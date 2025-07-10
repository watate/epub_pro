import 'dart:async';

import 'epub_chapter_ref.dart';

/// A reference to a part of a split chapter.
///
/// This class represents a portion of a larger chapter that has been split
/// for better readability. It extends [EpubChapterRef] and overrides
/// content reading to return only the specific part.
class EpubChapterSplitRef extends EpubChapterRef {
  /// The original chapter this part was split from
  final EpubChapterRef originalChapter;

  /// The part number (1-based)
  final int partNumber;

  /// Total number of parts this chapter was split into
  final int totalParts;

  /// The HTML content for this specific part
  final String? partContent;

  /// The original title before splitting
  final String? originalTitle;

  EpubChapterSplitRef({
    required this.originalChapter,
    required this.partNumber,
    required this.totalParts,
    this.partContent,
    this.originalTitle,
    required super.title,
    required super.contentFileName,
    super.anchor,
    super.subChapters,
  }) : super(
          epubTextContentFileRef: originalChapter.epubTextContentFileRef,
        );

  /// Reads only the HTML content for this specific part
  @override
  Future<String> readHtmlContent() async {
    // If we have the part content stored, return it directly
    if (partContent != null) {
      return partContent!;
    }

    // Otherwise, this shouldn't happen in normal usage
    // but we'll return empty string as a fallback
    return '';
  }

  /// Whether this is a split part (always true for this class)
  bool get isSplitPart => true;

  @override
  String toString() {
    return 'Title: $title (Part $partNumber of $totalParts), Original: $originalTitle';
  }
}
