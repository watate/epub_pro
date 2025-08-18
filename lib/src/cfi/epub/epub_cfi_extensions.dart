import '../../ref_entities/epub_book_ref.dart';
import '../../ref_entities/epub_chapter_ref.dart';
import '../core/cfi.dart';
import '../dom/dom_abstraction.dart';
import 'epub_cfi_manager.dart';

/// CFI extensions for EpubBookRef to add navigation and CFI generation capabilities.
extension EpubBookRefCFI on EpubBookRef {
  /// Creates a CFI manager for this book.
  /// 
  /// The CFI manager provides methods to navigate to CFI locations
  /// and generate CFIs from positions within the book.
  /// 
  /// ```dart
  /// final bookRef = await EpubReader.openBook(bytes);
  /// final cfiManager = bookRef.cfiManager;
  /// 
  /// // Navigate to a CFI
  /// final location = await cfiManager.navigateToCFI(cfi);
  /// ```
  EpubCFIManager get cfiManager => EpubCFIManager(this);

  /// Navigates to a CFI location within the book.
  /// 
  /// Returns the CFI location containing the chapter reference and
  /// precise DOM position, or null if the CFI cannot be resolved.
  /// 
  /// ```dart
  /// final location = await bookRef.navigateToCFI(
  ///   CFI('epubcfi(/6/4!/4/10/2:5)')
  /// );
  /// 
  /// if (location != null) {
  ///   print('Found in chapter: ${location.chapterRef.title}');
  ///   final content = await location.getTextContent();
  /// }
  /// ```
  Future<CFILocation?> navigateToCFI(CFI cfi) async {
    return await cfiManager.navigateToCFI(cfi);
  }

  /// Creates a simple CFI for reading progress tracking.
  /// 
  /// Generates a CFI that represents a position within a specific
  /// spine item, optionally with a fractional position within that item.
  /// 
  /// ```dart
  /// // CFI pointing to the beginning of spine item 2
  /// final cfi = bookRef.createProgressCFI(2);
  /// 
  /// // CFI pointing to 30% through spine item 2
  /// final cfi = bookRef.createProgressCFI(2, fraction: 0.3);
  /// ```
  CFI createProgressCFI(int spineIndex, {double fraction = 0.0}) {
    return cfiManager.createProgressCFI(spineIndex, fraction: fraction);
  }

  /// Validates that a CFI can be resolved within this book.
  /// 
  /// Checks if the CFI points to a valid location without actually
  /// navigating to it. Useful for validation before attempting navigation.
  /// 
  /// ```dart
  /// final isValid = await bookRef.validateCFI(cfi);
  /// if (isValid) {
  ///   final location = await bookRef.navigateToCFI(cfi);
  /// }
  /// ```
  Future<bool> validateCFI(CFI cfi) async {
    return await cfiManager.validateCFI(cfi);
  }

  /// Gets a map of spine indices to chapter references.
  /// 
  /// Useful for understanding the relationship between CFI spine
  /// positions and actual chapter content.
  /// 
  /// ```dart
  /// final spineMap = bookRef.getSpineChapterMap();
  /// for (final entry in spineMap.entries) {
  ///   print('Spine ${entry.key}: ${entry.value.title}');
  /// }
  /// ```
  Map<int, EpubChapterRef> getSpineChapterMap() {
    return cfiManager.getSpineChapterMap();
  }

  /// Gets the total number of spine items in the book.
  /// 
  /// Useful for calculating overall reading progress percentages
  /// when combined with CFI spine positions.
  int get spineItemCount => cfiManager.spineItemCount;

  /// Finds chapters that contain CFIs within a specific range.
  /// 
  /// Returns chapter references for all chapters that contain
  /// content between the start and end CFIs.
  /// 
  /// ```dart
  /// final startCFI = CFI('epubcfi(/6/4!/4/2/1:0)');
  /// final endCFI = CFI('epubcfi(/6/8!/4/2/1:0)');
  /// final chapters = bookRef.getChaptersInCFIRange(startCFI, endCFI);
  /// ```
  Future<List<EpubChapterRef>> getChaptersInCFIRange(CFI startCFI, CFI endCFI) async {
    final startSpine = cfiManager.extractSpineIndex(startCFI);
    final endSpine = cfiManager.extractSpineIndex(endCFI);
    
    if (startSpine == null || endSpine == null) return [];
    
    final spineMap = getSpineChapterMap();
    final chapters = <EpubChapterRef>[];
    
    for (int i = startSpine; i <= endSpine; i++) {
      final chapter = spineMap[i];
      if (chapter != null) {
        chapters.add(chapter);
      }
    }
    
    return chapters;
  }
}

