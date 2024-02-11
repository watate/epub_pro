import 'epub_content_file.dart';

class EpubTextContentFile extends EpubContentFile {
  final String? content;

  const EpubTextContentFile({
    super.fileName,
    super.contentMimeType,
    super.contentType,
    this.content,
  });

  @override
  int get hashCode =>
      fileName.hashCode ^
      contentMimeType.hashCode ^
      contentType.hashCode ^
      content.hashCode;

  @override
  bool operator ==(covariant EpubTextContentFile other) {
    if (identical(this, other)) return true;

    return other.fileName == fileName &&
        other.contentMimeType == contentMimeType &&
        other.contentType == contentType &&
        other.content == content;
  }
}
