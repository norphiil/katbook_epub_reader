import 'package:html/dom.dart' as dom;

/// Represents a parsed paragraph element from the EPUB content.
///
/// Each paragraph contains the HTML element, its chapter association,
/// and metadata needed for rendering and navigation.
class ParagraphElement {
  /// The HTML element containing the paragraph content.
  final dom.Element element;

  /// Index of the chapter this paragraph belongs to.
  final int chapterIndex;

  /// The absolute index of this paragraph in the entire book.
  final int absoluteIndex;

  /// Whether this paragraph starts a new chapter.
  final bool isChapterStart;

  /// The chapter title (if this is a chapter start).
  final String? chapterTitle;

  const ParagraphElement({
    required this.element,
    required this.chapterIndex,
    required this.absoluteIndex,
    this.isChapterStart = false,
    this.chapterTitle,
  });

  /// Get the outer HTML of this element.
  String get outerHtml => element.outerHtml;

  /// Get the inner HTML of this element.
  String get innerHtml => element.innerHtml;

  /// Get the text content without HTML tags.
  String get text => element.text;

  /// Get the element's tag name (e.g., 'p', 'div', 'h1').
  String get tagName => element.localName ?? 'div';

  /// Whether this is a heading element.
  bool get isHeading {
    final tag = tagName.toLowerCase();
    return tag.startsWith('h') && tag.length == 2;
  }

  /// Whether this element contains an image.
  bool get containsImage {
    return element.querySelector('img') != null ||
        element.querySelector('image') != null ||
        element.querySelector('svg') != null;
  }

  /// Create a copy with modified properties.
  ParagraphElement copyWith({
    dom.Element? element,
    int? chapterIndex,
    int? absoluteIndex,
    bool? isChapterStart,
    String? chapterTitle,
  }) {
    return ParagraphElement(
      element: element ?? this.element,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      absoluteIndex: absoluteIndex ?? this.absoluteIndex,
      isChapterStart: isChapterStart ?? this.isChapterStart,
      chapterTitle: chapterTitle ?? this.chapterTitle,
    );
  }

  @override
  String toString() {
    return 'ParagraphElement(index: $absoluteIndex, chapter: $chapterIndex, tag: $tagName)';
  }
}
