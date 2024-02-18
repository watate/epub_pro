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
import 'ref_entities/epub_byte_content_file_ref.dart';
import 'ref_entities/epub_chapter_ref.dart';
import 'ref_entities/epub_content_file_ref.dart';
import 'ref_entities/epub_content_ref.dart';
import 'ref_entities/epub_text_content_file_ref.dart';
import 'schema/opf/epub_metadata_creator.dart';

/// A class that provides the primary interface to read Epub files.
///
/// To open an Epub and load all data at once use the [readBook()] method.
///
/// To open an Epub and load only basic metadata use the [openBook()] method.
/// This is a good option to quickly load text-based metadata, while leaving the
/// heavier lifting of loading images and main content for subsequent operations.
///
/// ## Example
/// ```dart
/// // Read the basic metadata.
/// EpubBookRef epub = await EpubReader.openBook(epubFileBytes);
/// // Extract values of interest.
/// String title = epub.Title;
/// String author = epub.Author;
/// var metadata = epub.Schema.Package.Metadata;
/// String genres = metadata.Subjects.join(', ');
/// ```
class EpubReader {
  /// Loads basics metadata.
  ///
  /// Opens the book asynchronously without reading its main content.
  /// Holds the handle to the EPUB file.
  ///
  /// Argument [bytes] should be the bytes of
  /// the epub file you have loaded with something like the [dart:io] package's
  /// [readAsBytes()].
  ///
  /// This is a fast and convenient way to get the most important information
  /// about the book, notably the [Title], [Author] and [AuthorList].
  /// Additional information is loaded in the [Schema] property such as the
  /// Epub version, Publishers, Languages and more.
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

  /// Opens the book asynchronously and reads all of its content into the memory. Does not hold the handle to the EPUB file.
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
      final title = chapterRef.title;
      final contentFileName = chapterRef.contentFileName;
      final anchor = chapterRef.anchor;
      final htmlContent = await chapterRef.readHtmlContent();
      final subChapters = await readChapters(chapterRef.subChapters);

      final chapter = EpubChapter(
        title: title,
        contentFileName: contentFileName,
        anchor: anchor,
        htmlContent: htmlContent,
        subChapters: subChapters,
      );

      result.add(chapter);
    });
    return result;
  }
}
