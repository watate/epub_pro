import 'dart:async';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:image/image.dart';

import '../entities/epub_chapter.dart';
import '../entities/epub_schema.dart';
import '../readers/book_cover_reader.dart';
import '../readers/chapter_reader.dart';
import '../utils/chapter_splitter.dart';
import 'epub_chapter_ref.dart';
import 'epub_content_ref.dart';

/// Represents a reference to an EPUB book for lazy loading.
///
/// An [EpubBookRef] provides access to EPUB content without loading it all into
/// memory at once. Content is loaded on-demand when accessed, making it ideal
/// for large EPUB files or memory-constrained environments.
///
/// This is the result of calling [EpubReader.openBook] and provides the same
/// functionality as [EpubBook] but with lazy loading behavior.
///
/// ## Key Features
/// - Metadata available immediately (title, author, schema)
/// - Chapter structure available without loading content
/// - Content loaded only when explicitly requested
/// - Support for chapter splitting on-demand
///
/// ## Example
/// ```dart
/// final bytes = await File('large_book.epub').readAsBytes();
/// final bookRef = await EpubReader.openBook(bytes);
///
/// // Metadata available immediately
/// print('Title: ${bookRef.title}');
/// print('Author: ${bookRef.author}');
///
/// // Get chapter references (no content loaded yet)
/// final chapters = bookRef.getChapters();
/// print('Chapter count: ${chapters.length}');
///
/// // Load content for specific chapter only
/// final firstChapterContent = await chapters[0].readHtmlContent();
///
/// // Or get chapters with automatic splitting
/// final splitChapters = await bookRef.getChaptersWithSplitting();
/// ```
class EpubBookRef {
  final Archive epubArchive;
  final String? title;
  final String? author;
  final List<String> authors;
  final EpubSchema? schema;
  final EpubContentRef? content;

  const EpubBookRef({
    required this.epubArchive,
    this.title,
    this.author,
    this.authors = const [],
    this.schema,
    this.content,
  });

  @override
  int get hashCode {
    return title.hashCode ^
        author.hashCode ^
        authors.hashCode ^
        schema.hashCode ^
        content.hashCode;
  }

  @override
  bool operator ==(covariant EpubBookRef other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.title == title &&
        other.author == author &&
        listEquals(other.authors, authors) &&
        other.schema == schema &&
        other.content == content;
  }

  /// Gets the chapter structure without loading content.
  ///
  /// Returns a list of [EpubChapterRef] objects that represent the book's
  /// navigation structure. The actual HTML content is not loaded until you
  /// call [readHtmlContent] on a specific chapter reference.
  ///
  /// This method includes smart NCX/spine reconciliation to ensure all
  /// content files are accessible, even in malformed EPUBs.
  ///
  /// ## Example
  /// ```dart
  /// final chapters = bookRef.getChapters();
  /// for (final chapter in chapters) {
  ///   print(chapter.title ?? 'Untitled');
  ///   // Content not loaded yet
  /// }
  /// ```
  List<EpubChapterRef> getChapters() {
    return ChapterReader.getChapters(this);
  }

  /// Gets chapters and automatically splits any that exceed 5000 words.
  ///
  /// This method loads chapter content on-demand and splits long chapters
  /// into smaller parts of approximately 5000 words each.
  ///
  /// Returns a `Future<List<EpubChapter>>` instead of `List<EpubChapterRef>`
  /// because splitting requires reading the actual content.
  Future<List<EpubChapter>> getChaptersWithSplitting() async {
    final chapterRefs = getChapters();
    final result = <EpubChapter>[];

    for (final chapterRef in chapterRefs) {
      final splitChapters = await ChapterSplitter.splitChapterRef(chapterRef);
      result.addAll(splitChapters);
    }

    return result;
  }

  /// Reads the book's cover image.
  ///
  /// Attempts to extract the cover image from the EPUB manifest.
  /// If no cover is specified, falls back to the first image in the manifest.
  ///
  /// Returns null if no suitable cover image is found.
  ///
  /// ## Example
  /// ```dart
  /// final cover = await bookRef.readCover();
  /// if (cover != null) {
  ///   print('Cover dimensions: ${cover.width}x${cover.height}');
  /// }
  /// ```
  Future<Image?> readCover() async {
    return await BookCoverReader.readBookCover(this);
  }

  /// Gets chapter references with automatic splitting for long chapters.
  ///
  /// Unlike [getChaptersWithSplitting], this method returns references
  /// that load content on-demand, maintaining the lazy-loading behavior.
  ///
  /// Returns a list of [EpubChapterRef] where long chapters are replaced
  /// with multiple [EpubChapterSplitRef] instances.
  Future<List<EpubChapterRef>> getChapterRefsWithSplitting() async {
    final chapterRefs = getChapters();
    final result = <EpubChapterRef>[];

    for (final chapterRef in chapterRefs) {
      final splitRefs = await ChapterSplitter.createSplitRefs(chapterRef);
      result.addAll(splitRefs);
    }

    return result;
  }
}
