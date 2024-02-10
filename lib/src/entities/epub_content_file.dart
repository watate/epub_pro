import 'package:quiver/core.dart';

import 'epub_content_type.dart';

abstract class EpubContentFile {
  String? fileName;
  EpubContentType? contentType;
  String? contentMimeType;

  @override
  int get hashCode =>
      hash3(fileName.hashCode, contentType.hashCode, contentMimeType.hashCode);

  @override
  bool operator ==(other) {
    if (other is! EpubContentFile) {
      return false;
    }
    return fileName == other.fileName &&
        contentType == other.contentType &&
        contentMimeType == other.contentMimeType;
  }
}
