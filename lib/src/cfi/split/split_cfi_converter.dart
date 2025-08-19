import '../core/cfi.dart';
import '../../ref_entities/epub_chapter_split_ref.dart';
import 'split_cfi.dart';

/// Converter for translating between Split CFI and Standard CFI formats.
///
/// Provides bidirectional conversion between standard EPUB CFI and the
/// split CFI extension, enabling precise positioning within split chapters
/// while maintaining compatibility with existing CFI ecosystems.
///
/// ## Use Cases
/// - Converting split chapter positions to standard CFI for storage
/// - Converting standard CFI to split CFI for precise navigation
/// - Mapping positions between split parts and original chapters
///
/// ## Example
/// ```dart
/// final converter = SplitCFIConverter();
///
/// // Convert standard CFI to split CFI
/// final standardCFI = CFI('epubcfi(/6/4!/4/10/2:500)');
/// final splitCFI = converter.standardToSplit(
///   standardCFI,
///   splitRef: mySplitChapterRef,
/// );
///
/// // Convert split CFI back to standard CFI
/// final backToStandard = converter.splitToStandard(splitCFI, splitRef);
/// ```
class SplitCFIConverter {
  /// Converts a standard CFI to a split CFI using split chapter context.
  ///
  /// Takes a standard CFI that points to an original chapter and converts
  /// it to a split CFI that points to the appropriate split part with
  /// adjusted character offsets.
  ///
  /// Returns null if the standard CFI doesn't fall within the split chapter
  /// boundaries.
  ///
  /// ```dart
  /// final standardCFI = CFI('epubcfi(/6/4!/4/10/2:500)');
  /// final splitCFI = converter.standardToSplit(
  ///   standardCFI,
  ///   splitRef: chapterPart2Of3,
  /// );
  /// ```
  static SplitCFI? standardToSplit(
    CFI standardCFI,
    EpubChapterSplitRef splitRef,
  ) {
    // Extract character position from standard CFI
    final characterOffset = _extractCharacterOffset(standardCFI);
    if (characterOffset == null) {
      // No character offset to map, create split CFI for the part
      return SplitCFI.fromStandardCFI(
        standardCFI,
        splitPart: splitRef.partNumber,
        totalParts: splitRef.totalParts,
      );
    }

    // Calculate split part boundaries
    final partBoundaries = _calculatePartBoundaries(splitRef);

    // Find which part contains this character offset
    for (int i = 0; i < partBoundaries.length; i++) {
      final boundary = partBoundaries[i];
      if (characterOffset >= boundary.startOffset &&
          characterOffset <= boundary.endOffset) {
        // Calculate relative offset within the part
        final relativeOffset = characterOffset - boundary.startOffset;

        // Create split CFI with adjusted offset
        final adjustedCFI = _adjustCharacterOffset(
          standardCFI,
          relativeOffset,
        );

        return SplitCFI.fromStandardCFI(
          adjustedCFI,
          splitPart: i + 1, // Parts are 1-based
          totalParts: splitRef.totalParts,
        );
      }
    }

    // Character offset is outside split chapter boundaries
    return null;
  }

  /// Converts a split CFI to a standard CFI using split chapter context.
  ///
  /// Takes a split CFI and converts it to a standard CFI that points to
  /// the corresponding position in the original chapter, adjusting character
  /// offsets to account for the split.
  ///
  /// ```dart
  /// final splitCFI = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:50)');
  /// final standardCFI = converter.splitToStandard(splitCFI, splitRef);
  /// ```
  static CFI splitToStandard(
    SplitCFI splitCFI,
    EpubChapterSplitRef splitRef,
  ) {
    // Validate that the split CFI matches the split reference
    if (splitCFI.splitPart != splitRef.partNumber ||
        splitCFI.totalParts != splitRef.totalParts) {
      throw ArgumentError(
          'Split CFI (${splitCFI.splitPart}/${splitCFI.totalParts}) '
          'does not match split reference (${splitRef.partNumber}/${splitRef.totalParts})');
    }

    // Extract character offset from split CFI
    final relativeOffset = _extractCharacterOffset(splitCFI.baseCFI);
    if (relativeOffset == null) {
      // No character offset to adjust
      return splitCFI.baseCFI;
    }

    // Calculate the absolute offset in the original chapter
    final partBoundaries = _calculatePartBoundaries(splitRef);
    final partIndex = splitRef.partNumber - 1; // Convert to 0-based

    if (partIndex >= partBoundaries.length) {
      throw ArgumentError('Invalid part number: ${splitRef.partNumber}');
    }

    final absoluteOffset =
        partBoundaries[partIndex].startOffset + relativeOffset;

    // Create standard CFI with absolute offset
    return _adjustCharacterOffset(splitCFI.baseCFI, absoluteOffset);
  }

