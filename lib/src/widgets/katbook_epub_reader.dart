import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../controller/katbook_epub_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/chapter_node.dart';
import '../models/paragraph_element.dart';
import '../models/reader_theme.dart';
import '../models/reading_mode.dart';
import '../models/reading_position.dart';
import 'book_page_view.dart';
import 'epub_content_renderer.dart';
import 'table_of_contents.dart';

/// The main EPUB reader widget.
class KatbookEpubReader extends StatefulWidget {
  /// Creates a new EPUB reader widget.
  const KatbookEpubReader({
    super.key,
    required this.controller,
    this.initialTheme = ReaderTheme.light,
    this.initialFontSize = 16.0,
    this.initialReadingMode = ReadingMode.page,
    this.showAppBar = true,
    this.appBarBuilder,
    this.onPositionChanged,
    this.onChapterChanged,
    this.onProgressChanged,
    this.onReadingModeChanged,
    this.loadingBuilder,
    this.errorBuilder,
    this.tocBuilder,
    this.chapterHeaderBuilder,
    this.paragraphBuilder,
    this.imageErrorBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.scrollPhysics,
    this.initialPosition,
    this.contentWidthPercent = 0.65,
    this.locale,
    this.onLocaleChanged,
    this.showLanguageButton = true,
    this.showThemeButton = true,
  });

  /// The controller that manages the EPUB book.
  final KatbookEpubController controller;

  /// The initial theme to use.
  final ReaderTheme initialTheme;

  /// The initial font size.
  final double initialFontSize;

  /// Whether to show the built-in app bar.
  final bool showAppBar;

  /// Builder for a custom app bar.
  final PreferredSizeWidget Function(BuildContext context, KatbookEpubReaderState state)? appBarBuilder;

  /// Called when the reading position changes.
  final void Function(ReadingPosition position)? onPositionChanged;

  /// Called when the current chapter changes.
  final void Function(ChapterNode chapter)? onChapterChanged;

  /// Called when the progress percentage changes.
  final void Function(double progress)? onProgressChanged;

  /// Called when the reading mode changes.
  final void Function(ReadingMode mode)? onReadingModeChanged;

  /// The initial reading mode (scroll or page).
  final ReadingMode initialReadingMode;

  /// Builder for the loading indicator.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error display.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builder for custom table of contents.
  final Widget Function(BuildContext context, List<ChapterNode> chapters, void Function(ChapterNode) onTap)? tocBuilder;

  /// Builder for chapter headers.
  final Widget Function(BuildContext context, ChapterNode chapter)? chapterHeaderBuilder;

  /// Builder for paragraph content.
  final Widget Function(BuildContext context, ParagraphElement paragraph, ReaderThemeData theme, double fontSize)? paragraphBuilder;

  /// Builder for image loading errors.
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? imageErrorBuilder;

  /// Padding around each paragraph.
  final EdgeInsets padding;

  /// Scroll physics for the content.
  final ScrollPhysics? scrollPhysics;

  /// Initial reading position to restore.
  final ReadingPosition? initialPosition;

  /// Width of the content area as a percentage of screen width (0.0 to 1.0).
  /// Content will be centered. Defaults to 0.65 (65% of screen width).
  final double contentWidthPercent;

  /// The locale to use for localization. If null, uses the system locale.
  final Locale? locale;

  /// Called when the locale changes.
  final void Function(Locale locale)? onLocaleChanged;

  /// Whether to show the language selector button in the app bar.
  final bool showLanguageButton;

  /// Whether to show the theme selector button in the app bar.
  final bool showThemeButton;

  @override
  State<KatbookEpubReader> createState() => KatbookEpubReaderState();
}

