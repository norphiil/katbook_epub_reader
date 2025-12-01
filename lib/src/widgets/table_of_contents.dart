import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/chapter_node.dart';
import '../models/reader_theme.dart';

/// Widget for displaying the table of contents in a drawer.
class TableOfContentsWidget extends StatelessWidget {
  /// Creates a new table of contents widget.
  const TableOfContentsWidget({
    super.key,
    required this.chapters,
    required this.themeData,
    required this.onChapterTap,
    this.currentParagraphIndex = -1,
    this.bookTitle,
    this.bookAuthor,
    this.coverImage,
  });

  /// List of chapters in the book.
  final List<ChapterNode> chapters;

  /// The current theme data.
  final ReaderThemeData themeData;

  /// Callback when a chapter is tapped.
  final void Function(ChapterNode chapter) onChapterTap;

  /// Index of the current paragraph being read (for highlighting active chapter).
  final int currentParagraphIndex;

  /// Title of the book.
  final String? bookTitle;

  /// Author of the book.
  final String? bookAuthor;

  /// Cover image data.
  final Uint8List? coverImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with book info
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: themeData.accentColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: themeData.textColor.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bookTitle != null)
                Text(
                  bookTitle!,
                  style: TextStyle(
                    color: themeData.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (bookAuthor != null) ...[
                const SizedBox(height: 4),
                Text(
                  bookAuthor!,
                  style: TextStyle(
                    color: themeData.secondaryTextColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // Table of contents
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: _buildChaptersList(chapters),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChaptersList(List<ChapterNode> chapters, {int depth = 0}) {
    final widgets = <Widget>[];

    for (final chapter in chapters) {
      widgets.add(
        _buildChapterTile(chapter, depth),
      );

      if (chapter.children.isNotEmpty) {
        widgets.addAll(_buildChaptersList(chapter.children, depth: depth + 1));
      }
    }

    return widgets;
  }

  Widget _buildChapterTile(ChapterNode chapter, int depth) {
    // A chapter is current if the current paragraph is at or after its start index
    // but before the next chapter's start index
    final isCurrentChapter = _isChapterActive(chapter);
    final indentLevel = depth * 16.0;

    return Material(
      color: isCurrentChapter
          ? themeData.accentColor.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onChapterTap(chapter),
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0 + indentLevel,
            right: 16.0,
            top: 12.0,
            bottom: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.title,
                style: TextStyle(
                  color: isCurrentChapter
                      ? themeData.accentColor
                      : themeData.textColor,
                  fontSize: 14 - (depth * 1.0).clamp(0, 2),
                  fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (chapter.children.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${chapter.children.length} sections',
                    style: TextStyle(
                      color: themeData.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if a chapter is the currently active one based on paragraph index.
  bool _isChapterActive(ChapterNode chapter) {
    if (currentParagraphIndex < 0) return false;
    if (currentParagraphIndex < chapter.startIndex) return false;
    
    // Check if any child chapter is active (has a lower or equal start index 
    // that is still <= currentParagraphIndex)
    for (final child in chapter.children) {
      if (currentParagraphIndex >= child.startIndex) {
        // A child chapter starts before or at the current position
        // So this parent is not the active one
        return false;
      }
    }
    
    // Current paragraph is at or after this chapter's start
    // and before any child chapter's start
    return true;
  }
}
