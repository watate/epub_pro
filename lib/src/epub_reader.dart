import 'dart:async';

import 'package:archive/archive.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_chapter.dart';
import 'entities/epub_content.dart';
import 'entities/epub_content_file.dart';
import 'entities/epub_text_content_file.dart';
import 'readers/content_reader.dart';
import 'readers/schema_reader.dart';
import 'ref_entities/epub_book_ref.dart';
import 'ref_entities/epub_book_split_ref.dart';
import 'ref_entities/epub_byte_content_file_ref.dart';
import 'ref_entities/epub_chapter_ref.dart';
import 'ref_entities/epub_content_file_ref.dart';
import 'ref_entities/epub_content_ref.dart';
import 'ref_entities/epub_text_content_file_ref.dart';
import 'schema/opf/epub_metadata_creator.dart';
import 'utils/chapter_splitter.dart';

/// A class that provides the primary interface to read EPUB files.
///
/// The [EpubReader] supports multiple reading modes:
/// - **Eager loading**: Load entire book into memory using [readBook]
/// - **Lazy loading**: Load metadata only, content on-demand using [openBook]
/// - **With chapter splitting**: Automatically split long chapters using [readBookWithSplitChapters] or [openBookWithSplitChapters]
///
/// The reader handles various EPUB formats (EPUB 2 and 3) and malformed files gracefully,
/// including EPUBs with incomplete navigation through smart NCX/spine reconciliation.
///
/// ## Example - Basic Reading
/// ```dart
/// // Load entire book into memory
/// List<int> bytes = await File('book.epub').readAsBytes();
/// EpubBook book = await EpubReader.readBook(bytes);
/// print('Title: ${book.title}');
/// print('Author: ${book.author}');
/// ```
///
/// ## Example - Lazy Loading
/// ```dart
/// // Load only metadata, content loaded on-demand
/// EpubBookRef bookRef = await EpubReader.openBook(bytes);
/// print('Title: ${bookRef.title}');
///
/// // Load chapters when needed
/// List<EpubChapterRef> chapters = bookRef.getChapters();
/// String firstChapterContent = await chapters[0].readHtmlContent();
/// ```
///
/// ## Example - With Chapter Splitting
/// ```dart
/// // Automatically split chapters exceeding 3000 words
/// EpubBook book = await EpubReader.readBookWithSplitChapters(bytes);
/// // Long chapters are now split: "Chapter 1 - Part 1", "Chapter 1 - Part 2", etc.
/// ```
class EpubReader {
  /// Opens an EPUB file for lazy loading without reading its content.
  ///
  /// This method loads only the metadata and structure of the EPUB file,
  /// making it very fast and memory-efficient. Content is loaded on-demand
  /// when accessed through the returned [EpubBookRef].
  ///
  /// The [bytes] parameter should contain the complete EPUB file data,
  /// which can be either a [Future<List<int>>] or [List<int>].
  ///
  /// Returns an [EpubBookRef] that provides access to:
  /// - Basic metadata (title, author, etc.)
  /// - Schema information (EPUB version, manifest, spine)
  /// - Chapter references for lazy content loading
  /// - Cover image extraction
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await File('book.epub').readAsBytes();
  /// final bookRef = await EpubReader.openBook(bytes);
  ///
  /// // Access metadata immediately
  /// print('Title: ${bookRef.title}');
  /// print('Authors: ${bookRef.authors.join(", ")}');
  ///
  /// // Content loaded only when needed
  /// final chapters = bookRef.getChapters();
  /// final content = await chapters[0].readHtmlContent();
  /// ```
  static Future<EpubBookRef> openBook(FutureOr<List<int>> bytes) async {
    List<int> loadedBytes;
    if (bytes is Future) {
      loadedBytes = await bytes;
    } else {
      loadedBytes = bytes;
    }

    var epubArchive = ZipDecoder().decodeBytes(loadedBytes);

    final schema = await SchemaReader.readSchema(epubArchive);
    final title = schema.package!.metadata!.titles
        .firstWhere((String name) => true, orElse: () => '');
    final authors = schema.package!.metadata!.creators
        .map((EpubMetadataCreator creator) => creator.creator)
        .whereType<String>()
        .toList();
    final author = authors.join(', ');

    final bookRef = EpubBookRef(
      epubArchive: epubArchive,
      title: title,
      author: author,
      authors: authors,
      schema: schema,
    );

    final content = ContentReader.parseContentMap(bookRef);

    return EpubBookRef(
      epubArchive: epubArchive,
      title: title,
      author: author,
      authors: authors,
      schema: schema,
      content: content,
    );
  }

