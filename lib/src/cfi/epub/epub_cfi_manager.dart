import '../../ref_entities/epub_book_ref.dart';
import '../../ref_entities/epub_chapter_ref.dart';
import '../core/cfi.dart';
import '../core/cfi_structure.dart';
import '../dom/dom_abstraction.dart';
import '../dom/html_navigator.dart';

/// Manager for EPUB-specific CFI operations.
///
/// Integrates CFI functionality with the existing EPUB library structure,
/// providing methods to navigate to CFI locations within EPUB books and
/// generate CFIs from EPUB positions.
class EpubCFIManager {
  final EpubBookRef _bookRef;

  /// Creates a CFI manager for the given EPUB book reference.
  EpubCFIManager(this._bookRef);

  /// Navigates to a CFI location within the EPUB.
  ///
  /// Returns the chapter reference and DOM position where the CFI points,
  /// or null if the CFI cannot be resolved.
  ///
  /// ```dart
  /// final manager = EpubCFIManager(bookRef);
  /// final location = await manager.navigateToCFI(
  ///   CFI('epubcfi(/6/4!/4/10/2:5)')
  /// );
  ///
  /// if (location != null) {
  ///   final content = await location.chapterRef.readHtmlContent();
  ///   // Use location.position for precise positioning
  /// }
  /// ```
  Future<CFILocation?> navigateToCFI(CFI cfi) async {
    final spineIndex = extractSpineIndex(cfi);
    if (spineIndex == null) return null;

    final chapterRef = _getChapterBySpineIndex(spineIndex);
    if (chapterRef == null) return null;

    // Get the path after spine position
    final documentPath = _extractDocumentPath(cfi);
    if (documentPath == null) return null;

    // Load HTML content and create DOM
    final htmlContent = await chapterRef.readHtmlContent();
    final document = DOMDocument.parseHTML(htmlContent);

    // Navigate to position within the document
    final position = HTMLNavigator.navigateToPosition(document, documentPath);
    if (position == null) return null;

    return CFILocation(
      chapterRef: chapterRef,
      spineIndex: spineIndex,
      position: position,
      document: document,
    );
  }

  /// Generates a CFI from an EPUB position.
  ///
  /// Creates a CFI that references the specified position within the given
  /// chapter at the character offset.
  ///
  /// ```dart
  /// final cfi = await manager.generateCFI(
  ///   chapterRef: chapters[0],
  ///   elementPath: '/4/10/2',
  ///   characterOffset: 15,
  /// );
  /// print(cfi.toString()); // epubcfi(/6/4!/4/10/2:15)
  /// ```
  Future<CFI?> generateCFI({
    required EpubChapterRef chapterRef,
    required String elementPath,
    int? characterOffset,
  }) async {
    final spineIndex = getSpineIndexForChapter(chapterRef);
    if (spineIndex == null) return null;

    // Build spine part (convert 0-based index to CFI format)
    final spinePart = CFIPart(index: (spineIndex + 1) * 2);

    // Parse element path
    final pathParts = _parseElementPath(elementPath, characterOffset);

    // Create complete CFI structure
    final structure = CFIStructure(
      start: CFIPath(parts: [spinePart, ...pathParts]),
    );

    return CFI.fromStructure(structure);
  }

  /// Generates a CFI from a DOM position within a chapter.
  ///
  /// Creates a CFI by analyzing the DOM position and building the
  /// appropriate spine and document paths.
  Future<CFI?> generateCFIFromPosition({
    required EpubChapterRef chapterRef,
    required DOMPosition position,
  }) async {
    final spineIndex = getSpineIndexForChapter(chapterRef);
    if (spineIndex == null) return null;

    // Build spine part
    final spinePart = CFIPart(index: (spineIndex + 1) * 2);

    // Get document path from position
    final documentPath = HTMLNavigator.createPathFromPosition(position);

    // Add step indirection marker
    final indirectionPart = CFIPart(
      index: documentPath.parts.first.index,
      id: documentPath.parts.first.id,
      hasIndirection: true,
    );

    // Combine spine + indirection + document path
    final allParts = [
      spinePart,
      indirectionPart,
      ...documentPath.parts
          .skip(1), // Skip first part as it's now the indirection
    ];

    final structure = CFIStructure(
      start: CFIPath(parts: allParts),
    );

    return CFI.fromStructure(structure);
  }

