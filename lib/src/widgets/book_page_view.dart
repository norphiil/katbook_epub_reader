import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/paragraph_element.dart';
import '../models/reader_theme.dart';
import '../parser/css_parser.dart';

/// A segment of content that can be rendered on a page.
/// Can be text, part of a paragraph, a chapter header, or an image.
class _PageSegment {
  final int paragraphIndex;
  final String text;
  final bool isChapterStart;
  final String? chapterTitle;
  final bool isHeading;
  final bool isFirstOfParagraph;
  final bool isDropCap;
  final bool isImage;
  final String? imagePath;
  
  const _PageSegment({
    required this.paragraphIndex,
    required this.text,
    this.isChapterStart = false,
    this.chapterTitle,
    this.isHeading = false,
    this.isFirstOfParagraph = true,
    this.isDropCap = false,
    this.isImage = false,
    this.imagePath,
  });
}

/// Widget that displays EPUB content in a book page format.
class BookPageView extends StatefulWidget {
  const BookPageView({
    super.key,
    required this.paragraphs,
    required this.themeData,
    required this.fontSize,
    required this.imageData,
    required this.onPageChanged,
    this.cssParser,
    this.initialPage = 0,
    this.initialParagraphIndex,
    this.contentWidthPercent = 0.70,
  });

  final List<ParagraphElement> paragraphs;
  final ReaderThemeData themeData;
  final double fontSize;
  final Map<String, Uint8List> imageData;
  final void Function(int pageIndex, int paragraphIndex) onPageChanged;
  final EpubCssParser? cssParser;
  final int initialPage;
  /// Initial paragraph index to navigate to (for mode synchronization)
  final int? initialParagraphIndex;
  final double contentWidthPercent;

  @override
  State<BookPageView> createState() => BookPageViewState();
}

class BookPageViewState extends State<BookPageView> with TickerProviderStateMixin {
  late PageController _pageController;
  
  // Pages list - built asynchronously
  List<List<_PageSegment>> _pages = [];
  int _currentPage = 0;
  Size? _lastPageSize;
  double? _lastFontSize;
  final TextEditingController _pageInputController = TextEditingController();
  bool _showPageInput = false;
  bool _needsInitialJump = false;
  int? _pendingParagraphIndex;
  bool _isLoading = true;
  
