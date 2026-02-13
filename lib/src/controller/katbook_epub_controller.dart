import 'dart:async';
import 'dart:typed_data';

import 'package:epubx_kuebiko/epubx_kuebiko.dart';
import 'package:flutter/foundation.dart';

import '../models/chapter_node.dart';
import '../models/paragraph_element.dart';
import '../models/reading_position.dart';
import '../parser/parser.dart';

/// Controller for the Katbook EPUB Reader.
class KatbookEpubController extends ChangeNotifier {
  EpubBook? _book;
  List<ChapterNode> _tableOfContents = [];
  List<ChapterNode> _flatChapters = [];
  List<ParagraphElement> _paragraphs = [];
  Map<String, Uint8List> _imageData = {};
  ReadingPosition? _currentPosition;
  EpubCssParser? _cssParser;
  
  final _positionController = StreamController<ReadingPosition>.broadcast();
  
  bool _isLoaded = false;
  String? _loadingError;

  // ===== Getters =====
  
  EpubBook? get book => _book;
  bool get isLoaded => _isLoaded;
  String? get loadingError => _loadingError;
  List<ChapterNode> get tableOfContents => _tableOfContents;
  List<ChapterNode> get flatChapters => _flatChapters;
  List<ParagraphElement> get paragraphs => _paragraphs;
  int get totalParagraphs => _paragraphs.length;
  ReadingPosition? get currentPosition => _currentPosition;
  Stream<ReadingPosition> get positionStream => _positionController.stream;
  String? get title => _book?.Title;
  String? get author => _book?.Author;
  Map<String, Uint8List> get imageData => _imageData;
  EpubCssParser? get cssParser => _cssParser;

  // ===== Loading =====

  /// Load an EPUB from bytes.
  Future<bool> openBook(Uint8List data) async {
    try {
      _loadingError = null;
      _isLoaded = false;
      notifyListeners();

      // Parse EPUB
      _book = await EpubReader.readBook(data);
      if (_book == null) {
        _loadingError = 'Failed to parse EPUB file';
        notifyListeners();
        return false;
      }

      // Extract images
      _imageData = EpubImageExtractor.extractImages(_book!);

      // Parse CSS styles
      _cssParser = EpubCssParser();
      _cssParser!.parseFromBook(_book!);

      // Parse content
      final parser = EpubContentParser(_book!);
      final result = parser.parse();
      
      _tableOfContents = result.tableOfContents;
      _flatChapters = result.flatChapters;
      _paragraphs = result.paragraphs;

      // Initial position
      _currentPosition = ReadingPosition.initial(
        totalParagraphs: _paragraphs.length,
      );

      _isLoaded = true;
      notifyListeners();

      debugPrint('📚 Loaded: ${_book?.Title}');
      return true;
    } catch (e, stack) {
      _loadingError = e.toString();
      debugPrint('❌ Error: $e\n$stack');
      notifyListeners();
      return false;
    }
  }

  // ===== Navigation =====

  /// Jump to a paragraph index.
  void jumpToIndex(int index, {double offset = 0.0}) {
    if (index < 0 || index >= _paragraphs.length) return;

    final paragraph = _paragraphs[index];
    final chapter = _findChapterForIndex(index);

    _currentPosition = ReadingPosition(
      chapterIndex: paragraph.chapterIndex,
      paragraphIndex: index,
      chapterTitle: chapter?.title,
      totalParagraphs: _paragraphs.length,
      paragraphOffset: offset,
    );

    _positionController.add(_currentPosition!);
    notifyListeners();
  }

  /// Jump to a chapter.
  void jumpToChapter(ChapterNode chapter) {
    jumpToIndex(chapter.startIndex);
  }

  /// Jump to a saved position.
  void jumpToPosition(ReadingPosition position) {
    jumpToIndex(position.paragraphIndex, offset: position.paragraphOffset);
  }

  /// Update position from scroll.
  void updatePositionFromScroll(int visibleIndex, double offset) {
    if (!_isLoaded || _paragraphs.isEmpty) return;
    if (visibleIndex < 0 || visibleIndex >= _paragraphs.length) return;

    final chapter = _findChapterForIndex(visibleIndex);

    final newPosition = ReadingPosition(
      chapterIndex: _paragraphs[visibleIndex].chapterIndex,
      paragraphIndex: visibleIndex,
      chapterTitle: chapter?.title,
      totalParagraphs: _paragraphs.length,
      paragraphOffset: offset,
    );

    if (_currentPosition?.paragraphIndex != visibleIndex) {
      _currentPosition = newPosition;
      _positionController.add(newPosition);
      notifyListeners();
    }
  }

  /// Find chapter containing a paragraph index.
  ChapterNode? _findChapterForIndex(int index) {
    ChapterNode? result;
    for (final chapter in _flatChapters) {
      if (chapter.startIndex <= index) {
        result = chapter;
      } else {
        break;
      }
    }
    return result;
  }

  @override
  void dispose() {
    _positionController.close();
    super.dispose();
  }
}