  /// Generates a range CFI from two positions within the same chapter.
  ///
  /// Creates a range CFI spanning from the start position to the end position.
  Future<CFI?> generateRangeCFI({
    required EpubChapterRef chapterRef,
    required DOMPosition startPosition,
    required DOMPosition endPosition,
  }) async {
    final spineIndex = getSpineIndexForChapter(chapterRef);
    if (spineIndex == null) return null;

    // Create a range between the positions
    final range = DOMRange(
      startContainer: startPosition.container,
      startOffset: startPosition.offset,
      endContainer: endPosition.container,
      endOffset: endPosition.offset,
    );

    // Build CFI structure from range
    final rangeStructure = HTMLNavigator.createStructureFromRange(range);

    // Add spine information to parent path
    final spinePart = CFIPart(index: (spineIndex + 1) * 2);
    final parentParts = rangeStructure.parent?.parts ?? [];
    final fullParentParts = [spinePart, ...parentParts];

    final structure = CFIStructure(
      parent: CFIPath(parts: fullParentParts),
      start: rangeStructure.start,
      end: rangeStructure.end,
    );

    return CFI.fromStructure(structure);
  }

  /// Validates that a CFI can be resolved within the EPUB.
  ///
  /// Checks that the CFI points to a valid location without actually
  /// navigating to it (more efficient for validation).
  Future<bool> validateCFI(CFI cfi) async {
    final spineIndex = extractSpineIndex(cfi);
    if (spineIndex == null) return false;

    final chapterRef = _getChapterBySpineIndex(spineIndex);
    if (chapterRef == null) return false;

    final documentPath = _extractDocumentPath(cfi);
    if (documentPath == null) return false;

    // For basic validation, we could just check if the chapter exists
    // For thorough validation, we'd need to load and parse the HTML
    return true;
  }

  /// Gets all chapters that contain content referenced by CFIs.
  ///
  /// Returns a map of spine indices to chapter references for all
  /// chapters that have content files in the spine.
  Map<int, EpubChapterRef> getSpineChapterMap() {
    final map = <int, EpubChapterRef>{};
    final chapters = _bookRef.getChapters();

    for (final chapter in chapters) {
      final spineIndex = getSpineIndexForChapter(chapter);
      if (spineIndex != null) {
        map[spineIndex] = chapter;
      }
    }

    return map;
  }

  /// Gets the total number of spine items in the EPUB.
  int get spineItemCount {
    return _bookRef.schema?.package?.spine?.items.length ?? 0;
  }

  /// Creates a simple position CFI for reading progress tracking.
  ///
  /// Generates a CFI that represents a rough position within a chapter,
  /// useful for bookmarks and reading progress without requiring precise
  /// DOM analysis.
  CFI createProgressCFI(int spineIndex, {double fraction = 0.0}) {
    final spinePart = CFIPart(index: (spineIndex + 1) * 2);

    if (fraction > 0.0) {
      // Create an approximate position based on the fraction
      final estimatedStep = (fraction * 100).round() * 2;
      final progressPart = CFIPart(index: estimatedStep, hasIndirection: true);

      return CFI.fromStructure(
        CFIStructure(
          start: CFIPath(parts: [spinePart, progressPart]),
        ),
      );
    }

    return CFI.fromStructure(
      CFIStructure(
        start: CFIPath(parts: [spinePart]),
      ),
    );
  }

  /// Extracts the spine index from a CFI.
  int? extractSpineIndex(CFI cfi) {
    final structure = cfi.structure;
    final firstPart =
        structure.parent?.parts.first ?? structure.start.parts.first;

    // CFI spine indices are 1-based even numbers (2, 4, 6, ...)
    // Convert to 0-based: (index / 2) - 1
    if (firstPart.index >= 2 && firstPart.index.isEven) {
      return (firstPart.index ~/ 2) - 1;
    }

    return null;
  }

