import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;

import '../models/paragraph_element.dart';
import '../models/reader_theme.dart';
import '../parser/css_parser.dart';

/// Renders EPUB content with proper styling and image handling.
class EpubContentRenderer extends StatelessWidget {
  /// Creates a new content renderer.
  const EpubContentRenderer({
    super.key,
    required this.paragraph,
    required this.themeData,
    required this.fontSize,
    required this.imageData,
    this.onLinkTap,
    this.imageErrorBuilder,
    this.cssParser,
  });

  /// The paragraph element to render.
  final ParagraphElement paragraph;

  /// The theme data for styling.
  final ReaderThemeData themeData;

  /// The font size to use.
  final double fontSize;

  /// Image data cache for rendering images.
  final Map<String, Uint8List> imageData;

  /// Callback when a link is tapped.
  final void Function(String href)? onLinkTap;

  /// Builder for image loading errors.
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? imageErrorBuilder;

  /// CSS parser for resolving class-based styles from EPUB stylesheets.
  final EpubCssParser? cssParser;

  @override
  Widget build(BuildContext context) {
    return _renderElement(context, paragraph.element);
  }

  /// Parse inline CSS style attribute.
  Map<String, String> _parseStyle(dom.Element element) {
    final style = element.attributes['style'] ?? '';
    final result = <String, String>{};
    
    if (style.isEmpty) return result;
    
    for (final part in style.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0) {
        final key = trimmed.substring(0, colonIndex).trim().toLowerCase();
        final value = trimmed.substring(colonIndex + 1).trim().toLowerCase();
        result[key] = value;
      }
    }
    
