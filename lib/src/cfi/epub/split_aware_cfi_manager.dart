import '../core/cfi.dart';
import '../split/split_cfi.dart';
import '../split/split_cfi_parser.dart';
import '../split/split_position_mapper.dart';
import '../../ref_entities/epub_chapter_ref.dart';
import '../../ref_entities/epub_chapter_split_ref.dart';
import 'epub_cfi_manager.dart';

/// Enhanced CFI manager with split chapter awareness.
///
/// Extends the standard [EpubCFIManager] to provide seamless handling of
/// both standard CFI and split CFI formats. Automatically detects split
/// chapters and provides appropriate CFI operations.
///
/// ## Features
/// - Automatic detection of split vs standard chapters
/// - Bidirectional CFI conversion (standard ↔ split)
/// - Seamless navigation between split parts
/// - Full backward compatibility with standard CFI
/// - Precise position mapping across split boundaries
///
/// ## Usage
/// ```dart
/// final manager = SplitAwareCFIManager(bookRef);
///
/// // Works with both standard and split CFI
/// final location = await manager.navigateToCFI(anyCFI);
///
/// // Generate appropriate CFI type based on chapter
/// final cfi = await manager.generateCFI(
///   chapterRef: splitChapterRef,
///   elementPath: '/4/10/2',
///   characterOffset: 15,
/// );
/// ```
class SplitAwareCFIManager extends EpubCFIManager {
  /// Creates a split-aware CFI manager for the given book.
  SplitAwareCFIManager(super.bookRef);

  /// Navigates to a CFI location, handling both standard and split CFI.
  ///
  /// Automatically detects CFI type and performs appropriate navigation:
  /// - Standard CFI: Uses base implementation
  /// - Split CFI: Maps to original chapter position and navigates
  ///
  /// Returns null if the CFI cannot be resolved.
  @override
  Future<CFILocation?> navigateToCFI(CFI cfi) async {
    // Check if this is a split CFI
    final splitCFI = cfi.toSplitCFI();
    if (splitCFI != null) {
      return await _navigateToSplitCFI(splitCFI);
    }

    // Use standard navigation for regular CFI
    return await super.navigateToCFI(cfi);
  }

  /// Generates a CFI for the given chapter reference and position.
  ///
  /// Automatically creates the appropriate CFI type:
  /// - Split CFI for [EpubChapterSplitRef] instances
  /// - Standard CFI for regular chapter references
  @override
  Future<CFI?> generateCFI({
    required EpubChapterRef chapterRef,
    required String elementPath,
    int? characterOffset,
  }) async {
    // Check if this is a split chapter reference
    if (chapterRef is EpubChapterSplitRef) {
      return await _generateSplitCFI(
        chapterRef,
        elementPath,
        characterOffset,
      );
    }

    // Use standard generation for regular chapters
    return await super.generateCFI(
      chapterRef: chapterRef,
      elementPath: elementPath,
      characterOffset: characterOffset,
    );
  }

  /// Validates a CFI, handling both standard and split CFI formats.
  @override
  Future<bool> validateCFI(CFI cfi) async {
    // Check if this is a split CFI
    final splitCFI = cfi.toSplitCFI();
    if (splitCFI != null) {
      return await _validateSplitCFI(splitCFI);
    }

    // Use standard validation for regular CFI
    return await super.validateCFI(cfi);
  }

  /// Converts a standard CFI to a split CFI for the given split chapter.
  ///
  /// Returns null if the standard CFI doesn't fall within the split
  /// chapter's boundaries.
  ///
  /// ```dart
  /// final standardCFI = CFI('epubcfi(/6/4!/4/10/2:500)');
  /// final splitCFI = await manager.convertToSplitCFI(
  ///   standardCFI,
  ///   splitChapterRef,
  /// );
  /// ```
  Future<SplitCFI?> convertToSplitCFI(
    CFI standardCFI,
    EpubChapterSplitRef splitRef,
  ) async {
    return await SplitChapterPositionMapper.mapOriginalToSplit(
      standardCFI,
      splitRef,
    );
  }

  /// Converts a split CFI to a standard CFI.
  ///
  /// Useful for interoperability with systems that don't understand
  /// split CFI notation.
  ///
  /// ```dart
  /// final splitCFI = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:50)');
  /// final standardCFI = await manager.convertToStandardCFI(
  ///   splitCFI,
  ///   splitChapterRef,
  /// );
  /// ```
  Future<CFI> convertToStandardCFI(
    SplitCFI splitCFI,
    EpubChapterSplitRef splitRef,
  ) async {
    return await SplitChapterPositionMapper.mapSplitToOriginal(
      splitCFI,
      splitRef,
    );
  }

