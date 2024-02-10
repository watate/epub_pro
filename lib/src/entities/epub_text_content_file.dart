import 'package:quiver/core.dart';

import 'epub_content_file.dart';

class EpubTextContentFile extends EpubContentFile {
  String? content;

  @override
  int get hashCode => hash4(content, contentMimeType, contentType, fileName);

  @override
  bool operator ==(other) {
    if (other is! EpubTextContentFile) {
      return false;
    }

    return content == other.content &&
        contentMimeType == other.contentMimeType &&
        contentType == other.contentType &&
        fileName == other.fileName;
  }
}
