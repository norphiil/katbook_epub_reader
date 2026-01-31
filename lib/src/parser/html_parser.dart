import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

/// Utility class for parsing HTML content from EPUB files.
class EpubHtmlParser {
  /// Parse HTML content to a list of displayable elements.
  static List<dom.Element> parseHtmlToElements(String htmlContent) {
    try {
      final document = parse(htmlContent);
      final body = document.body;
      if (body == null) return [];

      final result = <dom.Element>[];
      _extractElements(body.children, result);
      return result;
    } catch (e) {
      debugPrint('❌ Error parsing HTML: $e');
      return [];
    }
  }

  /// Extract meaningful elements recursively.
  static void _extractElements(List<dom.Element> elements, List<dom.Element> result) {
    for (final element in elements) {
      final tag = element.localName?.toLowerCase() ?? '';

      // Skip non-content elements
      if (_isSkippableTag(tag)) continue;

      // Handle container elements
      if (_isContainerTag(tag)) {
        // If container has inline style with important layout info, keep it as-is
        if (_hasImportantStyle(element)) {
          result.add(element);
        } else if (element.children.isEmpty && element.text.trim().isNotEmpty) {
          result.add(element);
        } else if (element.children.isNotEmpty) {
          _extractElements(element.children, result);
        }
      } else if (_isContentElement(element)) {
        result.add(element);
      }
    }
  }

  static bool _isSkippableTag(String tag) {
    return ['style', 'script', 'meta', 'link', 'head'].contains(tag);
  }

  static bool _isContainerTag(String tag) {
    return ['div', 'section', 'article', 'aside', 'main', 'nav'].contains(tag);
  }

  /// Check if element has important styling that should be preserved.
  static bool _hasImportantStyle(dom.Element element) {
    final style = element.attributes['style']?.toLowerCase() ?? '';
    final className = element.className.toLowerCase();
    
    // Important layout styles
    if (style.contains('text-align') ||
        style.contains('margin') ||
        style.contains('text-indent') ||
        style.contains('font-style') ||
        style.contains('font-weight')) {
      return true;
    }
    
    // Important classes (common in ebooks)
    if (className.contains('center') ||
        className.contains('right') ||
        className.contains('italic') ||
        className.contains('dedication') ||
        className.contains('epigraph') ||
        className.contains('quote') ||
        className.contains('signature') ||
        className.contains('attribution')) {
      return true;
    }
    
    return false;
  }

  static bool _isContentElement(dom.Element element) {
    final tag = element.localName?.toLowerCase() ?? '';
    
    // Block-level content tags
    if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'pre', 
         'ul', 'ol', 'table', 'figure', 'img', 'hr', 'br'].contains(tag)) {
      return true;
    }

    // Has text content
    if (element.text.trim().isNotEmpty) return true;

    // Has images
    if (element.querySelector('img, image, svg') != null) return true;

    return false;
  }

  /// Check if an element contains a specific ID or name anchor.
  static bool elementContainsAnchor(dom.Element element, String anchor) {
    if (element.id == anchor) return true;
    if (element.attributes['name'] == anchor) return true;
    
    // Use attribute selector instead of #id to avoid CSS selector parsing issues
    // with IDs containing special characters like dots followed by numbers
    try {
      if (element.querySelector('[id="$anchor"]') != null) return true;
    } catch (_) {
      // Fallback: manually search for the element
      if (_findElementById(element, anchor) != null) return true;
    }
    
    try {
      if (element.querySelector('[name="$anchor"]') != null) return true;
    } catch (_) {
      // Ignore selector parsing errors
    }
    
    return false;
  }

  /// Manually find an element by ID (fallback for invalid CSS selectors).
  static dom.Element? _findElementById(dom.Element parent, String id) {
    if (parent.id == id) return parent;
    for (final child in parent.children) {
      final found = _findElementById(child, id);
      if (found != null) return found;
    }
    return null;
  }
}
