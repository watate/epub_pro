import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:epub_plus/src/utils/zip_path_utils.dart';
import 'package:epub_plus/src/writers/epub_package_writer.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_text_content_file.dart';

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

  // Serializes the EpubBook into a byte array
  static List<int>? writeBook(EpubBook book) {
    var arch = _createArchive(book);

    return ZipEncoder().encode(arch);
  }
}