  /// Reads an entire EPUB file into memory.
  ///
  /// This method loads all content of the EPUB file into memory at once,
  /// including all chapters, images, stylesheets, and other resources.
  /// Use this when you need immediate access to all content and have
  /// sufficient memory available.
  ///
  /// The [bytes] parameter should contain the complete EPUB file data,
  /// which can be either a [Future<List<int>>] or [List<int>].
  ///
  /// Returns an [EpubBook] containing:
  /// - All metadata (title, author, etc.)
  /// - Complete chapter content with HTML
  /// - All images, CSS, and fonts
  /// - Cover image (if available)
  /// - Properly structured chapter hierarchy with NCX/spine reconciliation
  ///
  /// For large EPUB files or memory-constrained environments, consider using
  /// [openBook] for lazy loading instead.
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await File('book.epub').readAsBytes();
  /// final book = await EpubReader.readBook(bytes);
  ///
  /// // All content is immediately available
  /// print('Chapter count: ${book.chapters.length}');
  /// print('First chapter: ${book.chapters[0].htmlContent}');
  ///
  /// // Access images
  /// book.content?.images?.forEach((name, image) {
  ///   print('Image: $name, size: ${image.content?.length} bytes');
  /// });
  /// ```
  static Future<EpubBook> readBook(FutureOr<List<int>> bytes) async {
    List<int> loadedBytes = await bytes;

    var epubBookRef = await openBook(loadedBytes);
    final schema = epubBookRef.schema;
    final title = epubBookRef.title;
    final authors = epubBookRef.authors;
    final author = epubBookRef.author;
    final content = await readContent(epubBookRef.content!);
    final coverImage = await epubBookRef.readCover();
    final chapterRefs = epubBookRef.getChapters();
    final chapters = await readChapters(chapterRefs);

    return EpubBook(
      title: title,
      author: author,
      authors: authors,
      schema: schema,
      content: content,
      coverImage: coverImage,
      chapters: chapters,
    );
  }

  static Future<EpubContent> readContent(EpubContentRef contentRef) async {
    final html = await readTextContentFiles(contentRef.html);
    final css = await readTextContentFiles(contentRef.css);
    final images = await readByteContentFiles(contentRef.images);
    final fonts = await readByteContentFiles(contentRef.fonts);
    final allFiles = <String, EpubContentFile>{};

    html.forEach((key, value) => allFiles[key] = value);
    css.forEach((key, value) => allFiles[key] = value);
    images.forEach((key, value) => allFiles[key] = value);
    fonts.forEach((key, value) => allFiles[key] = value);

    await Future.forEach(
      contentRef.allFiles.keys.where((key) => !allFiles.containsKey(key)),
      (key) async =>
          allFiles[key] = await readByteContentFile(contentRef.allFiles[key]!),
    );

    return EpubContent(
      html: html,
      css: css,
      images: images,
      fonts: fonts,
      allFiles: allFiles,
    );
  }

  static Future<Map<String, EpubTextContentFile>> readTextContentFiles(
    Map<String, EpubTextContentFileRef> textContentFileRefs,
  ) async {
    var result = <String, EpubTextContentFile>{};

    await Future.forEach(textContentFileRefs.keys, (String key) async {
      EpubContentFileRef value = textContentFileRefs[key]!;
      final content = await value.readContentAsText();
      final textContentFile = EpubTextContentFile(
        fileName: value.fileName,
        contentType: value.contentType,
        contentMimeType: value.contentMimeType,
        content: content,
      );
      result[key] = textContentFile;
    });
    return result;
  }

  static Future<Map<String, EpubByteContentFile>> readByteContentFiles(
    Map<String, EpubByteContentFileRef> byteContentFileRefs,
  ) async {
    var result = <String, EpubByteContentFile>{};
    await Future.forEach(byteContentFileRefs.keys, (dynamic key) async {
      result[key] = await readByteContentFile(byteContentFileRefs[key]!);
    });
    return result;
  }

  static Future<EpubByteContentFile> readByteContentFile(
    EpubContentFileRef contentFileRef,
  ) async {
    final content = await contentFileRef.readContentAsBytes();
    final result = EpubByteContentFile(
      fileName: contentFileRef.fileName,
      contentType: contentFileRef.contentType,
      contentMimeType: contentFileRef.contentMimeType,
      content: content,
    );

    return result;
  }

