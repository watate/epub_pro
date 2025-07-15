import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:epub_pro/src/utils/zip_path_utils.dart';
import 'package:epub_pro/src/writers/epub_package_writer.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_text_content_file.dart';

/// A class that provides functionality to write EPUB files.
///
/// The [EpubWriter] can serialize an [EpubBook] back into a valid EPUB file format.
/// This is useful for:
/// - Creating new EPUB files programmatically
/// - Modifying existing EPUB files
/// - Converting between formats
///
/// The writer handles:
/// - Proper EPUB structure (mimetype, META-INF, OEBPS)
/// - Content packaging with correct mime types
/// - OPF manifest generation
/// - Maintaining references between files
///
/// ## Example
/// ```dart
/// // Read an EPUB
/// final bytes = await File('input.epub').readAsBytes();
/// final book = await EpubReader.readBook(bytes);
///
/// // Modify the book (e.g., change title)
/// final modifiedBook = EpubBook(
///   title: 'New Title',
///   author: book.author,
///   chapters: book.chapters,
///   content: book.content,
///   schema: book.schema,
/// );
///
/// // Write to new EPUB file
/// final outputBytes = EpubWriter.writeBook(modifiedBook);
/// await File('output.epub').writeAsBytes(outputBytes!);
/// ```
class EpubWriter {
  static const _containerFile =
      '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>';

  // Creates a Zip Archive of an EpubBook
  static Archive _createArchive(EpubBook book) {
    var arch = Archive();

    // Add simple metadata
    arch.addFile(ArchiveFile.noCompress(
        'mimetype', 20, convert.utf8.encode('application/epub+zip')));

    // Add Container file
    arch.addFile(ArchiveFile('META-INF/container.xml', _containerFile.length,
        convert.utf8.encode(_containerFile)));

    // Add all content to the archive
    book.content!.allFiles.forEach((name, file) {
      List<int>? content;

      if (file is EpubByteContentFile) {
        content = file.content;
      } else if (file is EpubTextContentFile) {
        content = convert.utf8.encode(file.content!);
      }

      arch.addFile(ArchiveFile(
          ZipPathUtils.combine(book.schema!.contentDirectoryPath, name)!,
          content!.length,
          content));
    });

    // Generate the content.opf file and add it to the Archive
    var contentopf = EpubPackageWriter.writeContent(book.schema!.package!);

    arch.addFile(ArchiveFile(
        ZipPathUtils.combine(book.schema!.contentDirectoryPath, 'content.opf')!,
        contentopf.length,
        convert.utf8.encode(contentopf)));

    return arch;
  }

  /// Writes an [EpubBook] to a byte array.
  ///
  /// Serializes the complete book structure into a valid EPUB file format.
  /// The resulting byte array can be written directly to a file or transmitted
  /// over a network.
  ///
  /// The [book] parameter must contain:
  /// - Valid schema with package information
  /// - Content files (HTML, CSS, images, etc.)
  /// - Proper content directory path
  ///
  /// Returns a [List<int>] containing the EPUB file data, or null if the
  /// book structure is invalid.
  ///
  /// The generated EPUB includes:
  /// - Uncompressed mimetype (as per EPUB specification)
  /// - META-INF/container.xml pointing to the OPF file
  /// - All content files in their proper locations
  /// - Generated content.opf with complete manifest
  ///
  /// ## Example
  /// ```dart
  /// final book = EpubBook(
  ///   title: 'My Book',
  ///   author: 'John Doe',
  ///   chapters: chapters,
  ///   content: content,
  ///   schema: schema,
  /// );
  ///
  /// final epubBytes = EpubWriter.writeBook(book);
  /// if (epubBytes != null) {
  ///   await File('my_book.epub').writeAsBytes(epubBytes);
  /// }
  /// ```
  static List<int>? writeBook(EpubBook book) {
    var arch = _createArchive(book);

    return ZipEncoder().encode(arch);
  }
}