  late AnimationController _turnAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _turnAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Mark if we need to jump to initial paragraph after build
    if (widget.initialParagraphIndex != null) {
      _needsInitialJump = true;
      _pendingParagraphIndex = widget.initialParagraphIndex;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _turnAnimationController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  /// Get the text style for body text
  TextStyle _getBodyTextStyle() {
    return GoogleFonts.literata(
      fontSize: widget.fontSize,
      color: widget.themeData.textColor,
      height: 1.6,
    );
  }

  /// Get the text style for chapter titles
  TextStyle _getChapterTitleStyle() {
    return GoogleFonts.cinzelDecorative(
      fontSize: widget.fontSize + 4,
      fontWeight: FontWeight.w600,
      color: widget.themeData.textColor,
      letterSpacing: 3,
    );
  }

  /// Get the text style for drop cap
  TextStyle _getDropCapStyle() {
    return GoogleFonts.cinzelDecorative(
      fontSize: widget.fontSize * 3.5,
      fontWeight: FontWeight.bold,
      color: widget.themeData.textColor,
      height: 0.85,
    );
  }

  /// Extract image source from paragraph HTML
  String? _extractImageSrc(ParagraphElement para) {
    final html = para.outerHtml;
    // Match src="..." or xlink:href="..."
    final srcRegex = RegExp('src=["\']([^"\']+)["\']');
    final srcMatch = srcRegex.firstMatch(html);
    if (srcMatch != null) return srcMatch.group(1);
    
    final hrefRegex = RegExp('xlink:href=["\']([^"\']+)["\']');
    final hrefMatch = hrefRegex.firstMatch(html);
    if (hrefMatch != null) return hrefMatch.group(1);
    
    final hrefRegex2 = RegExp('href=["\']([^"\']+)["\']');
    final hrefMatch2 = hrefRegex2.firstMatch(html);
    return hrefMatch2?.group(1);
  }

  /// Find image data by path
  Uint8List? _findImageData(String src) {
    // Direct match
    if (widget.imageData.containsKey(src)) {
      return widget.imageData[src];
    }

    // Try without leading path separators
    final cleanSrc = src.replaceAll(RegExp(r'^[./\\]+'), '');
    if (widget.imageData.containsKey(cleanSrc)) {
      return widget.imageData[cleanSrc];
    }

    // Try matching by filename
    final filename = src.split('/').last.split('\\').last;
    for (final entry in widget.imageData.entries) {
      final entryFilename = entry.key.split('/').last.split('\\').last;
      if (entryFilename == filename) {
        return entry.value;
      }
    }

    // Try case-insensitive match
    final lowerSrc = src.toLowerCase();
    for (final entry in widget.imageData.entries) {
      if (entry.key.toLowerCase() == lowerSrc ||
          entry.key.toLowerCase().endsWith(lowerSrc) ||
          lowerSrc.endsWith(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return null;
  }

  /// Start building pages asynchronously
  void _startBuildingPages(Size pageSize) {
    if (_lastPageSize == pageSize && _lastFontSize == widget.fontSize && _pages.isNotEmpty) {
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
      return;
    }
    
    // Show loading state
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    
    _lastPageSize = pageSize;
    _lastFontSize = widget.fontSize;
    
    // Build pages in microtask to avoid blocking UI
    Future.microtask(() {
      if (!mounted) return;
      final pages = _buildPagesSync(pageSize);
      if (!mounted) return;
      
      setState(() {
        _pages = pages;
        _isLoading = false;
      });
      
      // Handle initial jump after pages are built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleInitialJump();
      });
    });
  }

  /// Handle initial jump to paragraph
  void _handleInitialJump() {
    if (_needsInitialJump && _pendingParagraphIndex != null) {
      _needsInitialJump = false;
      final targetParagraph = _pendingParagraphIndex!;
      _pendingParagraphIndex = null;
      
      final targetPage = _findPageForParagraph(targetParagraph);
      if (targetPage != null) {
        setState(() {
          _currentPage = targetPage;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(targetPage);
        }
        _notifyPageChange();
      }
    } else {
      if (_pages.isNotEmpty && _currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
      if (_pageController.hasClients && _pageController.page?.round() != _currentPage) {
        _pageController.jumpToPage(_currentPage);
      }
    }
  }

  /// Build pages synchronously - called from microtask
  List<List<_PageSegment>> _buildPagesSync(Size pageSize) {
    if (widget.paragraphs.isEmpty) {
      return [[const _PageSegment(paragraphIndex: 0, text: '')]];
    }

    final double contentWidth = pageSize.width - 48;
    final double contentHeight = pageSize.height - 180;
    final bodyStyle = _getBodyTextStyle();
    final lineHeight = widget.fontSize * 2.0;
    
    final List<List<_PageSegment>> newPages = [];
    List<_PageSegment> currentPageSegments = [];
    double currentPageHeight = 0;
    
    for (int i = 0; i < widget.paragraphs.length; i++) {
      final para = widget.paragraphs[i];
      final text = para.text
          .replaceAll(RegExp(r'\r\n|\r|\n'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      // Handle chapter starts - always on new page
      if (para.isChapterStart && currentPageSegments.isNotEmpty) {
        newPages.add(List.from(currentPageSegments));
        currentPageSegments = [];
        currentPageHeight = 0;
      }
      
      // Handle images
      if (para.containsImage) {
        final imageSrc = _extractImageSrc(para);
        if (imageSrc != null) {
          final imageHeight = contentHeight * 0.6;
          
          if (currentPageHeight + imageHeight > contentHeight && currentPageSegments.isNotEmpty) {
            newPages.add(List.from(currentPageSegments));
            currentPageSegments = [];
            currentPageHeight = 0;
          }
          
          currentPageSegments.add(_PageSegment(
            paragraphIndex: i,
            text: '',
            isImage: true,
            imagePath: imageSrc,
          ));
          currentPageHeight += imageHeight + 16;
          continue;
        }
      }
      
      if (text.isEmpty) continue;
      
      // Chapter title
      if (para.isChapterStart && para.chapterTitle != null) {
        final titleHeight = _measureChapterTitleHeight(para.chapterTitle!, contentWidth);
        
        if (currentPageHeight + titleHeight > contentHeight && currentPageSegments.isNotEmpty) {
          newPages.add(List.from(currentPageSegments));
          currentPageSegments = [];
          currentPageHeight = 0;
        }
        
        currentPageSegments.add(_PageSegment(
          paragraphIndex: i,
          text: para.chapterTitle!,
          isChapterStart: true,
          chapterTitle: para.chapterTitle,
        ));
        currentPageHeight += titleHeight + 24;
      }
      
      // Headings
      if (para.isHeading) {
        final headingHeight = _measureTextHeight(text, contentWidth, bodyStyle.copyWith(
          fontSize: widget.fontSize + 6,
          fontWeight: FontWeight.bold,
        ));
        
        if (currentPageHeight + headingHeight + 20 > contentHeight && currentPageSegments.isNotEmpty) {
          newPages.add(List.from(currentPageSegments));
          currentPageSegments = [];
          currentPageHeight = 0;
        }
        
        currentPageSegments.add(_PageSegment(
          paragraphIndex: i,
          text: text,
          isHeading: true,
        ));
        currentPageHeight += headingHeight + 20;
        continue;
      }
      
      // Regular paragraph
      final bool needsDropCap = para.isChapterStart && 
          text.length > 10 && 
          RegExp(r'^[A-Za-zÀ-ÿ]').hasMatch(text);
      
      String remainingText = text;
      bool isFirstSegment = true;
      
      while (remainingText.isNotEmpty) {
        double availableHeight = contentHeight - currentPageHeight;
        double dropCapHeight = needsDropCap && isFirstSegment ? widget.fontSize * 3.5 : 0;
        
        if (availableHeight < lineHeight * 2 + dropCapHeight) {
          if (currentPageSegments.isNotEmpty) {
            newPages.add(List.from(currentPageSegments));
            currentPageSegments = [];
            currentPageHeight = 0;
            availableHeight = contentHeight;
          }
        }
        
        final fitResult = _fitTextToHeight(
          remainingText, 
          contentWidth, 
          availableHeight - dropCapHeight - lineHeight,
          bodyStyle,
          needsDropCap && isFirstSegment,
        );
        
        if (fitResult.fittingText.isEmpty) {
          if (currentPageSegments.isNotEmpty) {
            newPages.add(List.from(currentPageSegments));
            currentPageSegments = [];
            currentPageHeight = 0;
          }
          continue;
        }
        
        currentPageSegments.add(_PageSegment(
          paragraphIndex: i,
          text: fitResult.fittingText,
          isFirstOfParagraph: isFirstSegment,
          isDropCap: needsDropCap && isFirstSegment,
          isChapterStart: para.isChapterStart && isFirstSegment,
        ));
        
        currentPageHeight += fitResult.usedHeight + 8;
        remainingText = fitResult.remainingText;
        isFirstSegment = false;
      }
    }
    
    // Add last page
    if (currentPageSegments.isNotEmpty) {
      newPages.add(currentPageSegments);
    }
    
    if (newPages.isEmpty) {
      newPages.add([const _PageSegment(paragraphIndex: 0, text: '')]);
    }
    
    return newPages;
  }
  
  /// Find the page index that contains the given paragraph index
  int? _findPageForParagraph(int paragraphIndex) {
    for (int pageIdx = 0; pageIdx < _pages.length; pageIdx++) {
      for (final segment in _pages[pageIdx]) {
        if (segment.paragraphIndex >= paragraphIndex) {
          return pageIdx;
        }
      }
    }
    return _pages.isNotEmpty ? _pages.length - 1 : null;
  }
  
  /// Get the reading progress as a value between 0.0 and 1.0
  double get readingProgress {
    if (_pages.isEmpty) return 0.0;
    return (_currentPage + 1) / _pages.length;
  }
  
  /// Get the current page number (1-indexed for display)
  int get currentPageNumber => _currentPage + 1;
  
  /// Get the total number of pages
  int get totalPages => _pages.length;

  double _measureChapterTitleHeight(String title, double width) {
    final titleStyle = _getChapterTitleStyle();
    final painter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    painter.layout(maxWidth: width);
    return painter.height + 50;
  }

  double _measureTextHeight(String text, double width, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    painter.layout(maxWidth: width);
    return painter.height;
  }

  _FitResult _fitTextToHeight(
    String text, 
    double width, 
    double maxHeight,
    TextStyle style,
    bool hasDropCap,
  ) {
    if (text.isEmpty) {
      return const _FitResult(fittingText: '', remainingText: '', usedHeight: 0);
    }
    
    double effectiveWidth = width;
    if (hasDropCap) {
      effectiveWidth = width - (widget.fontSize * 4.2);
    }
    
    final fullPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    fullPainter.layout(maxWidth: effectiveWidth);
    
    if (fullPainter.height <= maxHeight) {
      return _FitResult(
        fittingText: text,
        remainingText: '',
        usedHeight: fullPainter.height,
      );
    }
    
    // Binary search for the right amount of text
    final words = text.split(RegExp(r'(?<=\s)'));
    int low = 1;
    int high = words.length;
    String bestFit = '';
    double bestHeight = 0;
    
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      String testText = words.sublist(0, mid).join('');
      
      final painter = TextPainter(
        text: TextSpan(text: testText, style: style),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );
      painter.layout(maxWidth: effectiveWidth);
      
      if (painter.height <= maxHeight) {
        bestFit = testText;
        bestHeight = painter.height;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    
    if (bestFit.isEmpty && words.isNotEmpty) {
      bestFit = words[0];
      final painter = TextPainter(
        text: TextSpan(text: bestFit, style: style),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );
      painter.layout(maxWidth: effectiveWidth);
      bestHeight = painter.height;
    }
    
    String remaining = text.substring(bestFit.length).trimLeft();
    
    return _FitResult(
      fittingText: bestFit.trimRight(),
      remainingText: remaining,
      usedHeight: bestHeight,
    );
  }

  void jumpToParagraph(int paragraphIndex) {
    // If pages are not yet built, store the target and jump after build
    if (_isLoading || _pages.isEmpty) {
      _needsInitialJump = true;
      _pendingParagraphIndex = paragraphIndex;
      return;
    }
    
    final targetPage = _findPageForParagraph(paragraphIndex);
    if (targetPage != null) {
      _jumpToPageImmediate(targetPage);
    }
  }
  
  /// Jump to a page immediately, ensuring the PageController is in sync
  void _jumpToPageImmediate(int page) {
    if (page < 0 || page >= _pages.length) return;
    if (page == _currentPage) return;
    
    _currentPage = page;
    
    // Dispose old controller and create new one at the target page
    _pageController.dispose();
    _pageController = PageController(initialPage: page);
    
    // Force rebuild
    setState(() {});
    
    _notifyPageChange();
  }

  int get currentParagraphIndex {
    if (_pages.isEmpty || _currentPage >= _pages.length) return 0;
    return _pages[_currentPage].first.paragraphIndex;
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _pages.length) return;
    
    final previousPage = _currentPage;
    _currentPage = page;
    _showPageInput = false;
    
    // If controller is attached and we can animate, do it smoothly
    if (_pageController.hasClients && (page - previousPage).abs() <= 3) {
      setState(() {});
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // For large jumps or when controller isn't ready, recreate it
      _pageController.dispose();
      _pageController = PageController(initialPage: page);
      setState(() {});
    }
    
    _notifyPageChange();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _notifyPageChange() {
    if (_pages.isEmpty || _currentPage >= _pages.length) return;
    final paragraphIndex = currentParagraphIndex;
    widget.onPageChanged(_currentPage, paragraphIndex);
  }

  void _showPageInputDialog() {
    _pageInputController.text = (_currentPage + 1).toString();
    setState(() {
      _showPageInput = true;
    });
  }

  void _submitPageInput() {
    final pageNum = int.tryParse(_pageInputController.text);
    if (pageNum != null && pageNum >= 1 && pageNum <= _pages.length) {
      _goToPage(pageNum - 1);
    }
    setState(() {
      _showPageInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    final pageHeight = screenSize.height * 0.82;
    final pageWidth = math.min(pageHeight * 0.72, screenSize.width * 0.88);
    
    final backgroundColor = _getBackgroundColor();
    
    return Container(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageSize = Size(pageWidth, pageHeight);
          
          // Start building pages asynchronously
          _startBuildingPages(pageSize);
          
          // Show loading indicator while pages are being built
          if (_isLoading || _pages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: widget.themeData.accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Préparation des pages...',
                    style: TextStyle(
                      color: widget.themeData.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Page view
                    Center(
                      child: SizedBox(
                        width: pageWidth,
                        height: pageHeight,
                        child: PageView.builder(
                          key: ValueKey(_pageController),
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                            _notifyPageChange();
                          },
                          itemCount: _pages.length,
                          itemBuilder: (context, pageIndex) {
                            return _buildPage(context, pageIndex, pageWidth, pageHeight);
                          },
                        ),
                      ),
                    ),
                    
                    // Left arrow
                    Positioned(
                      left: 8,
                      child: _buildNavigationArrow(
                        icon: Icons.chevron_left,
                        onTap: _previousPage,
                        enabled: _currentPage > 0,
                      ),
                    ),
                    
                    // Right arrow
                    Positioned(
                      right: 8,
                      child: _buildNavigationArrow(
                        icon: Icons.chevron_right,
                        onTap: _nextPage,
                        enabled: _currentPage < _pages.length - 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page indicator with input option
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: _showPageInput 
                    ? _buildPageInputField()
                    : _buildPageIndicator(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return GestureDetector(
      onTap: _showPageInputDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: widget.themeData.backgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.themeData.textColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app,
              size: 14,
              color: widget.themeData.secondaryTextColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Page ${_currentPage + 1} / ${_pages.length}',
              style: GoogleFonts.literata(
                color: widget.themeData.textColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageInputField() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Page ',
          style: GoogleFonts.literata(
            color: widget.themeData.textColor,
            fontSize: 13,
          ),
        ),
        SizedBox(
          width: 60,
          height: 32,
          child: TextField(
            controller: _pageInputController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: GoogleFonts.literata(
              color: widget.themeData.textColor,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.themeData.accentColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.themeData.accentColor, width: 2),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submitPageInput(),
          ),
        ),
        Text(
          ' / ${_pages.length}',
          style: GoogleFonts.literata(
            color: widget.themeData.textColor,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.check, color: widget.themeData.accentColor, size: 20),
          onPressed: _submitPageInput,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          icon: Icon(Icons.close, color: widget.themeData.secondaryTextColor, size: 20),
          onPressed: () => setState(() => _showPageInput = false),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    final pageColor = _getPageColor();
    final hsl = HSLColor.fromColor(pageColor);
    
    if (widget.themeData.isDark) {
      return hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0)).toColor();
    } else {
      return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
                .withSaturation((hsl.saturation + 0.08).clamp(0.0, 1.0)).toColor();
    }
  }

  Color _getPageColor() {
    if (widget.themeData.isDark) {
      return Color.lerp(widget.themeData.backgroundColor, Colors.grey[850], 0.3)!;
    } else {
      return Color.lerp(widget.themeData.backgroundColor, const Color(0xFFFFFBF0), 0.6)!;
    }
  }

  Widget _buildPage(BuildContext context, int pageIndex, double width, double height) {
    if (pageIndex >= _pages.length) return const SizedBox.shrink();
    
    final segments = _pages[pageIndex];
    final pageColor = _getPageColor();
    
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.themeData.isDark ? 0.5 : 0.2),
            blurRadius: 15,
            offset: const Offset(5, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.themeData.isDark ? 0.3 : 0.1),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Page edge effect
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: widget.themeData.isDark ? 0.2 : 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Page content - using ClipRect to prevent overflow
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 50),
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final segment in segments)
                          _buildSegment(segment, width - 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Page number
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '— ${pageIndex + 1} —',
                  style: GoogleFonts.literata(
                    color: widget.themeData.secondaryTextColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(_PageSegment segment, double maxWidth) {
    // Image
    if (segment.isImage && segment.imagePath != null) {
      return _buildImage(segment.imagePath!, maxWidth);
    }
    
    // Chapter title
    if (segment.chapterTitle != null && segment.isChapterStart && segment.text == segment.chapterTitle) {
      return _buildChapterTitle(segment.chapterTitle!);
    }
    
    // Heading
    if (segment.isHeading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          segment.text,
          style: GoogleFonts.literata(
            fontSize: widget.fontSize + 6,
            fontWeight: FontWeight.bold,
            color: widget.themeData.textColor,
            height: 1.4,
          ),
        ),
      );
    }
    
    // Paragraph with drop cap
    if (segment.isDropCap && segment.text.isNotEmpty) {
      return _buildDropCapParagraph(segment);
    }
    
    // Regular paragraph with first-line indent using RichText
    final String indentText = segment.isFirstOfParagraph ? '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0' : ''; // Non-breaking spaces for indent
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$indentText${segment.text}',
        style: _getBodyTextStyle(),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildImage(String imagePath, double maxWidth) {
    final imageBytes = _findImageData(imagePath);
    
    if (imageBytes != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth * 0.9,
              maxHeight: 300,
            ),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            ),
          ),
        ),
      );
    }
    
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.themeData.textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 48,
        color: widget.themeData.textColor.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildChapterTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 1,
                color: widget.themeData.textColor.withValues(alpha: 0.3),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '❧',
                  style: TextStyle(
                    color: widget.themeData.textColor.withValues(alpha: 0.5),
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 1,
                color: widget.themeData.textColor.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _getChapterTitleStyle(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDropCapParagraph(_PageSegment segment) {
    final text = segment.text;
    if (text.isEmpty) return const SizedBox.shrink();
    
    final firstLetter = text[0].toUpperCase();
    final restOfText = text.substring(1);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 2),
            child: Text(
              firstLetter,
              style: _getDropCapStyle(),
            ),
          ),
          Expanded(
            child: Text(
              restOfText,
              textAlign: TextAlign.justify,
              style: _getBodyTextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: widget.themeData.backgroundColor.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: enabled ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          color: enabled 
              ? widget.themeData.textColor 
              : widget.themeData.textColor.withValues(alpha: 0.3),
          size: 30,
        ),
      ),
    );
  }
}

class _FitResult {
  final String fittingText;
  final String remainingText;
  final double usedHeight;
  
  const _FitResult({
    required this.fittingText,
    required this.remainingText,
    required this.usedHeight,
  });
}
