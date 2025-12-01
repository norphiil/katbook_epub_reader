/// Represents the current reading position in an EPUB.
///
/// This class provides comprehensive position tracking including:
/// - Chapter index and title
/// - Paragraph index within the book
/// - Reading progress as a percentage
///
/// Positions can be serialized to JSON for persistent storage.
class ReadingPosition {
  /// Index of the current chapter in the flat chapter list.
  final int chapterIndex;

  /// Index of the current paragraph in the entire book.
  final int paragraphIndex;

  /// Title of the current chapter (may be null for untitled chapters).
  final String? chapterTitle;

  /// Total number of paragraphs in the book (for progress calculation).
  final int totalParagraphs;

  /// Scroll offset within the current paragraph (0.0 to 1.0).
  final double paragraphOffset;

  const ReadingPosition({
    required this.chapterIndex,
    required this.paragraphIndex,
    this.chapterTitle,
    required this.totalParagraphs,
    this.paragraphOffset = 0.0,
  });

  /// Calculate the reading progress as a percentage (0-100).
  double get progressPercent {
    if (totalParagraphs == 0) return 0.0;
    final baseProgress = (paragraphIndex / totalParagraphs) * 100;
    final offsetBonus = (paragraphOffset / totalParagraphs) * 100;
    return (baseProgress + offsetBonus).clamp(0.0, 100.0);
  }

  /// Whether this position is at the beginning of the book.
  bool get isAtStart => paragraphIndex == 0 && paragraphOffset == 0.0;

  /// Whether this position is at the end of the book.
  bool get isAtEnd => paragraphIndex >= totalParagraphs - 1;

  /// Create a copy with modified properties.
  ReadingPosition copyWith({
    int? chapterIndex,
    int? paragraphIndex,
    String? chapterTitle,
    int? totalParagraphs,
    double? paragraphOffset,
  }) {
    return ReadingPosition(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      totalParagraphs: totalParagraphs ?? this.totalParagraphs,
      paragraphOffset: paragraphOffset ?? this.paragraphOffset,
    );
  }

  /// Convert to JSON for persistent storage.
  Map<String, dynamic> toJson() {
    return {
      'chapterIndex': chapterIndex,
      'paragraphIndex': paragraphIndex,
      if (chapterTitle != null) 'chapterTitle': chapterTitle,
      'totalParagraphs': totalParagraphs,
      'paragraphOffset': paragraphOffset,
    };
  }

  /// Create from JSON.
  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    return ReadingPosition(
      chapterIndex: json['chapterIndex'] as int? ?? 0,
      paragraphIndex: json['paragraphIndex'] as int? ?? 0,
      chapterTitle: json['chapterTitle'] as String?,
      totalParagraphs: json['totalParagraphs'] as int? ?? 0,
      paragraphOffset: (json['paragraphOffset'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Create an initial position (start of book).
  factory ReadingPosition.initial({int totalParagraphs = 0}) {
    return ReadingPosition(
      chapterIndex: 0,
      paragraphIndex: 0,
      totalParagraphs: totalParagraphs,
    );
  }

  @override
  String toString() {
    return 'ReadingPosition(chapter: $chapterIndex, paragraph: $paragraphIndex, progress: ${progressPercent.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingPosition &&
        other.chapterIndex == chapterIndex &&
        other.paragraphIndex == paragraphIndex &&
        other.paragraphOffset == paragraphOffset;
  }

  @override
  int get hashCode => Object.hash(chapterIndex, paragraphIndex, paragraphOffset);
}