  /// Extracts the document path (after step indirection) from a CFI.
  CFIPath? _extractDocumentPath(CFI cfi) {
    final structure = cfi.structure;

    // For range CFIs, use the start path
    final pathParts = structure.parent?.parts ?? structure.start.parts;

    // Find step indirection marker
    int indirectionIndex = -1;
    for (int i = 0; i < pathParts.length; i++) {
      if (pathParts[i].hasIndirection) {
        indirectionIndex = i;
        break;
      }
    }

    if (indirectionIndex >= 0) {
      // Return parts after indirection
      final documentParts = pathParts.skip(indirectionIndex).toList();
      return CFIPath(parts: documentParts);
    }

    // If no indirection found, assume simple spine reference
    if (pathParts.length > 1) {
      return CFIPath(parts: pathParts.skip(1).toList());
    }

    return null;
  }

  /// Gets a chapter reference by spine index.
  EpubChapterRef? _getChapterBySpineIndex(int spineIndex) {
    final spineItems = _bookRef.schema?.package?.spine?.items;
    if (spineItems == null || spineIndex >= spineItems.length) {
      return null;
    }

    final spineItem = spineItems[spineIndex];
    final manifest = _bookRef.schema?.package?.manifest?.items;

    // Find manifest item by ID
    final manifestItem = manifest?.firstWhere(
      (item) => item.id == spineItem.idRef,
      orElse: () => throw StateError('Manifest item not found'),
    );

    if (manifestItem?.href == null) return null;

    // Find chapter with matching content file
    final chapters = _bookRef.getChapters();
    return chapters.firstWhere(
      (chapter) => chapter.contentFileName == manifestItem!.href,
      orElse: () => throw StateError('Chapter not found'),
    );
  }

  /// Gets the spine index for a chapter reference.
  int? getSpineIndexForChapter(EpubChapterRef chapterRef) {
    final spineItems = _bookRef.schema?.package?.spine?.items;
    final manifest = _bookRef.schema?.package?.manifest?.items;

    if (spineItems == null || manifest == null) return null;

    // Find manifest item for this chapter
    final manifestItem = manifest.firstWhere(
      (item) => item.href == chapterRef.contentFileName,
      orElse: () => throw StateError('Manifest item not found'),
    );

    // Find spine index for this manifest item
    for (int i = 0; i < spineItems.length; i++) {
      if (spineItems[i].idRef == manifestItem.id) {
        return i;
      }
    }

    return null;
  }

  /// Parses an element path string into CFI parts.
  List<CFIPart> _parseElementPath(String elementPath, int? characterOffset) {
    final parts = <CFIPart>[];
    final segments = elementPath.split('/').where((s) => s.isNotEmpty);

    for (int i = 0; i < segments.length; i++) {
      final segment = segments.elementAt(i);
      final index = int.tryParse(segment);

      if (index != null) {
        final isLast = i == segments.length - 1;
        parts.add(CFIPart(
          index: index,
          offset: isLast ? characterOffset : null,
          hasIndirection: i == 0, // First part after spine has indirection
        ));
      }
    }

    return parts;
  }
}

/// Represents a resolved CFI location within an EPUB.
class CFILocation {
  /// The chapter reference containing the CFI location.
  final EpubChapterRef chapterRef;

  /// The spine index of the chapter.
  final int spineIndex;

  /// The precise DOM position within the chapter.
  final DOMPosition position;

  /// The parsed DOM document of the chapter.
  final DOMDocument document;

  const CFILocation({
    required this.chapterRef,
    required this.spineIndex,
    required this.position,
    required this.document,
  });

  /// Gets the text content at this location.
  Future<String> getTextContent() async {
    if (position.container.nodeType == DOMNodeType.text) {
      final text = position.container.nodeValue ?? '';
      return text.substring(position.offset.clamp(0, text.length));
    }

    return position.container.textContent;
  }

  /// Gets surrounding context around this location.
  Future<String> getContext({int beforeChars = 50, int afterChars = 50}) async {
    // This would extract text context around the position
    // Implementation would depend on the specific requirements
    return position.container.textContent;
  }

  @override
  String toString() {
    return 'CFILocation(chapter: ${chapterRef.title}, spine: $spineIndex, position: $position)';
  }
}
