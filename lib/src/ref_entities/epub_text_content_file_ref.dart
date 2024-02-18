import 'dart:async';

import 'epub_content_file_ref.dart';

class EpubTextContentFileRef extends EpubContentFileRef {
  EpubTextContentFileRef({
    required super.epubBookRef,
    super.fileName,
    super.contentMimeType,
    super.contentType,
  });

  Future<String> readContentAsync() => readContentAsText();

  @override
  int get hashCode =>
      epubBookRef.hashCode ^
      fileName.hashCode ^
      contentMimeType.hashCode ^
      contentType.hashCode;

  @override
  bool operator ==(covariant EpubTextContentFileRef other) {
    if (identical(this, other)) return true;

    return other.epubBookRef == epubBookRef &&
        other.fileName == fileName &&
        other.contentMimeType == contentMimeType &&
        other.contentType == contentType;
  }
}
