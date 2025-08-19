import 'dart:async';

import '../core/cfi.dart';
import '../../ref_entities/epub_chapter_split_ref.dart';
import '../../utils/chapter_splitter.dart';
import 'split_cfi.dart';

/// Maps positions between split chapters and their original chapters.
///
/// Provides precise position translation services for split chapters,
/// enabling accurate CFI conversion and navigation between split parts
/// and the original chapter content.
///
/// ## Core Functions
/// - Calculate character offsets between split parts
/// - Map CFI positions from original to split chapters
/// - Handle boundary conditions and edge cases
/// - Support bidirectional position translation
///
/// ## Usage
/// ```dart
/// final mapper = SplitChapterPositionMapper();
/// 
/// // Map position from original chapter to split part
/// final splitCFI = await mapper.mapOriginalToSplit(
///   originalCFI,
///   splitRef,
/// );
/// 
/// // Map position from split part to original chapter
/// final originalCFI = await mapper.mapSplitToOriginal(
///   splitCFI,
///   splitRef,
/// );
/// ```
class SplitChapterPositionMapper {
  /// Cache for calculated boundaries to avoid repeated computation.
  static final Map<String, List<PartBoundary>> _boundaryCache = {};

  /// Maps a CFI from the original chapter to a specific split part.
  ///
  /// Takes a CFI pointing to the original chapter content and converts
  /// it to a CFI pointing to the equivalent position within a split part.
  ///
  /// Returns null if the position falls outside the split part's boundaries.
  static Future<SplitCFI?> mapOriginalToSplit(
    CFI originalCFI,
    EpubChapterSplitRef splitRef,
  ) async {
    // Get the precise boundaries for this split chapter
    final boundaries = await calculatePreciseBoundaries(splitRef);
    
    // Extract character position from the original CFI
    final characterOffset = _extractCharacterOffset(originalCFI);
    if (characterOffset == null) {
      // Without character offset, create split CFI for the current part
      return SplitCFI.fromStandardCFI(
        originalCFI,
        splitPart: splitRef.partNumber,
        totalParts: splitRef.totalParts,
      );
    }

    // Find the part containing this character offset
    final partIndex = splitRef.partNumber - 1; // Convert to 0-based
    if (partIndex >= boundaries.length) {
      return null;
    }

    final boundary = boundaries[partIndex];
    if (!boundary.contains(characterOffset)) {
      return null; // Position is not in this split part
    }

    // Calculate relative offset within the split part
    final relativeOffset = characterOffset - boundary.startOffset;
    
    // Create adjusted CFI with relative offset
    final adjustedCFI = _adjustCharacterOffset(originalCFI, relativeOffset);
    
    return SplitCFI.fromStandardCFI(
      adjustedCFI,
      splitPart: splitRef.partNumber,
      totalParts: splitRef.totalParts,
    );
  }

  /// Maps a CFI from a split part to the original chapter.
  ///
  /// Takes a split CFI and converts it to a CFI pointing to the
  /// equivalent position in the original chapter content.
  static Future<CFI> mapSplitToOriginal(
    SplitCFI splitCFI,
    EpubChapterSplitRef splitRef,
  ) async {
    // Validate split CFI matches the split reference
    if (splitCFI.splitPart != splitRef.partNumber ||
        splitCFI.totalParts != splitRef.totalParts) {
      throw ArgumentError(
        'Split CFI part ${splitCFI.splitPart}/${splitCFI.totalParts} '
        'does not match split reference ${splitRef.partNumber}/${splitRef.totalParts}'
      );
    }

    // Get precise boundaries
    final boundaries = await calculatePreciseBoundaries(splitRef);
    final partIndex = splitRef.partNumber - 1;
    
    if (partIndex >= boundaries.length) {
      throw ArgumentError('Invalid part number: ${splitRef.partNumber}');
    }

    // Extract relative offset from split CFI
    final relativeOffset = _extractCharacterOffset(splitCFI.baseCFI) ?? 0;
    
    // Calculate absolute offset in original chapter
    final absoluteOffset = boundaries[partIndex].startOffset + relativeOffset;
    
    // Create original CFI with absolute offset
    return _adjustCharacterOffset(splitCFI.baseCFI, absoluteOffset);
  }

  /// Calculates precise character boundaries for each part of a split chapter.
  ///
  /// This method loads the original chapter content and uses the same
  /// splitting algorithm to determine exact boundaries between parts.
  static Future<List<PartBoundary>> calculatePreciseBoundaries(
    EpubChapterSplitRef splitRef,
  ) async {
    // Use cache key to avoid recalculating boundaries
    final cacheKey = '${splitRef.originalChapter.contentFileName}_${splitRef.totalParts}';
    
    if (_boundaryCache.containsKey(cacheKey)) {
      return _boundaryCache[cacheKey]!;
    }

    // Load the original chapter content
    final originalContent = await splitRef.originalChapter.readHtmlContent();
    
    // Use ChapterSplitter to analyze the content
    final wordCount = ChapterSplitter.countWords(originalContent);
    final isLongEnough = wordCount > ChapterSplitter.maxWordsPerChapter;
    
    if (!isLongEnough && splitRef.totalParts > 1) {
      throw StateError(
        'Chapter with $wordCount words should not be split into ${splitRef.totalParts} parts'
      );
    }

    // Calculate boundaries using the same algorithm as ChapterSplitter
    final boundaries = await _calculateBoundariesFromContent(
      originalContent,
      splitRef.totalParts,
    );

    // Cache the results
    _boundaryCache[cacheKey] = boundaries;
    
    return boundaries;
  }

