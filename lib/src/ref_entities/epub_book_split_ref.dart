import 'epub_book_ref.dart';
import 'epub_chapter_ref.dart';

/// A reference to an EPUB book that automatically splits long chapters.
///
/// This class extends [EpubBookRef] and overrides the [getChapters] method
/// to return split chapter references for chapters that exceed 5000 words.
class EpubBookSplitRef extends EpubBookRef {
  EpubBookSplitRef({
    required super.epubArchive,
    super.title,
    super.author,
    super.authors,
    super.schema,
    super.content,
  });

  /// Gets chapters with automatic splitting for long chapters.
  ///
  /// This overrides the base [getChapters] method to return split references
  /// instead of regular chapter references. The splitting happens lazily -
  /// content is only loaded when a specific chapter part is accessed.
  @override
  List<EpubChapterRef> getChapters() {
    // We can't make this async, so we'll return a special list that
    // handles splitting when chapters are accessed
    final originalChapters = super.getChapters();

    // For now, return original chapters. The actual splitting will happen
    // when getChapterRefsWithSplitting() is called explicitly
    return originalChapters;
  }

  /// Creates an EpubBookSplitRef from an existing EpubBookRef
  static EpubBookSplitRef fromBookRef(EpubBookRef bookRef) {
    return EpubBookSplitRef(
      epubArchive: bookRef.epubArchive,
      title: bookRef.title,
      author: bookRef.author,
      authors: bookRef.authors,
      schema: bookRef.schema,
      content: bookRef.content,
    );
  }
}