  /// Determines which split part a standard CFI position falls into.
  ///
  /// Returns the part number (1-based) or null if the position is outside
  /// the split chapter boundaries.
  static int? getPartForPosition(
    CFI standardCFI,
    List<EpubChapterSplitRef> splitParts,
  ) {
    if (splitParts.isEmpty) return null;

    final characterOffset = _extractCharacterOffset(standardCFI);
    if (characterOffset == null) {
      // Without character offset, assume first part
      return 1;
    }

    // Use the first part to get the structure (all parts share the same original)
    final firstPart = splitParts.first;
    final partBoundaries = _calculatePartBoundaries(firstPart);

    for (int i = 0; i < partBoundaries.length; i++) {
      final boundary = partBoundaries[i];
      if (characterOffset >= boundary.startOffset &&
          characterOffset <= boundary.endOffset) {
        return i + 1; // Return 1-based part number
      }
    }

    return null;
  }

  /// Extracts character offset from a CFI.
  static int? _extractCharacterOffset(CFI cfi) {
    // Look for character offset in the CFI string (format: :number)
    final match = RegExp(r':(\d+)').firstMatch(cfi.raw);
    return match != null ? int.parse(match.group(1)!) : null;
  }

  /// Adjusts the character offset in a CFI string.
  static CFI _adjustCharacterOffset(CFI originalCFI, int newOffset) {
    // Replace the character offset in the CFI string
    final adjustedString = originalCFI.raw.replaceAll(
      RegExp(r':(\d+)'),
      ':$newOffset',
    );

    // If no offset was found, add one
    if (!originalCFI.raw.contains(':')) {
      // Find the last part and add offset
      final insertPoint = originalCFI.raw.lastIndexOf(')');
      final withOffset =
          '${originalCFI.raw.substring(0, insertPoint)}:$newOffset${originalCFI.raw.substring(insertPoint)}';
      return CFI(withOffset);
    }

    return CFI(adjustedString);
  }

  /// Calculates character boundaries for each part of a split chapter.
  static List<PartBoundary> _calculatePartBoundaries(
      EpubChapterSplitRef splitRef) {
    // This is a simplified implementation
    // In practice, this would need to load the original chapter content
    // and calculate exact boundaries based on the splitting algorithm

    final totalParts = splitRef.totalParts;
    final boundaries = <PartBoundary>[];

    // Estimate boundaries (this would be more precise in real implementation)
    // For now, assume equal distribution as a placeholder
    const estimatedTotalChars =
        10000; // Would be calculated from actual content
    final charsPerPart = estimatedTotalChars ~/ totalParts;

    for (int i = 0; i < totalParts; i++) {
      final startOffset = i * charsPerPart;
      final endOffset = (i == totalParts - 1)
          ? estimatedTotalChars - 1
          : (i + 1) * charsPerPart - 1;

      boundaries.add(PartBoundary(
        partNumber: i + 1,
        startOffset: startOffset,
        endOffset: endOffset,
      ));
    }

    return boundaries;
  }
}

/// Represents the character boundaries of a split chapter part.
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
    return 'PartBoundary(part: $partNumber, start: $startOffset, end: $endOffset)';
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
