import '../entities/epub_content_type.dart';
import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_byte_content_file_ref.dart';
import '../ref_entities/epub_content_file_ref.dart';
import '../ref_entities/epub_content_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';

class ContentReader {
  static EpubContentRef parseContentMap(EpubBookRef bookRef) {
    var result = EpubContentRef();
    result.html = <String, EpubTextContentFileRef>{};
    result.css = <String, EpubTextContentFileRef>{};
    result.images = <String, EpubByteContentFileRef>{};
    result.fonts = <String, EpubByteContentFileRef>{};
    result.allFiles = <String, EpubContentFileRef>{};

    for (final manifestItem in bookRef.schema!.package!.manifest!.items!) {
      var fileName = manifestItem.href;
      var contentMimeType = manifestItem.mediaType!;
      var contentType = getContentTypeByContentMimeType(contentMimeType);
      switch (contentType) {
        case EpubContentType.xhtml11:
        case EpubContentType.css:
        case EpubContentType.oeb1Document:
        case EpubContentType.oeb1CSS:
        case EpubContentType.xml:
        case EpubContentType.dtbook:
        case EpubContentType.dtbookNCX:
          var epubTextContentFile = EpubTextContentFileRef(bookRef);

          epubTextContentFile.fileName = Uri.decodeFull(fileName!);
          epubTextContentFile.contentMimeType = contentMimeType;
          epubTextContentFile.contentType = contentType;

          switch (contentType) {
            case EpubContentType.xhtml11:
              result.html![fileName] = epubTextContentFile;
            case EpubContentType.css:
              result.css![fileName] = epubTextContentFile;
            case EpubContentType.dtbook:
            case EpubContentType.dtbookNCX:
            case EpubContentType.oeb1Document:
            case EpubContentType.xml:
            case EpubContentType.oeb1CSS:
            case EpubContentType.imageGIF:
            case EpubContentType.imageJPEG:
            case EpubContentType.imagePNG:
            case EpubContentType.imageSVG:
            case EpubContentType.imageBMP:
            case EpubContentType.fontTrueType:
            case EpubContentType.fontOpenType:
            case EpubContentType.other:
              break;
          }
          result.allFiles![fileName] = epubTextContentFile;
        default:
          var epubByteContentFile = EpubByteContentFileRef(bookRef);

          epubByteContentFile.fileName = Uri.decodeFull(fileName!);
          epubByteContentFile.contentMimeType = contentMimeType;
          epubByteContentFile.contentType = contentType;

          switch (contentType) {
            case EpubContentType.imageGIF:
            case EpubContentType.imageJPEG:
            case EpubContentType.imagePNG:
            case EpubContentType.imageSVG:
            case EpubContentType.imageBMP:
              result.images![fileName] = epubByteContentFile;
            case EpubContentType.fontTrueType:
            case EpubContentType.fontOpenType:
              result.fonts![fileName] = epubByteContentFile;
            case EpubContentType.css:
            case EpubContentType.xhtml11:
            case EpubContentType.dtbook:
            case EpubContentType.dtbookNCX:
            case EpubContentType.oeb1Document:
            case EpubContentType.xml:
            case EpubContentType.oeb1CSS:
            case EpubContentType.other:
              break;
          }
          result.allFiles![fileName] = epubByteContentFile;
      }
    }
    return result;
  }

  static EpubContentType getContentTypeByContentMimeType(
    String contentMimeType,
  ) =>
      switch (contentMimeType.toLowerCase()) {
        'application/xhtml+xml' || 'text/html' => EpubContentType.xhtml11,
        'application/x-dtbook+xml' => EpubContentType.dtbook,
        'application/x-dtbncx+xml' => EpubContentType.dtbookNCX,
        'text/x-oeb1-document' => EpubContentType.oeb1Document,
        'application/xml' => EpubContentType.xml,
        'text/css' => EpubContentType.css,
        'text/x-oeb1-css' => EpubContentType.oeb1CSS,
        'image/gif' => EpubContentType.imageGIF,
        'image/jpeg' => EpubContentType.imageJPEG,
        'image/png' => EpubContentType.imagePNG,
        'image/svg+xml' => EpubContentType.imageSVG,
        'image/bmp' => EpubContentType.imageBMP,
        'font/truetype' => EpubContentType.fontTrueType,
        'font/opentype' ||
        'application/vnd.ms-opentype' =>
          EpubContentType.fontOpenType,
        _ => EpubContentType.other,
      };
}
