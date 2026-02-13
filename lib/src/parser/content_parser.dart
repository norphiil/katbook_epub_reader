import 'package:epubx_kuebiko/epubx_kuebiko.dart';
import 'package:html/dom.dart' as dom;
import 'package:flutter/foundation.dart';

import '../models/chapter_node.dart';
import '../models/paragraph_element.dart';
import 'html_parser.dart';

/// Result of content parsing.
class ParseResult {
  final List<ChapterNode> tableOfContents;
  final List<ChapterNode> flatChapters;
  final List<ParagraphElement> paragraphs;

  const ParseResult({
    required this.tableOfContents,
    required this.flatChapters,
    required this.paragraphs,
  });
}

/// Parses EPUB content following chapter hierarchy.
class EpubContentParser {
  final EpubBook _book;
  final List<ChapterNode> _tableOfContents = [];
  final List<ChapterNode> _flatChapters = [];
  final List<ParagraphElement> _paragraphs = [];
  
  // Cache parsed HTML files
  final Map<String, List<dom.Element>> _parsedFiles = {};
  
  // Track which elements have been used (to avoid duplicates)
  final Set<String> _usedFileKeys = {};

  EpubContentParser(this._book);

  /// Parse the entire EPUB content.
  ParseResult parse() {
    _parseHtmlFiles();
    _addFrontMatter(); // Add content before chapters
    _processChapters();
    
    debugPrint('📑 TOC: ${_tableOfContents.length} root chapters');
    debugPrint('📑 Flat: ${_flatChapters.length} total chapters');
    debugPrint('📄 Paragraphs: ${_paragraphs.length}');
    
    return ParseResult(
      tableOfContents: _tableOfContents,
      flatChapters: _flatChapters,
      paragraphs: _paragraphs,
    );
  }

  /// Add front matter content (before chapters: cover, dedication, etc.)
  void _addFrontMatter() {
    if (_book.Chapters == null || _book.Chapters!.isEmpty) return;
    
    // Get spine order if available
    final spine = _book.Schema?.Package?.Spine?.Items;
    final manifest = _book.Schema?.Package?.Manifest?.Items;
    
    if (spine == null || manifest == null || manifest.isEmpty) return;
    
    // Collect ALL files referenced by chapters (including nested)
    final chapterFiles = <String>{};
    void collectChapterFiles(List<EpubChapter> chapters) {
      for (final chapter in chapters) {
        final fileName = chapter.ContentFileName;
        if (fileName != null) {
          chapterFiles.add(fileName);
          chapterFiles.add(fileName.split('/').last);
        }
        if (chapter.SubChapters != null) {
          collectChapterFiles(chapter.SubChapters!);
        }
      }
    }
    collectChapterFiles(_book.Chapters!);
    
    // Add front matter (files in spine that are NOT used by any chapter)
    int paragraphIndex = 0;
    
    for (final spineItem in spine) {
      // Find manifest item
      EpubManifestItem? manifestItem;
      for (final m in manifest) {
        if (m.Id == spineItem.IdRef) {
          manifestItem = m;
          break;
        }
      }
      
      if (manifestItem == null) continue;
      
      final href = manifestItem.Href;
      if (href == null) continue;
      
      final fileName = href.split('/').last;
      
      // Skip if this file is used by any chapter
      if (chapterFiles.contains(fileName) || chapterFiles.contains(href)) {
        continue;
      }
      
      // Find the content
      List<dom.Element>? elements;
      String? matchingKey;
      for (final entry in _parsedFiles.entries) {
        final entryName = entry.key.split('/').last;
        if (entryName == fileName || entry.key == href) {
          elements = entry.value;
          matchingKey = entry.key;
          break;
        }
      }
      
      if (elements == null || elements.isEmpty) continue;
      
      // Mark as used
      if (matchingKey != null) {
        _usedFileKeys.add(matchingKey);
      }
      
      debugPrint('📖 Adding front matter: $fileName (${elements.length} elements)');
      
      for (final element in elements) {
        _paragraphs.add(ParagraphElement(
          element: element,
          chapterIndex: 0,
          absoluteIndex: paragraphIndex,
          isChapterStart: paragraphIndex == 0,
          chapterTitle: paragraphIndex == 0 ? 'Couverture' : null,
        ));
        paragraphIndex++;
      }
    }
    
    // Add a front matter chapter if we found content
    if (paragraphIndex > 0) {
      final frontMatterNode = ChapterNode(
        title: 'Couverture',
        startIndex: 0,
        depth: 0,
      );
      _tableOfContents.insert(0, frontMatterNode);
      _flatChapters.insert(0, frontMatterNode);
    }
  }

  /// Pre-parse all HTML content files.
  void _parseHtmlFiles() {
    final htmlFiles = _book.Content?.Html;
    if (htmlFiles == null) return;

    for (final entry in htmlFiles.entries) {
      final fileName = entry.key;
      final content = entry.value.Content;
      if (content != null) {
        _parsedFiles[fileName] = EpubHtmlParser.parseHtmlToElements(content);
      }
    }
    
    debugPrint('📄 Parsed ${_parsedFiles.length} HTML files');
  }