/// CFI extensions for EpubChapterRef to add CFI generation and navigation.
extension EpubChapterRefCFI on EpubChapterRef {
  /// Generates a CFI pointing to a specific position within this chapter.
  /// 
  /// Creates a CFI based on an element path and optional character offset.
  /// The element path should follow CFI indexing rules.
  /// 
  /// ```dart
  /// final cfi = await chapterRef.generateCFI(
  ///   elementPath: '/4/10/2',
  ///   characterOffset: 15,
  ///   bookRef: bookRef,
  /// );
  /// ```
  Future<CFI?> generateCFI({
    required String elementPath,
    int? characterOffset,
    required EpubBookRef bookRef,
  }) async {
    final manager = EpubCFIManager(bookRef);
    return await manager.generateCFI(
      chapterRef: this,
      elementPath: elementPath,
      characterOffset: characterOffset,
    );
  }

  /// Generates a CFI from a DOM position within this chapter.
  /// 
  /// Creates a CFI by analyzing the DOM position relative to this chapter's
  /// content. Requires the book reference to determine spine position.
  /// 
  /// ```dart
  /// final htmlContent = await chapterRef.readHtmlContent();
  /// final document = DOMDocument.parseHTML(htmlContent);
  /// final position = DOMPosition(container: textNode, offset: 10);
  /// 
  /// final cfi = await chapterRef.generateCFIFromPosition(
  ///   position: position,
  ///   bookRef: bookRef,
  /// );
  /// ```
  Future<CFI?> generateCFIFromPosition({
    required DOMPosition position,
    required EpubBookRef bookRef,
  }) async {
    final manager = EpubCFIManager(bookRef);
    return await manager.generateCFIFromPosition(
      chapterRef: this,
      position: position,
    );
  }

  /// Generates a range CFI between two positions within this chapter.
  /// 
  /// Creates a CFI representing a text selection or range between
  /// the start and end positions.
  /// 
  /// ```dart
  /// final startPos = DOMPosition(container: textNode, offset: 5);
  /// final endPos = DOMPosition(container: textNode, offset: 15);
  /// 
  /// final rangeCFI = await chapterRef.generateRangeCFI(
  ///   startPosition: startPos,
  ///   endPosition: endPos,
  ///   bookRef: bookRef,
  /// );
  /// ```
  Future<CFI?> generateRangeCFI({
    required DOMPosition startPosition,
    required DOMPosition endPosition,
    required EpubBookRef bookRef,
  }) async {
    final manager = EpubCFIManager(bookRef);
    return await manager.generateRangeCFI(
      chapterRef: this,
      startPosition: startPosition,
      endPosition: endPosition,
    );
  }

  /// Parses this chapter's HTML content into a DOM document.
  /// 
  /// Convenience method for creating a DOM representation of the
  /// chapter's HTML content for CFI operations.
  /// 
  /// ```dart
  /// final document = await chapterRef.parseAsDOM();
  /// final element = document.getElementById('section1');
  /// ```
  Future<DOMDocument> parseAsDOM() async {
    final htmlContent = await readHtmlContent();
    return DOMDocument.parseHTML(htmlContent);
  }

  /// Finds text content at a specific CFI within this chapter.
  /// 
  /// Resolves a CFI to its text content within this chapter's DOM.
  /// The CFI should point to a location within this specific chapter.
  /// 
  /// ```dart
  /// final text = await chapterRef.getTextAtCFI(
  ///   cfi,
  ///   bookRef: bookRef,
  /// );
  /// print('Text at CFI: $text');
  /// ```
  Future<String?> getTextAtCFI(CFI cfi, {required EpubBookRef bookRef}) async {
    final manager = EpubCFIManager(bookRef);
    final location = await manager.navigateToCFI(cfi);
    
    if (location?.chapterRef == this) {
      return await location!.getTextContent();
    }
    
    return null;
  }

  /// Creates a simple CFI pointing to the beginning of this chapter.
  /// 
  /// Generates a basic CFI that references the start of this chapter
  /// based on its position in the book's spine.
  /// 
  /// ```dart
  /// final chapterStartCFI = await chapterRef.getStartCFI(bookRef);
  /// ```
  Future<CFI?> getStartCFI(EpubBookRef bookRef) async {
    final manager = EpubCFIManager(bookRef);
    final spineIndex = manager.getSpineIndexForChapter(this);
    
    if (spineIndex != null) {
      return manager.createProgressCFI(spineIndex);
    }
    
    return null;
  }

  /// Validates that this chapter can resolve a given CFI.
  /// 
  /// Checks if the CFI points to a valid location within this chapter
  /// without loading the full DOM structure.
  /// 
  /// ```dart
  /// final canResolve = await chapterRef.canResolveCFI(cfi, bookRef: bookRef);
  /// ```
  Future<bool> canResolveCFI(CFI cfi, {required EpubBookRef bookRef}) async {
    final manager = EpubCFIManager(bookRef);
    final location = await manager.navigateToCFI(cfi);
    return location?.chapterRef == this;
  }
}