  /// Finds the split chapter reference for a given split CFI.
  ///
  /// Returns null if no matching split chapter is found.
  Future<EpubChapterSplitRef?> findSplitChapterForCFI(SplitCFI splitCFI) async {
    // Get the base spine index
    final spineIndex = extractSpineIndex(splitCFI.baseCFI);
    if (spineIndex == null) return null;

    // Find the original chapter using the spine map
    final spineMap = getSpineChapterMap();
    final originalChapter = spineMap[spineIndex];
    if (originalChapter == null) return null;

    // Look for split chapters based on this original chapter
    // Note: This would need to be implemented based on how split chapters
    // are tracked in the book reference
    return await _findSplitChapterRef(
      originalChapter,
      splitCFI.splitPart,
      splitCFI.totalParts,
    );
  }

  /// Navigates to a split CFI location.
  Future<CFILocation?> _navigateToSplitCFI(SplitCFI splitCFI) async {
    // Find the corresponding split chapter reference
    final splitRef = await findSplitChapterForCFI(splitCFI);
    if (splitRef == null) return null;

    // Convert split CFI to standard CFI for navigation
    final standardCFI = await SplitChapterPositionMapper.mapSplitToOriginal(
      splitCFI,
      splitRef,
    );

    // Navigate using the standard CFI
    final location = await super.navigateToCFI(standardCFI);
    if (location == null) return null;

    // Return enhanced location with split information
    return SplitCFILocation(
      chapterRef: location.chapterRef,
      spineIndex: location.spineIndex,
      position: location.position,
      document: location.document,
      splitRef: splitRef,
      splitCFI: splitCFI,
    );
  }

  /// Generates a split CFI for a split chapter reference.
  Future<SplitCFI?> _generateSplitCFI(
    EpubChapterSplitRef splitRef,
    String elementPath,
    int? characterOffset,
  ) async {
    // Generate standard CFI first
    final standardCFI = await super.generateCFI(
      chapterRef: splitRef.originalChapter,
      elementPath: elementPath,
      characterOffset: characterOffset,
    );

    if (standardCFI == null) return null;

    // Convert to split CFI
    return await SplitChapterPositionMapper.mapOriginalToSplit(
      standardCFI,
      splitRef,
    );
  }

  /// Validates a split CFI.
  Future<bool> _validateSplitCFI(SplitCFI splitCFI) async {
    try {
      // Check basic split CFI syntax
      if (!SplitCFIParser.isValidSplitCFI(splitCFI.raw)) {
        return false;
      }

      // Find the corresponding split chapter
      final splitRef = await findSplitChapterForCFI(splitCFI);
      if (splitRef == null) return false;

      // Validate with position mapper
      return await SplitChapterPositionMapper.validateSplitCFI(
        splitCFI,
        splitRef,
      );
    } catch (e) {
      return false;
    }
  }

  /// Finds a split chapter reference matching the criteria.
  ///
  /// This is a placeholder implementation. In practice, this would need
  /// to be integrated with how the book reference tracks split chapters.
  Future<EpubChapterSplitRef?> _findSplitChapterRef(
    EpubChapterRef originalChapter,
    int splitPart,
    int totalParts,
  ) async {
    // This would need to be implemented based on the specific way
    // split chapters are tracked and accessed in the system
    // For now, return null as this is a placeholder
    return null;
  }
}

/// Enhanced CFI location that includes split chapter information.
///
/// Extends the standard [CFILocation] to provide additional context
/// when navigating to positions within split chapters.
class SplitCFILocation extends CFILocation {
  /// The split chapter reference containing this location.
  final EpubChapterSplitRef splitRef;

  /// The split CFI that was used to navigate to this location.
  final SplitCFI splitCFI;

  SplitCFILocation({
    required super.chapterRef,
    required super.spineIndex,
    required super.position,
    required super.document,
    required this.splitRef,
    required this.splitCFI,
  });

  /// The part number within the split chapter (1-based).
  int get splitPart => splitRef.partNumber;

  /// The total number of parts in the split chapter.
  int get totalParts => splitRef.totalParts;

  /// The original chapter before splitting.
  EpubChapterRef get originalChapter => splitRef.originalChapter;

  /// Whether this location is in a split chapter part.
  bool get isInSplitChapter => true;

  @override
  String toString() {
    return 'SplitCFILocation('
        'chapter: ${chapterRef.title}, '
        'spine: $spineIndex, '
        'split: $splitPart/$totalParts, '
        'position: $position'
        ')';
  }
}
