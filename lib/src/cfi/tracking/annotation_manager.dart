import '../core/cfi.dart';
import '../core/cfi_comparator.dart';
import '../core/cfi_range.dart';
import '../epub/epub_cfi_manager.dart';
import '../../ref_entities/epub_book_ref.dart';

/// Manages annotations (highlights, notes, bookmarks) using CFI for precise positioning.
///
/// The annotation manager provides functionality to create, store, retrieve,
/// and manage annotations within EPUB books using CFI for location references.
class CFIAnnotationManager {
  final String _bookId;
  final EpubCFIManager _cfiManager;
  final AnnotationStorage _storage;

  /// Creates an annotation manager for the given book.
  CFIAnnotationManager({
    required String bookId,
    required EpubBookRef bookRef,
    required AnnotationStorage storage,
  })  : _bookId = bookId,
        _cfiManager = EpubCFIManager(bookRef),
        _storage = storage;

  /// Creates a highlight annotation from a text selection.
  ///
  /// Records a highlighted text passage using range CFI for precise positioning.
  /// The highlight includes the selected text, CFI location, and optional styling.
  ///
  /// ```dart
  /// final manager = CFIAnnotationManager(
  ///   bookId: 'book123',
  ///   bookRef: bookRef,
  ///   storage: storage,
  /// );
  ///
  /// final highlight = await manager.createHighlight(
  ///   startCFI: CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   endCFI: CFI('epubcfi(/6/4!/4/10/2:15)'),
  ///   selectedText: 'highlighted text',
  ///   color: '#ffff00',
  /// );
  /// ```
  Future<HighlightAnnotation> createHighlight({
    required CFI startCFI,
    required CFI endCFI,
    required String selectedText,
    String? color,
    String? note,
    Map<String, dynamic>? metadata,
  }) async {
    // Create range CFI from start and end positions
    final rangeCFI = CFIRange.fromStartEnd(startCFI, endCFI);

    final highlight = HighlightAnnotation(
      id: _generateId(),
      bookId: _bookId,
      cfi: rangeCFI,
      selectedText: selectedText,
      color: color ?? '#ffff00', // Default yellow
      note: note,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      metadata: metadata ?? {},
    );

    await _storage.saveAnnotation(highlight);
    return highlight;
  }