/// State for [KatbookEpubReader].
class KatbookEpubReaderState extends State<KatbookEpubReader> {
  late ReaderTheme _currentTheme;
  late double _fontSize;
  late ReadingMode _readingMode;
  late Locale? _currentLocale;
  bool _tocVisible = false;
  bool _showFontSlider = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<BookPageViewState> _bookPageKey = GlobalKey<BookPageViewState>();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  int _lastReportedChapterIndex = -1;
  double _lastReportedProgress = -1;
  int _lastReportedParagraphIndex = -1;
  Timer? _positionDebounceTimer;

  /// Gets the current theme.
  ReaderTheme get currentTheme => _currentTheme;

  /// Gets the current font size.
  double get fontSize => _fontSize;

  /// Gets the current reading mode.
  ReadingMode get readingMode => _readingMode;

  /// Gets the current locale.
  Locale? get currentLocale => _currentLocale;

  /// Gets the current theme data.
  ReaderThemeData get themeData => ReaderThemeData.fromTheme(_currentTheme);

  /// Gets whether the table of contents is visible.
  bool get isTocVisible => _tocVisible;

  /// Gets the reading progress (0.0 to 1.0).
  double get progress {
    if (!widget.controller.isLoaded || widget.controller.totalParagraphs == 0) {
      return 0.0;
    }
    final position = widget.controller.currentPosition?.paragraphIndex ?? 0;
    return position / widget.controller.totalParagraphs;
  }

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
    _fontSize = widget.initialFontSize;
    _readingMode = widget.initialReadingMode;
    _currentLocale = widget.locale;