  static Future<List<EpubChapter>> readChapters(
    List<EpubChapterRef> chapterRefs,
  ) async {
    var result = <EpubChapter>[];

    await Future.forEach(chapterRefs, (EpubChapterRef chapterRef) async {
      final effectiveTitle =
          _getEffectiveTitle(chapterRef.title, chapterRef.contentFileName);
      final contentFileName = chapterRef.contentFileName;
      final anchor = chapterRef.anchor;
      final htmlContent = await chapterRef.readHtmlContent();
      final subChapters = await readChapters(chapterRef.subChapters);

      final chapter = EpubChapter(
        title: effectiveTitle,
        contentFileName: contentFileName,
        anchor: anchor,
        htmlContent: htmlContent,
        subChapters: subChapters,
      );

      result.add(chapter);
    });
    return result;
  }

  /// Returns an effective title using filename fallback if title is null/empty
  static String _getEffectiveTitle(String? title, String? contentFileName) {
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return _stripFileExtension(contentFileName) ?? 'Chapter';
  }

  /// Strips file extension from filename for cleaner titles
  static String? _stripFileExtension(String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return fileName;
    }
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  /// Reads an EPUB file and automatically splits long chapters.
  ///
  /// This method combines full content loading with automatic chapter splitting.
  /// Any chapter exceeding 3000 words is split into smaller parts at paragraph
  /// boundaries for better readability.
  ///
  /// The [bytes] parameter should contain the complete EPUB file data as [List<int>].
  ///
  /// Returns an [EpubBook] where long chapters have been split into parts:
  /// - Original: "Chapter 1" (10,000 words)
  /// - Result: "Chapter 1 - Part 1" (5,000 words), "Chapter 1 - Part 2" (5,000 words)
  ///
  /// Split chapters maintain:
  /// - Original content file references
  /// - Proper HTML structure
  /// - Subchapters (only in the first part)
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await File('book.epub').readAsBytes();
  /// final book = await EpubReader.readBookWithSplitChapters(bytes);
  ///
  /// // Long chapters are automatically split
  /// book.chapters.forEach((chapter) {
  ///   final wordCount = ChapterSplitter.countWords(chapter.htmlContent);
  ///   print('${chapter.title}: $wordCount words');
  ///   // Each chapter guaranteed to have ≤5000 words
  /// });
  /// ```
  ///
  /// For lazy loading with splitting, use [openBookWithSplitChapters] instead.
  static Future<EpubBook> readBookWithSplitChapters(List<int> bytes) async {
    final epubBookRef = await openBook(bytes);

    final schema = epubBookRef.schema;
    final title = epubBookRef.title;
    final authors = epubBookRef.authors;
    final author = epubBookRef.author;
    final content = await readContent(epubBookRef.content!);
    final coverImage = await epubBookRef.readCover();
    final chapterRefs = epubBookRef.getChapters();
    final chapters = await readChaptersWithSplitting(chapterRefs);

    return EpubBook(
      title: title,
      author: author,
      authors: authors,
      schema: schema,
      content: content,
      coverImage: coverImage,
      chapters: chapters,
    );
  }

  /// Reads chapters and splits any that exceed 3000 words.
  static Future<List<EpubChapter>> readChaptersWithSplitting(
    List<EpubChapterRef> chapterRefs,
  ) async {
    var result = <EpubChapter>[];

    for (final chapterRef in chapterRefs) {
      final splitChapters = await ChapterSplitter.splitChapterRef(chapterRef);
      result.addAll(splitChapters);
    }

    return result;
  }

  /// Opens an EPUB file for lazy loading with automatic chapter splitting.
  ///
  /// Combines the memory efficiency of lazy loading with automatic chapter
  /// splitting. Content is loaded on-demand, and long chapters are split
  /// only when accessed.
  ///
  /// The [bytes] parameter should contain the complete EPUB file data as [List<int>].
  ///
  /// Returns an [EpubBookRef] that automatically splits chapters when accessed:
  /// - Metadata loaded immediately
  /// - Chapter content loaded on-demand
  /// - Chapters >3000 words split when retrieved
  ///
  /// ## Example
  /// ```dart
  /// final bytes = await File('book.epub').readAsBytes();
  /// final bookRef = await EpubReader.openBookWithSplitChapters(bytes);
  ///
  /// // Get split chapter references (lazy)
  /// final chapterRefs = await bookRef.getChapterRefsWithSplitting();
  ///
  /// // Content loaded and split on-demand
  /// for (final ref in chapterRefs) {
  ///   if (ref is EpubChapterSplitRef) {
  ///     print('${ref.title} - Part ${ref.partNumber} of ${ref.totalParts}');
  ///   }
  ///   final content = await ref.readHtmlContent(); // Loaded here
  /// }
  /// ```
  static Future<EpubBookRef> openBookWithSplitChapters(List<int> bytes) async {
    final bookRef = await openBook(bytes);
    return EpubBookSplitRef.fromBookRef(bookRef);
  }
}