  /// Process chapters in TOC order.
  void _processChapters() {
    if (_book.Chapters == null || _book.Chapters!.isEmpty) {
      _processWithoutToc();
      return;
    }

    // Start chapter index after front matter (if any)
    int chapterIndex = _flatChapters.length;
    // Start paragraph index after front matter paragraphs (if any)
    int paragraphIndex = _paragraphs.length;

    for (final chapter in _book.Chapters!) {
      final result = _processChapter(
        chapter: chapter,
        depth: 0,
        chapterIndex: chapterIndex,
        paragraphIndex: paragraphIndex,
      );
      
      _tableOfContents.add(result.node);
      chapterIndex = result.nextChapterIndex;
      paragraphIndex = result.nextParagraphIndex;
    }
  }

  /// Fallback when no TOC is defined.
  void _processWithoutToc() {
    int index = 0;
    for (final entry in _parsedFiles.entries) {
      for (final element in entry.value) {
        _paragraphs.add(ParagraphElement(
          element: element,
          chapterIndex: 0,
          absoluteIndex: index,
          isChapterStart: index == 0,
          chapterTitle: index == 0 ? (_book.Title ?? 'Content') : null,
        ));
        index++;
      }
    }
    
    if (_paragraphs.isNotEmpty) {
      final node = ChapterNode(
        title: _book.Title ?? 'Content',
        startIndex: 0,
        depth: 0,
      );
      _tableOfContents.add(node);
      _flatChapters.add(node);
    }
  }

  /// Process a single chapter and its subchapters.
  _ChapterResult _processChapter({
    required EpubChapter chapter,
    required int depth,
    required int chapterIndex,
    required int paragraphIndex,
  }) {
    final startIndex = paragraphIndex;
    final fileName = chapter.ContentFileName;
    
    debugPrint('  ${"  " * depth}📖 ${chapter.Title}');

    // Get elements for this chapter
    final elements = _getElementsForChapter(chapter);
    
    // Add paragraphs
    bool isFirst = true;
    for (final element in elements) {
      _paragraphs.add(ParagraphElement(
        element: element,
        chapterIndex: chapterIndex,
        absoluteIndex: paragraphIndex,
        isChapterStart: isFirst,
        chapterTitle: isFirst ? chapter.Title : null,
      ));
      paragraphIndex++;
      isFirst = false;
    }

    // Process subchapters
    final childNodes = <ChapterNode>[];
    int nextChapterIdx = chapterIndex + 1;
    
    if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
      for (final sub in chapter.SubChapters!) {
        final result = _processChapter(
          chapter: sub,
          depth: depth + 1,
          chapterIndex: nextChapterIdx,
          paragraphIndex: paragraphIndex,
        );
        childNodes.add(result.node);
        nextChapterIdx = result.nextChapterIndex;
        paragraphIndex = result.nextParagraphIndex;
      }
    }

    // Create node
    final node = ChapterNode(
      title: chapter.Title ?? 'Sans titre',
      startIndex: startIndex,
      depth: depth,
      children: childNodes,
      contentFileName: fileName,
      anchor: chapter.Anchor,
    );
    
    _flatChapters.add(node);

    return _ChapterResult(
      node: node,
      nextChapterIndex: nextChapterIdx,
      nextParagraphIndex: paragraphIndex,
    );
  }

  /// Get elements belonging to a specific chapter.
  List<dom.Element> _getElementsForChapter(EpubChapter chapter) {
    final fileName = chapter.ContentFileName;
    if (fileName == null) return [];

    // Find matching file key
    String? matchingKey;
    List<dom.Element>? allElements;
    for (final entry in _parsedFiles.entries) {
      if (_fileNamesMatch(entry.key, fileName)) {
        matchingKey = entry.key;
        allElements = entry.value;
        break;
      }
    }
    
    if (allElements == null || allElements.isEmpty) return [];

    final anchor = chapter.Anchor;
    final hasSubchapters = chapter.SubChapters?.isNotEmpty ?? false;
    
    // For chapters without anchors in already-used files, return empty
    // But only if file was used WITHOUT an anchor (i.e., fully consumed)
    if (_usedFileKeys.contains(matchingKey) && anchor == null && !hasSubchapters) {
      return [];
    }

    // Find start position
    int startIdx = 0;
    if (anchor != null) {
      for (int i = 0; i < allElements.length; i++) {
        if (EpubHtmlParser.elementContainsAnchor(allElements[i], anchor)) {
          startIdx = i;
          break;
        }
      }
    }

    // Find end position
    int endIdx = allElements.length;
    if (hasSubchapters) {
      for (final sub in chapter.SubChapters!) {
        final subAnchor = sub.Anchor;
        final subFile = sub.ContentFileName;
        
        if (_fileNamesMatch(fileName, subFile)) {
          if (subAnchor != null) {
            for (int i = startIdx + 1; i < allElements.length; i++) {
              if (EpubHtmlParser.elementContainsAnchor(allElements[i], subAnchor)) {
                endIdx = i;
                break;
              }
            }
          }
          break;
        }
      }
    }

    // Mark file as used ONLY if we're taking all content without anchor
    if (anchor == null && !hasSubchapters && matchingKey != null) {
      _usedFileKeys.add(matchingKey);
    }

    // Return a copy of the sublist
    if (startIdx >= endIdx) return [];
    return allElements.sublist(startIdx, endIdx);
  }

  /// Check if two file names refer to the same file.
  bool _fileNamesMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    
    // Compare just filenames
    final nameA = a.split('/').last;
    final nameB = b.split('/').last;
    return nameA == nameB;
  }
}

/// Internal result class for chapter processing.
class _ChapterResult {
  final ChapterNode node;
  final int nextChapterIndex;
  final int nextParagraphIndex;

  const _ChapterResult({
    required this.node,
    required this.nextChapterIndex,
    required this.nextParagraphIndex,
  });
}
