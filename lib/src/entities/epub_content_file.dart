import 'epub_content_type.dart';

abstract class EpubContentFile {
  final String? fileName;
  final EpubContentType? contentType;
  final String? contentMimeType;

  const EpubContentFile({
    this.fileName,
    this.contentType,
    this.contentMimeType,
  });

  @override
  int get hashCode =>
      fileName.hashCode ^ contentType.hashCode ^ contentMimeType.hashCode;

  @override
  bool operator ==(covariant EpubContentFile other) {
    if (identical(this, other)) return true;

    return other.fileName == fileName &&
        other.contentType == contentType &&
        other.contentMimeType == contentMimeType;
  }
}
