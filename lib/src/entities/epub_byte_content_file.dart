import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_content_file.dart';

class EpubByteContentFile extends EpubContentFile {
  List<int>? content;

  @override
  int get hashCode {
    var objects = [
      contentMimeType.hashCode,
      contentType.hashCode,
      fileName.hashCode,
      ...content?.map((content) => content.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubByteContentFile) {
      return false;
    }
    return collections.listsEqual(content, other.content) &&
        contentMimeType == other.contentMimeType &&
        contentType == other.contentType &&
        fileName == other.fileName;
  }
}
