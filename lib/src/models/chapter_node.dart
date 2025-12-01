/// Represents a chapter or subchapter in the EPUB table of contents.
///
/// This class supports arbitrary nesting depth, allowing proper representation
/// of complex EPUB structures with chapters, subchapters, sub-subchapters, etc.
class ChapterNode {
  /// The title of this chapter.
  final String title;

  /// The starting paragraph index in the flattened content.
  final int startIndex;

  /// The depth level (0 = top-level chapter, 1 = subchapter, etc.)
  final int depth;

  /// Child chapters (subchapters of this chapter).
  final List<ChapterNode> children;

  /// The content file name in the EPUB (for internal use).
  final String? contentFileName;

  /// The anchor within the content file (for internal use).
  final String? anchor;

  const ChapterNode({
    required this.title,
    required this.startIndex,
    this.depth = 0,
    this.children = const [],
    this.contentFileName,
    this.anchor,
  });

  /// Whether this chapter has subchapters.
  bool get hasChildren => children.isNotEmpty;

  /// The type identifier (for compatibility).
  String get type => depth == 0 ? 'chapter' : 'subchapter';

  /// Create a copy with modified properties.
  ChapterNode copyWith({
    String? title,
    int? startIndex,
    int? depth,
    List<ChapterNode>? children,
    String? contentFileName,
    String? anchor,
  }) {
    return ChapterNode(
      title: title ?? this.title,
      startIndex: startIndex ?? this.startIndex,
      depth: depth ?? this.depth,
      children: children ?? this.children,
      contentFileName: contentFileName ?? this.contentFileName,
      anchor: anchor ?? this.anchor,
    );
  }

  /// Convert to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startIndex': startIndex,
      'depth': depth,
      'children': children.map((c) => c.toJson()).toList(),
      if (contentFileName != null) 'contentFileName': contentFileName,
      if (anchor != null) 'anchor': anchor,
    };
  }

  /// Create from JSON.
  factory ChapterNode.fromJson(Map<String, dynamic> json) {
    return ChapterNode(
      title: json['title'] as String,
      startIndex: json['startIndex'] as int,
      depth: json['depth'] as int? ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => ChapterNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      contentFileName: json['contentFileName'] as String?,
      anchor: json['anchor'] as String?,
    );
  }

  @override
  String toString() {
    return 'ChapterNode(title: $title, startIndex: $startIndex, depth: $depth, children: ${children.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterNode &&
        other.title == title &&
        other.startIndex == startIndex &&
        other.depth == depth;
  }

  @override
  int get hashCode => Object.hash(title, startIndex, depth);
}
