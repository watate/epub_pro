import '../entities/epub_content_type.dart';
import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_byte_content_file_ref.dart';
import '../ref_entities/epub_content_file_ref.dart';
import '../ref_entities/epub_content_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';

class ContentReader {
  static EpubContentRef parseContentMap(EpubBookRef bookRef) {
    final html = <String, EpubTextContentFileRef>{};
    final css = <String, EpubTextContentFileRef>{};
    final images = <String, EpubByteContentFileRef>{};
    final fonts = <String, EpubByteContentFileRef>{};
    final allFiles = <String, EpubContentFileRef>{};

    for (final manifestItem in bookRef.schema!.package!.manifest!.items) {
      var fileName = manifestItem.href ?? '';
      var contentMimeType = manifestItem.mediaType!;
      var contentType = EpubContentType.fromMimeType(contentMimeType);
      switch (contentType) {
        case EpubContentType.xhtml11:
        case EpubContentType.css:
        case EpubContentType.oeb1Document:
        case EpubContentType.oeb1CSS:
        case EpubContentType.xml:
        case EpubContentType.dtbook:
        case EpubContentType.dtbookNCX:
          var epubTextContentFile = EpubTextContentFileRef(
            epubBookRef: bookRef,
            fileName: Uri.decodeFull(fileName),
            contentMimeType: contentMimeType,
          );

          switch (contentType) {
            case EpubContentType.xhtml11:
              html[fileName] = epubTextContentFile;
            case EpubContentType.css:
              css[fileName] = epubTextContentFile;
            default:
              break;
          }
          allFiles[fileName] = epubTextContentFile;
        default:
          var epubByteContentFile = EpubByteContentFileRef(
            epubBookRef: bookRef,
            fileName: Uri.decodeFull(fileName),
            contentMimeType: contentMimeType,
            contentType: contentType,
          );

          switch (contentType) {
            case EpubContentType.imageGIF:
            case EpubContentType.imageJPEG:
            case EpubContentType.imagePNG:
            case EpubContentType.imageSVG:
            case EpubContentType.imageBMP:
              images[fileName] = epubByteContentFile;
            case EpubContentType.fontTrueType:
            case EpubContentType.fontOpenType:
              fonts[fileName] = epubByteContentFile;
            default:
              break;
          }
          allFiles[fileName] = epubByteContentFile;
      }
    }
    return EpubContentRef(
      html: html,
      css: css,
      images: images,
      fonts: fonts,
      allFiles: allFiles,
    );
  }
}
