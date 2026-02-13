import 'package:epubx_kuebiko/epubx_kuebiko.dart';
import 'package:flutter/foundation.dart';

/// Parses CSS from EPUB files and provides style lookup.
class EpubCssParser {
  final Map<String, Map<String, String>> _classStyles = {};
  final Map<String, Map<String, String>> _tagStyles = {};

  EpubCssParser();

  /// Extract and parse all CSS from an EPUB book.
  void parseFromBook(EpubBook book) {
    final cssFiles = book.Content?.Css;
    if (cssFiles == null) return;

    for (final entry in cssFiles.entries) {
      final content = entry.value.Content;
      if (content != null) {
        _parseCss(content);
      }
    }

    debugPrint('🎨 Parsed ${_classStyles.length} CSS classes, ${_tagStyles.length} tag styles');
  }

  /// Parse CSS content.
  void _parseCss(String css) {
    // Remove comments
    css = css.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    
    // Split by closing brace to get rules
    final rules = css.split('}');
    
    for (final rule in rules) {
      final parts = rule.split('{');
      if (parts.length != 2) continue;
      
      final selector = parts[0].trim();
      final declarations = parts[1].trim();
      
      if (selector.isEmpty || declarations.isEmpty) continue;
      
      final styles = _parseDeclarations(declarations);
      if (styles.isEmpty) continue;
      
      // Handle multiple selectors (comma-separated)
      for (var sel in selector.split(',')) {
        sel = sel.trim();
        if (sel.isEmpty) continue;
        
        if (sel.startsWith('.')) {
          // Class selector
          final className = sel.substring(1).split(' ').first.split(':').first;
          _classStyles[className] = {...?_classStyles[className], ...styles};
        } else if (sel.startsWith('#')) {
          // ID selector - treat like class
          final id = sel.substring(1).split(' ').first.split(':').first;
          _classStyles[id] = {...?_classStyles[id], ...styles};
        } else if (!sel.contains(' ') && !sel.contains('>') && !sel.contains('+')) {
          // Simple tag selector
          final tag = sel.split(':').first.toLowerCase();
          _tagStyles[tag] = {...?_tagStyles[tag], ...styles};
        }
      }
    }
  }

  /// Parse CSS declarations into a map.
  Map<String, String> _parseDeclarations(String declarations) {
    final result = <String, String>{};
    
    for (final decl in declarations.split(';')) {
      final colonIndex = decl.indexOf(':');
      if (colonIndex <= 0) continue;
      
      final property = decl.substring(0, colonIndex).trim().toLowerCase();
      final value = decl.substring(colonIndex + 1).trim().toLowerCase();
      
      if (property.isNotEmpty && value.isNotEmpty) {
        result[property] = value;
      }
    }
    
    return result;
  }

  /// Get styles for an element based on its tag, classes, and id.
  Map<String, String> getStylesForElement({
    required String tagName,
    String? className,
    String? id,
  }) {
    final result = <String, String>{};
    
    // Apply tag styles first
    final tag = tagName.toLowerCase();
    if (_tagStyles.containsKey(tag)) {
      result.addAll(_tagStyles[tag]!);
    }
    
    // Then class styles (can override tag styles)
    if (className != null && className.isNotEmpty) {
      for (final cls in className.split(RegExp(r'\s+'))) {
        if (_classStyles.containsKey(cls)) {
          result.addAll(_classStyles[cls]!);
        }
      }
    }
    
    // Then ID styles (highest priority for our purposes)
    if (id != null && id.isNotEmpty && _classStyles.containsKey(id)) {
      result.addAll(_classStyles[id]!);
    }
    
    return result;
  }

  /// Check if styles indicate text should be centered.
  bool isCentered(Map<String, String> styles) {
    final align = styles['text-align'] ?? '';
    return align.contains('center');
  }

  /// Check if styles indicate text should be right-aligned.
  bool isRightAligned(Map<String, String> styles) {
    final align = styles['text-align'] ?? '';
    return align.contains('right');
  }

  /// Check if styles indicate italic.
  bool isItalic(Map<String, String> styles) {
    final fontStyle = styles['font-style'] ?? '';
    return fontStyle.contains('italic');
  }

  /// Check if styles indicate bold.
  bool isBold(Map<String, String> styles) {
    final fontWeight = styles['font-weight'] ?? '';
    return fontWeight.contains('bold') || 
           fontWeight.contains('700') ||
           fontWeight.contains('800') ||
           fontWeight.contains('900');
  }
}
