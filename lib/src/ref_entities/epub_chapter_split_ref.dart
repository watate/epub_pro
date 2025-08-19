import 'dart:async';

import 'epub_chapter_ref.dart';
import '../cfi/core/cfi.dart';
import '../cfi/split/split_cfi.dart';
import '../cfi/split/split_position_mapper.dart';
import '../cfi/epub/epub_cfi_manager.dart';

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

  /// Generates a Split CFI for a position within this split chapter part.
  ///
  /// Creates a Split CFI that precisely identifies a location within
  /// this specific part of the split chapter.
  ///
  /// ```dart
  /// final splitCFI = await splitChapterRef.generateSplitCFI(
  ///   elementPath: '/4/10/2',
  ///   characterOffset: 15,
  ///   bookRef: bookRef,
  /// );
  /// ```
  Future<SplitCFI?> generateSplitCFI({
    required String elementPath,
    int? characterOffset,
    required EpubCFIManager cfiManager,
  }) async {
    // Generate standard CFI for the original chapter
    final standardCFI = await cfiManager.generateCFI(
      chapterRef: originalChapter,
      elementPath: elementPath,
      characterOffset: characterOffset,
    );

    if (standardCFI == null) return null;

    // Convert to Split CFI using position mapper
    return await SplitChapterPositionMapper.mapOriginalToSplit(
      standardCFI,
      this,
    );
  }

  /// Generates a standard CFI for a position within this split chapter part.
  ///
  /// Converts the split chapter position to a standard CFI that points
  /// to the equivalent position in the original chapter.
  ///
  /// ```dart
  /// final standardCFI = await splitChapterRef.generateStandardCFI(
  ///   elementPath: '/4/10/2',
  ///   characterOffset: 15,
  ///   bookRef: bookRef,
  /// );
  /// ```
  Future<CFI?> generateStandardCFI({
    required String elementPath,
    int? characterOffset,
    required EpubCFIManager cfiManager,
  }) async {
    // Generate Split CFI first
    final splitCFI = await generateSplitCFI(
      elementPath: elementPath,
      characterOffset: characterOffset,
      cfiManager: cfiManager,
    );

    if (splitCFI == null) return null;

    // Convert to standard CFI
    return await SplitChapterPositionMapper.mapSplitToOriginal(
      splitCFI,
      this,
    );
  }

  /// Gets the character offset where this split part starts in the original chapter.
  Future<int> getPartStartOffset() async {
    return await SplitChapterPositionMapper.calculatePartStartOffset(this);
  }

  /// Gets the character offset where this split part ends in the original chapter.
  Future<int> getPartEndOffset() async {
    return await SplitChapterPositionMapper.calculatePartEndOffset(this);
  }

  @override
  String toString() {
    return 'Title: $title (Part $partNumber of $totalParts), Original: $originalTitle';
  }
}