    widget.controller.addListener(_onControllerChanged);
    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);

    // Restore initial position if provided
    if (widget.initialPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restorePosition(widget.initialPosition!);
      });
    }
  }

  @override
  void dispose() {
    _positionDebounceTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _itemPositionsListener.itemPositions.removeListener(_onScrollPositionChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _onScrollPositionChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Get the first visible item
    final firstVisible = positions.reduce((a, b) => 
      a.itemLeadingEdge < b.itemLeadingEdge ? a : b
    );

    final paragraphIndex = firstVisible.index;
    final paragraphs = widget.controller.paragraphs;
    
    if (paragraphs.isEmpty || paragraphIndex >= paragraphs.length) return;

    final paragraph = paragraphs[paragraphIndex];
    final chapterIndex = paragraph.chapterIndex;

    // Only update controller if paragraph actually changed
    if (paragraphIndex != _lastReportedParagraphIndex) {
      _lastReportedParagraphIndex = paragraphIndex;
      
      // Update controller position (internal state)
      widget.controller.updatePositionFromScroll(paragraphIndex, 0.0);

      // Notify if chapter changed
      if (chapterIndex != _lastReportedChapterIndex) {
        _lastReportedChapterIndex = chapterIndex;
        
        final flatChapters = widget.controller.flatChapters;
        if (chapterIndex < flatChapters.length) {
          widget.onChapterChanged?.call(flatChapters[chapterIndex]);
        }
      }

      // Notify if progress changed significantly (0.5% threshold)
      final currentProgress = progress;
      if ((currentProgress - _lastReportedProgress).abs() > 0.005) {
        _lastReportedProgress = currentProgress;
        widget.onProgressChanged?.call(currentProgress);
      }

      // Debounce position notification to avoid rapid updates
      // Only notify after user stops scrolling for 500ms
      _positionDebounceTimer?.cancel();
      _positionDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        final position = widget.controller.currentPosition;
        if (position != null && mounted) {
          widget.onPositionChanged?.call(position);
        }
      });
    }
  }

  void _restorePosition(ReadingPosition position) {
    if (!widget.controller.isLoaded) return;

    final paragraphIndex = position.paragraphIndex;
    jumpToParagraph(paragraphIndex);
  }

  /// Changes the current theme.
  void setTheme(ReaderTheme theme) {
    if (_currentTheme == theme) return;
    setState(() {
      _currentTheme = theme;
    });
  }

  /// Cycles through the available themes.
  void cycleTheme() {
    final themes = ReaderTheme.values;
    final currentIndex = themes.indexOf(_currentTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    setTheme(themes[nextIndex]);
  }

  /// Changes the reading mode.
  void setReadingMode(ReadingMode mode) {
    if (_readingMode == mode) return;
    
    // Capture current position before switching
    final currentPosition = widget.controller.currentPosition;
    final currentParagraphIndex = currentPosition?.paragraphIndex ?? 0;
    
    setState(() {
      _readingMode = mode;
      _pendingParagraphIndex = currentParagraphIndex;
    });
    
    widget.onReadingModeChanged?.call(mode);
    
    // After mode switch, navigate to the same position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (mode == ReadingMode.scroll) {
        // Scroll mode - jump to paragraph
        if (_itemScrollController.isAttached) {
          _itemScrollController.jumpTo(index: currentParagraphIndex);
        }
      }
      // Page mode handles its own navigation via initialParagraphIndex
    });
  }
  
  /// Pending paragraph index for mode synchronization
  int? _pendingParagraphIndex;

  /// Toggles between scroll and page mode.
  void toggleReadingMode() {
    setReadingMode(
      _readingMode == ReadingMode.scroll ? ReadingMode.page : ReadingMode.scroll,
    );
  }

  /// Changes the current locale.
  void setLocale(Locale locale) {
    if (_currentLocale == locale) return;
    setState(() {
      _currentLocale = locale;
    });
    widget.onLocaleChanged?.call(locale);
  }

  /// Cycles through the available locales.
  void cycleLocale() {
    final locales = AppLocalizations.supportedLocales;
    final currentIndex = _currentLocale != null
        ? locales.indexWhere((l) => l.languageCode == _currentLocale!.languageCode)
        : -1;
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % locales.length;
    setLocale(locales[nextIndex]);
  }

  /// Changes the font size.
  void setFontSize(double size) {
    if (size < 8.0 || size > 40.0) return;
    setState(() {
      _fontSize = size;
    });
  }

  /// Increases the font size.
  void increaseFontSize([double delta = 2.0]) {
    setFontSize(_fontSize + delta);
  }

  /// Decreases the font size.
  void decreaseFontSize([double delta = 2.0]) {
    setFontSize(_fontSize - delta);
  }

  /// Shows the table of contents.
  void showTableOfContents() {
    setState(() {
      _tocVisible = true;
    });
    _scaffoldKey.currentState?.openDrawer();
  }

  /// Hides the table of contents.
  void hideTableOfContents() {
    setState(() {
      _tocVisible = false;
    });
    Navigator.of(context).pop();
  }

  /// Toggle font size slider visibility.
  void toggleFontSlider() {
    setState(() {
      _showFontSlider = !_showFontSlider;
    });
  }

  /// Jumps to a specific chapter.
  void jumpToChapter(ChapterNode chapter) {
    final index = chapter.startIndex;
    final maxIndex = widget.controller.paragraphs.length - 1;
    if (index < 0 || index > maxIndex) return;
    
    widget.controller.jumpToIndex(index);
    if (_readingMode == ReadingMode.page) {
      // In page mode, use BookPageView's jumpToParagraph
      _bookPageKey.currentState?.jumpToParagraph(index);
    } else {
      if (_itemScrollController.isAttached) {
        // Use scrollTo with minimal duration to avoid layout cycle issues
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 1),
        );
      }
    }
  }

  /// Jumps to a specific paragraph index.
  void jumpToParagraph(int index) {
    final maxIndex = widget.controller.paragraphs.length - 1;
    if (index < 0 || index > maxIndex) return;
    
    widget.controller.jumpToIndex(index);
    
    if (_readingMode == ReadingMode.page) {
      // In page mode, use BookPageView's jumpToParagraph
      _bookPageKey.currentState?.jumpToParagraph(index);
    } else {
      // In scroll mode, use ScrollablePositionedList
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 1),
        );
      }
    }
  }

  /// Scrolls to a specific paragraph with animation.
  void scrollToParagraph(int index, {Duration duration = const Duration(milliseconds: 300)}) {
    final maxIndex = widget.controller.paragraphs.length - 1;
    if (index < 0 || index > maxIndex) return;
    
    widget.controller.jumpToIndex(index);
    
    if (_readingMode == ReadingMode.page) {
      // In page mode, use BookPageView's jumpToParagraph
      _bookPageKey.currentState?.jumpToParagraph(index);
    } else {
      // In scroll mode, use ScrollablePositionedList
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: duration,
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Gets the current reading position.
  ReadingPosition? getCurrentPosition() {
    return widget.controller.currentPosition;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ReaderThemeData.fromTheme(_currentTheme);

    Widget content = Theme(
      data: ThemeData(
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: theme.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: theme.appBarColor,
          foregroundColor: theme.textColor,
          elevation: 1,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: theme.backgroundColor,
        ),
        iconTheme: IconThemeData(
          color: theme.textColor,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.backgroundColor,
        appBar: widget.showAppBar ? _buildAppBar(context, theme) : widget.appBarBuilder?.call(context, this),
        drawer: _buildDrawer(context),
        body: _buildBody(context, theme),
      ),
    );

    // Wrap with Localizations if a specific locale is set
    if (_currentLocale != null) {
      content = Localizations.override(
        context: context,
        locale: _currentLocale,
        child: content,
      );
    }

    return content;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ReaderThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final title = widget.controller.title ?? l10n?.appBarTitleDefault ?? 'EPUB Reader';
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n?.tooltipBack,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$progressPercent%',
            style: TextStyle(
              fontSize: 12,
              color: theme.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_book),
          tooltip: l10n?.tooltipTableOfContents,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        IconButton(
          icon: const Icon(Icons.format_size),
          tooltip: l10n?.tooltipFontSize,
          onPressed: toggleFontSlider,
        ),
        // Reading mode menu
        PopupMenuButton<ReadingMode>(
          icon: Icon(
            _readingMode == ReadingMode.scroll 
                ? Icons.view_stream 
                : Icons.auto_stories,
          ),
          tooltip: l10n?.tooltipReadingMode,
          onSelected: setReadingMode,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ReadingMode.scroll,
              child: Row(
                children: [
                  Icon(
                    Icons.view_stream,
                    color: _readingMode == ReadingMode.scroll 
                        ? theme.accentColor 
                        : theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.readingModeScroll ?? 'Scroll Mode',
                    style: TextStyle(
                      fontWeight: _readingMode == ReadingMode.scroll 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: ReadingMode.page,
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: _readingMode == ReadingMode.page 
                        ? theme.accentColor 
                        : theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.readingModePage ?? 'Page Mode',
                    style: TextStyle(
                      fontWeight: _readingMode == ReadingMode.page 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Theme selector
        if (widget.showThemeButton)
          PopupMenuButton<ReaderTheme>(
            icon: const Icon(Icons.brightness_6),
            tooltip: l10n?.tooltipTheme,
            onSelected: setTheme,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ReaderTheme.light,
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(l10n?.themeLight ?? 'Light'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ReaderTheme.sepia,
                child: Row(
                  children: [
                    const Icon(Icons.brightness_5, color: Colors.brown),
                    const SizedBox(width: 8),
                    Text(l10n?.themeSepia ?? 'Sepia'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ReaderTheme.dark,
                child: Row(
                  children: [
                    const Icon(Icons.nights_stay, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(l10n?.themeDark ?? 'Dark'),
                  ],
                ),
              ),
            ],
          ),
        // Language selector
        if (widget.showLanguageButton)
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: l10n?.tooltipLanguage,
            onSelected: setLocale,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: [
                    Icon(
                      _currentLocale?.languageCode == 'en'
                          ? Icons.check
                          : Icons.language,
                      size: 20,
                      color: _currentLocale?.languageCode == 'en'
                          ? theme.accentColor
                          : theme.textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: TextStyle(
                        fontWeight: _currentLocale?.languageCode == 'en'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentLocale?.languageCode == 'en'
                            ? theme.accentColor
                            : theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('zh'),
                child: Row(
                  children: [
                    Icon(
                      _currentLocale?.languageCode == 'zh'
                          ? Icons.check
                          : Icons.language,
                      size: 20,
                      color: _currentLocale?.languageCode == 'zh'
                          ? theme.accentColor
                          : theme.textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '中文',
                      style: TextStyle(
                        fontWeight: _currentLocale?.languageCode == 'zh'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentLocale?.languageCode == 'zh'
                            ? theme.accentColor
                            : theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('fr'),
                child: Row(
                  children: [
                    Icon(
                      _currentLocale?.languageCode == 'fr'
                          ? Icons.check
                          : Icons.language,
                      size: 20,
                      color: _currentLocale?.languageCode == 'fr'
                          ? theme.accentColor
                          : theme.textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Français',
                      style: TextStyle(
                        fontWeight: _currentLocale?.languageCode == 'fr'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentLocale?.languageCode == 'fr'
                            ? theme.accentColor
                            : theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    if (widget.tocBuilder != null) {
      return Drawer(
        child: widget.tocBuilder!(
          context,
          widget.controller.tableOfContents,
          (chapter) {
            Navigator.pop(context);
            jumpToChapter(chapter);
          },
        ),
      );
    }

    final currentParagraphIndex = widget.controller.currentPosition?.paragraphIndex ?? -1;

    return Drawer(
      child: TableOfContentsWidget(
        chapters: widget.controller.tableOfContents,
        currentParagraphIndex: currentParagraphIndex,
        themeData: themeData,
        onChapterTap: (chapter) {
          Navigator.pop(context);
          jumpToChapter(chapter);
        },
        bookTitle: widget.controller.title,
        bookAuthor: widget.controller.author,
        coverImage: null,
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReaderThemeData theme) {
    final l10n = AppLocalizations.of(context);

    // Loading state
    if (!widget.controller.isLoaded) {
      return widget.loadingBuilder?.call(context) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme.linkColor,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.loadingBook ?? 'Loading book...',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
    }

    // Error state
    if (widget.controller.loadingError != null) {
      final error = widget.controller.loadingError!;
      return widget.errorBuilder?.call(context, error) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.textColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.errorLoadingTitle ?? 'Error loading book',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
    }

    // Not loaded
    if (!widget.controller.isLoaded) {
      return Center(
        child: Text(
          l10n?.noBookLoaded ?? 'No book loaded',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
          ),
        ),
      );
    }

    // Content
    final paragraphs = widget.controller.paragraphs;
    if (paragraphs.isEmpty) {
      return Center(
        child: Text(
          l10n?.bookEmpty ?? 'Book has no content',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Font size slider
        if (_showFontSlider)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.appBarColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.textColor.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.text_decrease, color: theme.textColor, size: 18),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 10,
                    max: 32,
                    divisions: 22,
                    activeColor: theme.accentColor,
                    inactiveColor: theme.textColor.withOpacity(0.3),
                    onChanged: (value) => setFontSize(value),
                  ),
                ),
                Icon(Icons.text_increase, color: theme.textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_fontSize.toInt()}',
                  style: TextStyle(color: theme.textColor, fontSize: 14),
                ),
              ],
            ),
          ),
        // Content - either scroll mode or page mode
        Expanded(
          child: _readingMode == ReadingMode.page
              ? _buildPageModeContent(context, theme, paragraphs)
              : _buildScrollModeContent(context, theme, paragraphs),
        ),
      ],
    );
  }

  Widget _buildPageModeContent(BuildContext context, ReaderThemeData theme, List<ParagraphElement> paragraphs) {
    // Get the paragraph index to navigate to (for mode sync)
    final initialParagraphIndex = _pendingParagraphIndex;
    _pendingParagraphIndex = null; // Clear after use
    
    return BookPageView(
      key: _bookPageKey,
      paragraphs: paragraphs,
      themeData: theme,
      fontSize: _fontSize,
      imageData: widget.controller.imageData,
      cssParser: widget.controller.cssParser,
      contentWidthPercent: widget.contentWidthPercent,
      initialParagraphIndex: initialParagraphIndex,
      onPageChanged: (pageIndex, paragraphIndex) {
        // Update controller position
        widget.controller.updatePositionFromScroll(paragraphIndex, 0.0);
        
        // Notify chapter change if needed
        if (paragraphIndex < paragraphs.length) {
          final chapterIndex = paragraphs[paragraphIndex].chapterIndex;
          if (chapterIndex != _lastReportedChapterIndex) {
            _lastReportedChapterIndex = chapterIndex;
            final flatChapters = widget.controller.flatChapters;
            if (chapterIndex < flatChapters.length) {
              widget.onChapterChanged?.call(flatChapters[chapterIndex]);
            }
          }
        }
        
        // Notify progress change
        final currentProgress = paragraphIndex / paragraphs.length;
        if ((currentProgress - _lastReportedProgress).abs() > 0.005) {
          _lastReportedProgress = currentProgress;
          widget.onProgressChanged?.call(currentProgress);
        }
        
        // Notify position change
        final position = widget.controller.currentPosition;
        if (position != null) {
          widget.onPositionChanged?.call(position);
        }
      },
    );
  }

  Widget _buildScrollModeContent(BuildContext context, ReaderThemeData theme, List<ParagraphElement> paragraphs) {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemCount: paragraphs.length,
      physics: widget.scrollPhysics ?? const ClampingScrollPhysics(),
      // Larger cache for smoother scrolling - pre-render more items
      minCacheExtent: 1500,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        return _buildScrollItem(context, index, paragraphs, theme);
      },
    );
  }

  /// Build a single scroll item with RepaintBoundary for performance
  Widget _buildScrollItem(BuildContext context, int index, List<ParagraphElement> paragraphs, ReaderThemeData theme) {
    final paragraph = paragraphs[index];
    
    // Check if this is a chapter start
    final isChapterStart = _isChapterStart(index, paragraphs);
    
    // Skip header if the first paragraph IS the chapter title (h1, h2, h3)
    final isFirstParagraphAHeading = paragraph.isHeading;
    final shouldShowHeader = isChapterStart && 
        paragraph.chapterTitle != null && 
        !isFirstParagraphAHeading;
    
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth * widget.contentWidthPercent;
          return Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shouldShowHeader)
                    _buildChapterHeaderFromTitle(context, paragraph.chapterTitle!, index > 0, theme),
                  Padding(
                    padding: widget.padding,
                    child: widget.paragraphBuilder?.call(context, paragraph, theme, _fontSize) ??
                        EpubContentRenderer(
                          paragraph: paragraph,
                          themeData: theme,
                          fontSize: _fontSize,
                          imageData: widget.controller.imageData,
                          onLinkTap: _handleLinkTap,
                          imageErrorBuilder: widget.imageErrorBuilder,
                          cssParser: widget.controller.cssParser,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isChapterStart(int index, List<ParagraphElement> paragraphs) {
    if (paragraphs.isEmpty || index >= paragraphs.length) return false;
    
    // Check if this paragraph is marked as chapter start
    return paragraphs[index].isChapterStart;
  }

  Widget _buildChapterHeaderFromTitle(BuildContext context, String title, bool showDivider, ReaderThemeData theme) {
    if (title.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDivider)
            Divider(
              color: theme.textColor.withOpacity(0.2),
              thickness: 1,
              height: 32,
            ),
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: _fontSize + 6,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLinkTap(String href) {
    // Handle internal and external links
    if (href.startsWith('http://') || href.startsWith('https://')) {
      // External link - could open in browser
      debugPrint('External link tapped: $href');
    } else {
      // Internal link - try to navigate
      debugPrint('Internal link tapped: $href');
    }
  }
}