  /// Creates a note annotation at a specific position.
  ///
  /// Records a text note attached to a specific location in the book.
  ///
  /// ```dart
  /// final note = await manager.createNote(
  ///   cfi: CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   text: 'This is an important point',
  ///   title: 'Key Insight',
  /// );
  /// ```
  Future<NoteAnnotation> createNote({
    required CFI cfi,
    required String text,
    String? title,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    final note = NoteAnnotation(
      id: _generateId(),
      bookId: _bookId,
      cfi: cfi,
      text: text,
      title: title,
      category: category,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      metadata: metadata ?? {},
    );

    await _storage.saveAnnotation(note);
    return note;
  }

  /// Creates a bookmark at a specific position.
  ///
  /// Records a bookmark for easy navigation back to a specific location.
  ///
  /// ```dart
  /// final bookmark = await manager.createBookmark(
  ///   cfi: CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   title: 'Chapter 3 start',
  ///   description: 'Important plot development',
  /// );
  /// ```
  Future<BookmarkAnnotation> createBookmark({
    required CFI cfi,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final bookmark = BookmarkAnnotation(
      id: _generateId(),
      bookId: _bookId,
      cfi: cfi,
      title: title ?? 'Bookmark',
      description: description,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      metadata: metadata ?? {},
    );

    await _storage.saveAnnotation(bookmark);
    return bookmark;
  }

  /// Gets all annotations for the book, sorted by reading order.
  ///
  /// Returns annotations ordered by their CFI positions in the book.
  ///
  /// ```dart
  /// final annotations = await manager.getAllAnnotations();
  /// for (final annotation in annotations) {
  ///   print('${annotation.type}: ${annotation.cfi}');
  /// }
  /// ```
  Future<List<Annotation>> getAllAnnotations() async {
    final annotations = await _storage.getAnnotations(_bookId);

    // Sort by CFI reading order
    annotations.sort((a, b) => a.cfi.compare(b.cfi));

    return annotations;
  }

  /// Gets annotations of a specific type.
  ///
  /// Filters annotations by type (highlight, note, bookmark).
  ///
  /// ```dart
  /// final highlights = await manager.getAnnotationsByType(AnnotationType.highlight);
  /// final bookmarks = await manager.getAnnotationsByType(AnnotationType.bookmark);
  /// ```
  Future<List<T>> getAnnotationsByType<T extends Annotation>(
      AnnotationType type) async {
    final allAnnotations = await getAllAnnotations();
    return allAnnotations
        .where((annotation) => annotation.type == type)
        .cast<T>()
        .toList();
  }

  /// Gets annotations within a CFI range.
  ///
  /// Returns all annotations that fall within the specified range.
  ///
  /// ```dart
  /// final startCFI = CFI('epubcfi(/6/4!/4/2/1:0)');
  /// final endCFI = CFI('epubcfi(/6/6!/4/2/1:0)');
  /// final annotations = await manager.getAnnotationsInRange(startCFI, endCFI);
  /// ```
  Future<List<Annotation>> getAnnotationsInRange(
      CFI startCFI, CFI endCFI) async {
    final allAnnotations = await getAllAnnotations();
    return CFIComparator.filterInRange(
      allAnnotations.map((a) => a.cfi).toList(),
      startCFI,
      endCFI,
    ).map((cfi) => allAnnotations.firstWhere((a) => a.cfi == cfi)).toList();
  }

  /// Gets annotations for a specific chapter.
  ///
  /// Returns annotations that belong to the specified spine index.
  ///
  /// ```dart
  /// final chapterAnnotations = await manager.getAnnotationsForChapter(2);
  /// ```
  Future<List<Annotation>> getAnnotationsForChapter(int spineIndex) async {
    final allAnnotations = await getAllAnnotations();
    return allAnnotations.where((annotation) {
      final annotationSpineIndex =
          _cfiManager.extractSpineIndex(annotation.cfi);
      return annotationSpineIndex == spineIndex;
    }).toList();
  }

  /// Updates an existing annotation.
  ///
  /// Modifies an annotation's content while preserving its ID and creation time.
  ///
  /// ```dart
  /// final updatedHighlight = highlight.copyWith(
  ///   note: 'Added this note later',
  ///   color: '#ff0000', // Changed to red
  /// );
  /// await manager.updateAnnotation(updatedHighlight);
  /// ```
  Future<void> updateAnnotation(Annotation annotation) async {
    final updatedAnnotation = annotation.copyWith(modifiedAt: DateTime.now());
    await _storage.saveAnnotation(updatedAnnotation);
  }

  /// Deletes an annotation.
  ///
  /// Removes the annotation from storage permanently.
  ///
  /// ```dart
  /// await manager.deleteAnnotation(annotation.id);
  /// ```
  Future<void> deleteAnnotation(String annotationId) async {
    await _storage.deleteAnnotation(annotationId);
  }

  /// Finds annotations near a specific CFI position.
  ///
  /// Returns annotations within a certain distance of the target position.
  /// Useful for showing contextual annotations.
  ///
  /// ```dart
  /// final nearbyAnnotations = await manager.findNearbyAnnotations(
  ///   targetCFI,
  ///   maxDistance: 1000, // characters
  /// );
  /// ```
  Future<List<Annotation>> findNearbyAnnotations(
    CFI targetCFI, {
    double maxDistance = 1000.0,
  }) async {
    final allAnnotations = await getAllAnnotations();
    final nearbyAnnotations = <Annotation>[];

    for (final annotation in allAnnotations) {
      final distance =
          CFIComparator.calculateDistance(targetCFI, annotation.cfi);
      if (distance <= maxDistance) {
        nearbyAnnotations.add(annotation);
      }
    }

    // Sort by distance
    nearbyAnnotations.sort((a, b) {
      final distanceA = CFIComparator.calculateDistance(targetCFI, a.cfi);
      final distanceB = CFIComparator.calculateDistance(targetCFI, b.cfi);
      return distanceA.compareTo(distanceB);
    });

    return nearbyAnnotations;
  }

  /// Exports all annotations to a portable format.
  ///
  /// Creates a data structure that can be serialized and imported elsewhere.
  ///
  /// ```dart
  /// final exportData = await manager.exportAnnotations();
  /// await saveToFile(exportData.toJson());
  /// ```
  Future<AnnotationExport> exportAnnotations() async {
    final annotations = await getAllAnnotations();
    return AnnotationExport(
      bookId: _bookId,
      annotations: annotations,
      exportTimestamp: DateTime.now(),
      version: '1.0',
    );
  }

  /// Imports annotations from exported data.
  ///
  /// Merges imported annotations with existing ones, avoiding duplicates.
  ///
  /// ```dart
  /// final importData = AnnotationExport.fromJson(jsonData);
  /// await manager.importAnnotations(importData, mergeStrategy: MergeStrategy.skipExisting);
  /// ```
  Future<void> importAnnotations(
    AnnotationExport exportData, {
    MergeStrategy mergeStrategy = MergeStrategy.skipExisting,
  }) async {
    final existingAnnotations = await getAllAnnotations();
    final existingIds = existingAnnotations.map((a) => a.id).toSet();

    for (final annotation in exportData.annotations) {
      final shouldImport = switch (mergeStrategy) {
        MergeStrategy.skipExisting => !existingIds.contains(annotation.id),
        MergeStrategy.overwriteExisting => true,
        MergeStrategy.renameConflicts => !existingIds.contains(annotation.id) ||
            annotation.copyWith(id: _generateId()) != annotation,
      };

      if (shouldImport) {
        var importAnnotation = annotation;
        if (mergeStrategy == MergeStrategy.renameConflicts &&
            existingIds.contains(annotation.id)) {
          importAnnotation = annotation.copyWith(id: _generateId());
        }
        await _storage.saveAnnotation(importAnnotation);
      }
    }
  }

  /// Searches annotations by text content.
  ///
  /// Finds annotations containing the search query in their text content.
  ///
  /// ```dart
  /// final results = await manager.searchAnnotations('important concept');
  /// ```
  Future<List<Annotation>> searchAnnotations(String query) async {
    final allAnnotations = await getAllAnnotations();
    final lowercaseQuery = query.toLowerCase();

    return allAnnotations.where((annotation) {
      final searchFields = [
        annotation.getSearchableText(),
        ...annotation.metadata.values.map((v) => v.toString()),
      ];

      return searchFields
          .any((field) => field.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Gets annotation statistics for the book.
  ///
  /// Returns counts and metrics about annotations in the book.
  ///
  /// ```dart
  /// final stats = await manager.getAnnotationStatistics();
  /// print('Total annotations: ${stats.totalCount}');
  /// print('Highlights: ${stats.highlightCount}');
  /// ```
  Future<AnnotationStatistics> getAnnotationStatistics() async {
    final annotations = await getAllAnnotations();

    int highlightCount = 0;
    int noteCount = 0;
    int bookmarkCount = 0;

    for (final annotation in annotations) {
      switch (annotation.type) {
        case AnnotationType.highlight:
          highlightCount++;
          break;
        case AnnotationType.note:
          noteCount++;
          break;
        case AnnotationType.bookmark:
          bookmarkCount++;
          break;
      }
    }

    return AnnotationStatistics(
      bookId: _bookId,
      totalCount: annotations.length,
      highlightCount: highlightCount,
      noteCount: noteCount,
      bookmarkCount: bookmarkCount,
      firstCreated: annotations.isNotEmpty
          ? annotations
              .map((a) => a.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      lastModified: annotations.isNotEmpty
          ? annotations
              .map((a) => a.modifiedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    );
  }

  /// Generates a unique ID for annotations.
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_bookId.hashCode}';
  }
}

/// Base class for all annotation types.
abstract class Annotation {
  final String id;
  final String bookId;
  final CFI cfi;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final Map<String, dynamic> metadata;

  const Annotation({
    required this.id,
    required this.bookId,
    required this.cfi,
    required this.createdAt,
    required this.modifiedAt,
    required this.metadata,
  });

  /// The type of this annotation.
  AnnotationType get type;

  /// Gets text content for searching.
  String getSearchableText();

  /// Creates a copy with updated fields.
  Annotation copyWith({
    String? id,
    String? bookId,
    CFI? cfi,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? metadata,
  });

  /// Converts to JSON for serialization.
  Map<String, dynamic> toJson();

  /// Creates from JSON (factory method to be implemented by subclasses).
  static Annotation fromJson(Map<String, dynamic> json) {
    final type = AnnotationType.values.firstWhere(
      (t) => t.name == json['type'],
    );

    return switch (type) {
      AnnotationType.highlight => HighlightAnnotation.fromJson(json),
      AnnotationType.note => NoteAnnotation.fromJson(json),
      AnnotationType.bookmark => BookmarkAnnotation.fromJson(json),
    };
  }
}

/// Represents a highlight annotation.
class HighlightAnnotation extends Annotation {
  final String selectedText;
  final String color;
  final String? note;

  const HighlightAnnotation({
    required super.id,
    required super.bookId,
    required super.cfi,
    required this.selectedText,
    required this.color,
    this.note,
    required super.createdAt,
    required super.modifiedAt,
    required super.metadata,
  });

  @override
  AnnotationType get type => AnnotationType.highlight;

  @override
  String getSearchableText() => '$selectedText ${note ?? ''}';

  @override
  HighlightAnnotation copyWith({
    String? id,
    String? bookId,
    CFI? cfi,
    String? selectedText,
    String? color,
    String? note,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? metadata,
  }) {
    return HighlightAnnotation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      cfi: cfi ?? this.cfi,
      selectedText: selectedText ?? this.selectedText,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'id': id,
      'bookId': bookId,
      'cfi': cfi.toString(),
      'selectedText': selectedText,
      'color': color,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory HighlightAnnotation.fromJson(Map<String, dynamic> json) {
    return HighlightAnnotation(
      id: json['id'],
      bookId: json['bookId'],
      cfi: CFI(json['cfi']),
      selectedText: json['selectedText'],
      color: json['color'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// Represents a note annotation.
class NoteAnnotation extends Annotation {
  final String text;
  final String? title;
  final String? category;

  const NoteAnnotation({
    required super.id,
    required super.bookId,
    required super.cfi,
    required this.text,
    this.title,
    this.category,
    required super.createdAt,
    required super.modifiedAt,
    required super.metadata,
  });

  @override
  AnnotationType get type => AnnotationType.note;

  @override
  String getSearchableText() => '${title ?? ''} $text ${category ?? ''}';

  @override
  NoteAnnotation copyWith({
    String? id,
    String? bookId,
    CFI? cfi,
    String? text,
    String? title,
    String? category,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? metadata,
  }) {
    return NoteAnnotation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      cfi: cfi ?? this.cfi,
      text: text ?? this.text,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'id': id,
      'bookId': bookId,
      'cfi': cfi.toString(),
      'text': text,
      'title': title,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory NoteAnnotation.fromJson(Map<String, dynamic> json) {
    return NoteAnnotation(
      id: json['id'],
      bookId: json['bookId'],
      cfi: CFI(json['cfi']),
      text: json['text'],
      title: json['title'],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// Represents a bookmark annotation.
class BookmarkAnnotation extends Annotation {
  final String title;
  final String? description;

  const BookmarkAnnotation({
    required super.id,
    required super.bookId,
    required super.cfi,
    required this.title,
    this.description,
    required super.createdAt,
    required super.modifiedAt,
    required super.metadata,
  });

  @override
  AnnotationType get type => AnnotationType.bookmark;

  @override
  String getSearchableText() => '$title ${description ?? ''}';

  @override
  BookmarkAnnotation copyWith({
    String? id,
    String? bookId,
    CFI? cfi,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? metadata,
  }) {
    return BookmarkAnnotation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      cfi: cfi ?? this.cfi,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'id': id,
      'bookId': bookId,
      'cfi': cfi.toString(),
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory BookmarkAnnotation.fromJson(Map<String, dynamic> json) {
    return BookmarkAnnotation(
      id: json['id'],
      bookId: json['bookId'],
      cfi: CFI(json['cfi']),
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// Types of annotations.
enum AnnotationType {
  highlight,
  note,
  bookmark,
}

/// Statistics about annotations in a book.
class AnnotationStatistics {
  final String bookId;
  final int totalCount;
  final int highlightCount;
  final int noteCount;
  final int bookmarkCount;
  final DateTime? firstCreated;
  final DateTime? lastModified;

  const AnnotationStatistics({
    required this.bookId,
    required this.totalCount,
    required this.highlightCount,
    required this.noteCount,
    required this.bookmarkCount,
    this.firstCreated,
    this.lastModified,
  });
}

/// Export data structure for annotations.
class AnnotationExport {
  final String bookId;
  final List<Annotation> annotations;
  final DateTime exportTimestamp;
  final String version;

  const AnnotationExport({
    required this.bookId,
    required this.annotations,
    required this.exportTimestamp,
    required this.version,
  });

  /// Converts to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'annotations': annotations.map((a) => a.toJson()).toList(),
      'exportTimestamp': exportTimestamp.toIso8601String(),
      'version': version,
    };
  }

  /// Creates from JSON.
  factory AnnotationExport.fromJson(Map<String, dynamic> json) {
    return AnnotationExport(
      bookId: json['bookId'],
      annotations: (json['annotations'] as List)
          .map((a) => Annotation.fromJson(a))
          .toList(),
      exportTimestamp: DateTime.parse(json['exportTimestamp']),
      version: json['version'],
    );
  }
}

/// Strategies for merging imported annotations.
enum MergeStrategy {
  skipExisting, // Skip annotations with existing IDs
  overwriteExisting, // Overwrite annotations with existing IDs
  renameConflicts, // Rename conflicting annotations with new IDs
}

/// Abstract interface for annotation storage implementations.
abstract class AnnotationStorage {
  /// Saves an annotation.
  Future<void> saveAnnotation(Annotation annotation);

  /// Gets all annotations for a book.
  Future<List<Annotation>> getAnnotations(String bookId);

  /// Gets a specific annotation by ID.
  Future<Annotation?> getAnnotation(String annotationId);

  /// Deletes an annotation.
  Future<void> deleteAnnotation(String annotationId);

  /// Deletes all annotations for a book.
  Future<void> deleteBookAnnotations(String bookId);
}