  /// Calculates part start offset for a specific split part.
  ///
  /// Returns the character offset where the split part begins in the
  /// original chapter content.
  static Future<int> calculatePartStartOffset(
    EpubChapterSplitRef splitRef,
  ) async {
    final boundaries = await calculatePreciseBoundaries(splitRef);
    final partIndex = splitRef.partNumber - 1;
    
    if (partIndex >= boundaries.length) {
      throw ArgumentError('Invalid part number: ${splitRef.partNumber}');
    }
    
    return boundaries[partIndex].startOffset;
  }

  /// Calculates part end offset for a specific split part.
  ///
  /// Returns the character offset where the split part ends in the
  /// original chapter content.
  static Future<int> calculatePartEndOffset(
    EpubChapterSplitRef splitRef,
  ) async {
    final boundaries = await calculatePreciseBoundaries(splitRef);
    final partIndex = splitRef.partNumber - 1;
    
    if (partIndex >= boundaries.length) {
      throw ArgumentError('Invalid part number: ${splitRef.partNumber}');
    }
    
    return boundaries[partIndex].endOffset;
  }

  /// Determines which split part contains a given character offset.
  ///
  /// Returns the part number (1-based) that contains the specified
  /// character offset in the original chapter.
  static Future<int?> findPartForOffset(
    int characterOffset,
    EpubChapterSplitRef anySplitRef, // Used to get splitting info
  ) async {
    final boundaries = await calculatePreciseBoundaries(anySplitRef);
    
    for (int i = 0; i < boundaries.length; i++) {
      if (boundaries[i].contains(characterOffset)) {
        return i + 1; // Return 1-based part number
      }
    }
    
    return null; // Offset is outside chapter boundaries
  }

  /// Validates that a split CFI is consistent with its split reference.
  ///
  /// Checks that the split CFI's position falls within the expected
  /// boundaries for the specified split part.
  static Future<bool> validateSplitCFI(
    SplitCFI splitCFI,
    EpubChapterSplitRef splitRef,
  ) async {
    try {
      // Check basic part number consistency
      if (splitCFI.splitPart != splitRef.partNumber ||
          splitCFI.totalParts != splitRef.totalParts) {
        return false;
      }

      // Check that the relative offset is within part boundaries
      final relativeOffset = _extractCharacterOffset(splitCFI.baseCFI);
      if (relativeOffset != null) {
        final boundaries = await calculatePreciseBoundaries(splitRef);
        final partIndex = splitRef.partNumber - 1;
        
        if (partIndex >= boundaries.length) {
          return false;
        }

        final partLength = boundaries[partIndex].length;
        if (relativeOffset < 0 || relativeOffset >= partLength) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears the boundary calculation cache.
  ///
  /// Useful for testing or when split chapter content has changed.
  static void clearCache() {
    _boundaryCache.clear();
  }

  /// Calculates boundaries from actual chapter content.
  static Future<List<PartBoundary>> _calculateBoundariesFromContent(
    String htmlContent,
    int totalParts,
  ) async {
    if (totalParts <= 1) {
      // Single part contains entire content
      return [
        PartBoundary(
          partNumber: 1,
          startOffset: 0,
          endOffset: htmlContent.length - 1,
        ),
      ];
    }

    // Strip HTML tags to get text content for accurate character counting
    final textContent = htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');
    final textLength = textContent.length;
    
    // Calculate approximate part boundaries
    final boundaries = <PartBoundary>[];
    final basePartLength = textLength ~/ totalParts;
    
    for (int i = 0; i < totalParts; i++) {
      final startOffset = i * basePartLength;
      final endOffset = (i == totalParts - 1) 
          ? textLength - 1 
          : (i + 1) * basePartLength - 1;
      
      boundaries.add(PartBoundary(
        partNumber: i + 1,
        startOffset: startOffset,
        endOffset: endOffset,
      ));
    }
    
    return boundaries;
  }

  /// Extracts character offset from a CFI.
  static int? _extractCharacterOffset(CFI cfi) {
    final match = RegExp(r':(\d+)').firstMatch(cfi.raw);
    return match != null ? int.parse(match.group(1)!) : null;
  }

  /// Adjusts the character offset in a CFI.
  static CFI _adjustCharacterOffset(CFI originalCFI, int newOffset) {
    // Replace existing offset
    final adjustedString = originalCFI.raw.replaceAll(
      RegExp(r':(\d+)'),
      ':$newOffset',
    );
    
    // Add offset if none exists
    if (!originalCFI.raw.contains(':')) {
      final insertPoint = originalCFI.raw.lastIndexOf(')');
      final withOffset = '${originalCFI.raw.substring(0, insertPoint)}:$newOffset${originalCFI.raw.substring(insertPoint)}';
      return CFI(withOffset);
    }
    
    return CFI(adjustedString);
  }
}

/// Represents the character boundaries of a split chapter part.
///
/// Used by the position mapper to track where each split part begins
/// and ends within the original chapter content.
class PartBoundary {
  final int partNumber;
  final int startOffset;
  final int endOffset;

  const PartBoundary({
    required this.partNumber,
    required this.startOffset,
    required this.endOffset,
  });

  /// The length of this part in characters.
  int get length => endOffset - startOffset + 1;

  /// Whether the given offset falls within this part's boundaries.
  bool contains(int offset) {
    return offset >= startOffset && offset <= endOffset;
  }

  @override
  String toString() {
    return 'PartBoundary(part: $partNumber, start: $startOffset, end: $endOffset, length: $length)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartBoundary &&
           other.partNumber == partNumber &&
           other.startOffset == startOffset &&
           other.endOffset == endOffset;
  }

  @override
  int get hashCode {
    return Object.hash(partNumber, startOffset, endOffset);
  }
}