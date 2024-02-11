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

    var bookRef = EpubBookRef(epubArchive);
    bookRef.schema = await SchemaReader.readSchema(epubArchive);
    bookRef.title = bookRef.schema!.package!.metadata!.titles
        .firstWhere((String name) => true, orElse: () => '');
    bookRef.authors = bookRef.schema!.package!.metadata!.creators
        .map((EpubMetadataCreator creator) => creator.creator)
        .toList();
    bookRef.author = bookRef.authors!.join(', ');
    bookRef.content = ContentReader.parseContentMap(bookRef);
    return bookRef;
  }

  /// Opens the book asynchronously and reads all of its content into the memory. Does not hold the handle to the EPUB file.
  static Future<EpubBook> readBook(FutureOr<List<int>> bytes) async {
    var result = EpubBook();
    List<int> loadedBytes;
    if (bytes is Future) {
      loadedBytes = await bytes;
    } else {
      loadedBytes = bytes;
    }

    var epubBookRef = await openBook(loadedBytes);
    result.schema = epubBookRef.schema;
    result.title = epubBookRef.title;
    result.authors = epubBookRef.authors;
    result.author = epubBookRef.author;
    result.content = await readContent(epubBookRef.content!);
    result.coverImage = await epubBookRef.readCover();
    var chapterRefs = await epubBookRef.getChapters();
    result.chapters = await readChapters(chapterRefs);

    return result;
  }

  static Future<EpubContent> readContent(EpubContentRef contentRef) async {
    var result = EpubContent();
    result.html = await readTextContentFiles(contentRef.html!);
    result.css = await readTextContentFiles(contentRef.css!);
    result.images = await readByteContentFiles(contentRef.images!);
    result.fonts = await readByteContentFiles(contentRef.fonts!);
    result.allFiles = <String, EpubContentFile>{};

    result.html!.forEach((String? key, EpubTextContentFile value) {
      result.allFiles![key!] = value;
    });
    result.css!.forEach((String? key, EpubTextContentFile value) {
      result.allFiles![key!] = value;
    });

    result.images!.forEach((String? key, EpubByteContentFile value) {
      result.allFiles![key!] = value;
    });
    result.fonts!.forEach((String? key, EpubByteContentFile value) {
      result.allFiles![key!] = value;
    });

    await Future.forEach(contentRef.allFiles!.keys, (dynamic key) async {
      if (!result.allFiles!.containsKey(key)) {
        result.allFiles![key] =
            await readByteContentFile(contentRef.allFiles![key]!);
      }
    });

    return result;
  }

  static Future<Map<String, EpubTextContentFile>> readTextContentFiles(
      Map<String, EpubTextContentFileRef> textContentFileRefs) async {
    var result = <String, EpubTextContentFile>{};

    await Future.forEach(textContentFileRefs.keys, (dynamic key) async {
      EpubContentFileRef value = textContentFileRefs[key]!;
      var textContentFile = EpubTextContentFile();
      textContentFile.fileName = value.fileName;
      textContentFile.contentType = value.contentType;
      textContentFile.contentMimeType = value.contentMimeType;
      textContentFile.content = await value.readContentAsText();
      result[key] = textContentFile;
    });
    return result;
  }

  static Future<Map<String, EpubByteContentFile>> readByteContentFiles(
      Map<String, EpubByteContentFileRef> byteContentFileRefs) async {
    var result = <String, EpubByteContentFile>{};
    await Future.forEach(byteContentFileRefs.keys, (dynamic key) async {
      result[key] = await readByteContentFile(byteContentFileRefs[key]!);
    });
    return result;
  }

  static Future<EpubByteContentFile> readByteContentFile(
      EpubContentFileRef contentFileRef) async {
    var result = EpubByteContentFile();

    result.fileName = contentFileRef.fileName;
    result.contentType = contentFileRef.contentType;
    result.contentMimeType = contentFileRef.contentMimeType;
    result.content = await contentFileRef.readContentAsBytes();

    return result;
  }

  static Future<List<EpubChapter>> readChapters(
      List<EpubChapterRef> chapterRefs) async {
    var result = <EpubChapter>[];
    await Future.forEach(chapterRefs, (EpubChapterRef chapterRef) async {
      var chapter = EpubChapter();

      chapter.title = chapterRef.title;
      chapter.contentFileName = chapterRef.contentFileName;
      chapter.anchor = chapterRef.anchor;
      chapter.htmlContent = await chapterRef.readHtmlContent();
      chapter.subChapters = await readChapters(chapterRef.subChapters!);

      result.add(chapter);
    });
    return result;
  }
}