    return result;
  }

  /// Normalize whitespace in text: collapse multiple spaces/newlines into single space.
  String _normalizeWhitespace(String text) {
    // Replace all whitespace (newlines, tabs, multiple spaces) with a single space
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Get text alignment from style or class.
  TextAlign _getTextAlign(dom.Element element) {
    final style = _parseStyle(element);
    final align = style['text-align'] ?? '';
    final className = element.className.toLowerCase();
    final tagName = element.localName?.toLowerCase() ?? '';
    
    // Check inline style first
    if (align.contains('left')) {
      return TextAlign.left;
    } else if (align.contains('right')) {
      return TextAlign.right;
    } else if (align.contains('center')) {
      return TextAlign.center;
    } else if (align.contains('justify')) {
      return TextAlign.justify;
    }
    
    // Check CSS parser for class-based styles
    if (cssParser != null) {
      final cssStyles = cssParser!.getStylesForElement(
        tagName: tagName,
        className: element.className,
        id: element.id,
      );
      if (cssParser!.isCentered(cssStyles)) {
        return TextAlign.center;
      }
      if (cssParser!.isRightAligned(cssStyles)) {
        return TextAlign.right;
      }
      // Check for text-align in CSS styles
      final cssAlign = cssStyles['text-align'] ?? '';
      if (cssAlign.contains('left')) {
        return TextAlign.left;
      } else if (cssAlign.contains('right')) {
        return TextAlign.right;
      } else if (cssAlign.contains('center')) {
        return TextAlign.center;
      } else if (cssAlign.contains('justify')) {
        return TextAlign.justify;
      }
    }
    
    // Check class name patterns
    if (className.contains('left')) {
      return TextAlign.left;
    } else if (className.contains('right')) {
      return TextAlign.right;
    } else if (className.contains('center')) {
      return TextAlign.center;
    } else if (className.contains('justify')) {
      return TextAlign.justify;
    }
    
    // Default to justify for book text
    return TextAlign.justify;
  }

  /// Check if element or its classes suggest italic.
  bool _isItalicFromStyle(dom.Element element) {
    final style = _parseStyle(element);
    final fontStyle = style['font-style'] ?? '';
    final className = element.className.toLowerCase();
    final tagName = element.localName?.toLowerCase() ?? '';
    
    // Check inline style
    if (fontStyle.contains('italic')) {
      return true;
    }
    
    // Check CSS parser
    if (cssParser != null) {
      final cssStyles = cssParser!.getStylesForElement(
        tagName: tagName,
        className: element.className,
        id: element.id,
      );
      if (cssParser!.isItalic(cssStyles)) {
        return true;
      }
    }
    
    // Check class name patterns
    return className.contains('italic') || className.contains('em');
  }

  /// Check if element or its classes suggest bold.
  bool _isBoldFromStyle(dom.Element element) {
    final style = _parseStyle(element);
    final fontWeight = style['font-weight'] ?? '';
    final className = element.className.toLowerCase();
    final tagName = element.localName?.toLowerCase() ?? '';
    
    // Check inline style
    if (fontWeight.contains('bold') || 
        fontWeight.contains('700') ||
        fontWeight.contains('800') ||
        fontWeight.contains('900')) {
      return true;
    }
    
    // Check CSS parser
    if (cssParser != null) {
      final cssStyles = cssParser!.getStylesForElement(
        tagName: tagName,
        className: element.className,
        id: element.id,
      );
      if (cssParser!.isBold(cssStyles)) {
        return true;
      }
    }
    
    // Check class name patterns
    return className.contains('bold') || className.contains('strong');
  }

  /// Get font size multiplier from style.
  double _getFontSizeMultiplier(dom.Element element) {
    final style = _parseStyle(element);
    final sizeStr = style['font-size'] ?? '';
    final className = element.className.toLowerCase();
    final tagName = element.localName?.toLowerCase() ?? '';
    
    // Check inline style
    if (sizeStr.contains('small')) {
      return 0.85;
    } else if (sizeStr.contains('x-large')) {
      return 1.4;
    } else if (sizeStr.contains('large')) {
      return 1.2;
    }
    
    // Check CSS parser
    if (cssParser != null) {
      final cssStyles = cssParser!.getStylesForElement(
        tagName: tagName,
        className: element.className,
        id: element.id,
      );
      final cssFontSize = cssStyles['font-size'] ?? '';
      if (cssFontSize.contains('small')) {
        return 0.85;
      } else if (cssFontSize.contains('x-large')) {
        return 1.4;
      } else if (cssFontSize.contains('large')) {
        return 1.2;
      }
      // Try to parse percentage or em values
      if (cssFontSize.endsWith('%')) {
        final value = double.tryParse(cssFontSize.replaceAll('%', ''));
        if (value != null) {
          return value / 100;
        }
      } else if (cssFontSize.endsWith('em')) {
        final value = double.tryParse(cssFontSize.replaceAll('em', ''));
        if (value != null) {
          return value;
        }
      }
    }
    
    // Check class name patterns
    if (className.contains('small')) {
      return 0.85;
    } else if (className.contains('large')) {
      return 1.2;
    }
    
    return 1.0;
  }

  /// Get margin/padding from style.
  EdgeInsets _getMargin(dom.Element element) {
    final style = _parseStyle(element);
    double top = 0, bottom = 0, left = 0, right = 0;
    
    // Parse margin-left for indentation
    final marginLeft = style['margin-left'] ?? style['padding-left'] ?? '';
    if (marginLeft.isNotEmpty) {
      final value = _parsePixelValue(marginLeft);
      left = value.clamp(0, 100);
    }
    
    // Parse text-indent for first line indent
    final textIndent = style['text-indent'] ?? '';
    if (textIndent.isNotEmpty) {
      final value = _parsePixelValue(textIndent);
      left += value.clamp(0, 50);
    }
    
    // Margin right
    final marginRight = style['margin-right'] ?? '';
    if (marginRight.isNotEmpty) {
      final value = _parsePixelValue(marginRight);
      right = value.clamp(0, 100);
    }
    
    return EdgeInsets.only(left: left, right: right, top: top, bottom: bottom);
  }

  double _parsePixelValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  Widget _renderElement(BuildContext context, dom.Element element) {
    final tagName = element.localName?.toLowerCase() ?? '';

    switch (tagName) {
      case 'img':
        return _renderImage(context, element);
      case 'image':
        return _renderSvgImage(context, element);
      case 'a':
        return _renderLink(context, element);
      case 'h1':
        return _renderHeading(context, element, fontSize + 10, FontWeight.bold);
      case 'h2':
        return _renderHeading(context, element, fontSize + 8, FontWeight.bold);
      case 'h3':
        return _renderHeading(context, element, fontSize + 6, FontWeight.bold);
      case 'h4':
        return _renderHeading(context, element, fontSize + 4, FontWeight.w600);
      case 'h5':
        return _renderHeading(context, element, fontSize + 2, FontWeight.w600);
      case 'h6':
        return _renderHeading(context, element, fontSize, FontWeight.w600);
      case 'p':
        return _renderParagraph(context, element);
      case 'div':
      case 'section':
      case 'article':
        return _renderContainer(context, element);
      case 'span':
        return _renderSpan(context, element);
      case 'strong':
      case 'b':
        return _renderBold(context, element);
      case 'em':
      case 'i':
        return _renderItalic(context, element);
      case 'u':
        return _renderUnderline(context, element);
      case 'blockquote':
        return _renderBlockquote(context, element);
      case 'pre':
      case 'code':
        return _renderCode(context, element);
      case 'ul':
        return _renderUnorderedList(context, element);
      case 'ol':
        return _renderOrderedList(context, element);
      case 'li':
        return _renderListItem(context, element);
      case 'br':
        return const SizedBox(height: 8);
      case 'hr':
        return Divider(color: themeData.textColor.withValues(alpha: 0.3));
      case 'table':
        return _renderTable(context, element);
      case 'figure':
        return _renderFigure(context, element);
      case 'figcaption':
        return _renderFigCaption(context, element);
      case 'sup':
        return _renderSuperscript(context, element);
      case 'sub':
        return _renderSubscript(context, element);
      default:
        // Try to render as text content
        return _renderTextContent(context, element);
    }
  }

  Widget _renderImage(BuildContext context, dom.Element element) {
    final src = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? '';

    if (src.isEmpty) {
      return const SizedBox.shrink();
    }

    // Try to find image in cache
    final imageBytes = _findImageData(src);

    if (imageBytes != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return imageErrorBuilder?.call(context, error, stackTrace) ??
                    _buildImagePlaceholder(alt);
              },
            ),
          ),
        ),
      );
    }

    return _buildImagePlaceholder(alt);
  }

  Widget _renderSvgImage(BuildContext context, dom.Element element) {
    // SVG image element (using xlink:href)
    final href = element.attributes['xlink:href'] ?? 
                 element.attributes['href'] ?? '';
    
    if (href.isEmpty) {
      return const SizedBox.shrink();
    }

    final imageBytes = _findImageData(href);

    if (imageBytes != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return imageErrorBuilder?.call(context, error, stackTrace) ??
                    _buildImagePlaceholder('');
              },
            ),
          ),
        ),
      );
    }

    return _buildImagePlaceholder('');
  }

  Uint8List? _findImageData(String src) {
    // Direct match
    if (imageData.containsKey(src)) {
      return imageData[src];
    }

    // Try without leading path separators
    final cleanSrc = src.replaceAll(RegExp(r'^[./\\]+'), '');
    if (imageData.containsKey(cleanSrc)) {
      return imageData[cleanSrc];
    }

    // Try matching by filename
    final filename = src.split('/').last.split('\\').last;
    for (final entry in imageData.entries) {
      final entryFilename = entry.key.split('/').last.split('\\').last;
      if (entryFilename == filename) {
        return entry.value;
      }
    }

    // Try case-insensitive match
    final lowerSrc = src.toLowerCase();
    for (final entry in imageData.entries) {
      if (entry.key.toLowerCase() == lowerSrc ||
          entry.key.toLowerCase().endsWith(lowerSrc) ||
          lowerSrc.endsWith(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return null;
  }

  Widget _buildImagePlaceholder(String alt) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: themeData.textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 48,
            color: themeData.textColor.withOpacity(0.5),
          ),
          if (alt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              alt,
              style: TextStyle(
                color: themeData.textColor.withOpacity(0.7),
                fontSize: fontSize - 2,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _renderLink(BuildContext context, dom.Element element) {
    final href = element.attributes['href'] ?? '';
    final text = element.text.trim();

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => onLinkTap?.call(href),
      child: Text(
        text,
        style: TextStyle(
          color: themeData.linkColor,
          fontSize: fontSize,
          decoration: TextDecoration.underline,
          decorationColor: themeData.linkColor,
        ),
      ),
    );
  }

  Widget _renderHeading(
    BuildContext context,
    dom.Element element,
    double size,
    FontWeight weight,
  ) {
    final textAlign = _getTextAlign(element);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        element.text.trim(),
        style: TextStyle(
          color: themeData.textColor,
          fontSize: size,
          fontWeight: weight,
          height: 1.3,
        ),
        textAlign: textAlign,
      ),
    );
  }

  Widget _renderParagraph(BuildContext context, dom.Element element) {
    // Check if paragraph contains only an image
    final images = element.querySelectorAll('img, image');
    if (images.isNotEmpty && element.text.trim().isEmpty) {
      return Column(
        children: images.map((img) => _renderElement(context, img)).toList(),
      );
    }

    // Get styling from CSS
    final textAlign = _getTextAlign(element);
    final isItalic = _isItalicFromStyle(element);
    final isBold = _isBoldFromStyle(element);
    final sizeMultiplier = _getFontSizeMultiplier(element);
    final margin = _getMargin(element);

    // Build rich text with inline elements
    final spans = _buildInlineSpans(element);
    
    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 4.0).add(margin),
      child: Text.rich(
        TextSpan(children: spans),
        style: TextStyle(
          color: themeData.textColor,
          fontSize: fontSize * sizeMultiplier,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          height: 1.6,
        ),
        textAlign: textAlign,
      ),
    );
  }

  List<InlineSpan> _buildInlineSpans(dom.Element element) {
    final spans = <InlineSpan>[];

    for (final node in element.nodes) {
      if (node is dom.Text) {
        final text = _normalizeWhitespace(node.text);
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: text));
        }
      } else if (node is dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        final text = _normalizeWhitespace(node.text);

        switch (tag) {
          case 'strong':
          case 'b':
            spans.add(TextSpan(
              text: text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ));
            break;
          case 'em':
          case 'i':
            spans.add(TextSpan(
              text: text,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ));
            break;
          case 'u':
            spans.add(TextSpan(
              text: text,
              style: const TextStyle(decoration: TextDecoration.underline),
            ));
            break;
          case 'a':
            spans.add(TextSpan(
              text: text,
              style: TextStyle(
                color: themeData.linkColor,
                decoration: TextDecoration.underline,
              ),
              recognizer: null, // Could add TapGestureRecognizer for links
            ));
            break;
          case 'sup':
            spans.add(WidgetSpan(
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: Text(
                  text,
                  style: TextStyle(
                    color: themeData.textColor,
                    fontSize: fontSize * 0.7,
                  ),
                ),
              ),
            ));
            break;
          case 'sub':
            spans.add(WidgetSpan(
              child: Transform.translate(
                offset: const Offset(0, 4),
                child: Text(
                  text,
                  style: TextStyle(
                    color: themeData.textColor,
                    fontSize: fontSize * 0.7,
                  ),
                ),
              ),
            ));
            break;
          case 'br':
            spans.add(const TextSpan(text: '\n'));
            break;
          case 'img':
          case 'image':
            // Skip images in inline context - they'll be rendered separately
            break;
          default:
            if (text.isNotEmpty) {
              spans.add(TextSpan(text: text));
            }
        }
      }
    }

    return spans;
  }

  Widget _renderContainer(BuildContext context, dom.Element element) {
    final children = <Widget>[];

    for (final child in element.children) {
      children.add(_renderElement(context, child));
    }

    if (children.isEmpty) {
      return _renderTextContent(context, element);
    }

    // Get alignment from container style
    final textAlign = _getTextAlign(element);
    final crossAxisAlignment = textAlign == TextAlign.right 
        ? CrossAxisAlignment.end 
        : textAlign == TextAlign.center 
            ? CrossAxisAlignment.center 
            : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }

  Widget _renderSpan(BuildContext context, dom.Element element) {
    final isItalic = _isItalicFromStyle(element);
    final isBold = _isBoldFromStyle(element);
    
    return Text(
      element.text.trim(),
      style: TextStyle(
        color: themeData.textColor,
        fontSize: fontSize,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _renderBold(BuildContext context, dom.Element element) {
    return Text(
      element.text.trim(),
      style: TextStyle(
        color: themeData.textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _renderItalic(BuildContext context, dom.Element element) {
    return Text(
      element.text.trim(),
      style: TextStyle(
        color: themeData.textColor,
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _renderUnderline(BuildContext context, dom.Element element) {
    return Text(
      element.text.trim(),
      style: TextStyle(
        color: themeData.textColor,
        fontSize: fontSize,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _renderBlockquote(BuildContext context, dom.Element element) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: themeData.linkColor,
            width: 4,
          ),
        ),
        color: themeData.textColor.withOpacity(0.05),
      ),
      child: Text(
        element.text.trim(),
        style: TextStyle(
          color: themeData.textColor.withOpacity(0.9),
          fontSize: fontSize,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _renderCode(BuildContext context, dom.Element element) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: themeData.isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.text,
        style: TextStyle(
          color: themeData.textColor,
          fontSize: fontSize - 1,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _renderUnorderedList(BuildContext context, dom.Element element) {
    final items = element.querySelectorAll('li');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: themeData.textColor,
                    fontSize: fontSize,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.text.trim(),
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: fontSize,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _renderOrderedList(BuildContext context, dom.Element element) {
    final items = element.querySelectorAll('li');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '$index.',
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.text.trim(),
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: fontSize,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _renderListItem(BuildContext context, dom.Element element) {
    return Text(
      element.text.trim(),
      style: TextStyle(
        color: themeData.textColor,
        fontSize: fontSize,
        height: 1.5,
      ),
    );
  }

  Widget _renderTable(BuildContext context, dom.Element element) {
    final rows = element.querySelectorAll('tr');
    if (rows.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Table(
          border: TableBorder.all(
            color: themeData.textColor.withOpacity(0.3),
            width: 1,
          ),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: rows.map((row) {
            final cells = row.querySelectorAll('td, th');
            final isHeader = row.querySelectorAll('th').isNotEmpty;
            return TableRow(
              children: cells.map((cell) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    cell.text.trim(),
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: fontSize - 1,
                      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _renderFigure(BuildContext context, dom.Element element) {
    return Column(
      children: element.children.map((child) => _renderElement(context, child)).toList(),
    );
  }

  Widget _renderFigCaption(BuildContext context, dom.Element element) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        element.text.trim(),
        style: TextStyle(
          color: themeData.textColor.withOpacity(0.7),
          fontSize: fontSize - 2,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _renderSuperscript(BuildContext context, dom.Element element) {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: Text(
        element.text.trim(),
        style: TextStyle(
          color: themeData.textColor,
          fontSize: fontSize * 0.7,
        ),
      ),
    );
  }

  Widget _renderSubscript(BuildContext context, dom.Element element) {
    return Transform.translate(
      offset: const Offset(0, 4),
      child: Text(
        element.text.trim(),
        style: TextStyle(
          color: themeData.textColor,
          fontSize: fontSize * 0.7,
        ),
      ),
    );
  }

  Widget _renderTextContent(BuildContext context, dom.Element element) {
    final text = element.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    // Get styling from CSS
    final textAlign = _getTextAlign(element);
    final isItalic = _isItalicFromStyle(element);
    final isBold = _isBoldFromStyle(element);
    final sizeMultiplier = _getFontSizeMultiplier(element);
    final margin = _getMargin(element);

    return Container(
      width: double.infinity,
      padding: margin,
      child: Text(
        text,
        style: TextStyle(
          color: themeData.textColor,
          fontSize: fontSize * sizeMultiplier,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          height: 1.6,
        ),
        textAlign: textAlign,
      ),
    );
  }
}
