import 'package:collection/collection.dart';

import 'epub_content_file.dart';

class EpubByteContentFile extends EpubContentFile {
  final List<int>? content;

  const EpubByteContentFile({
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
      const DeepCollectionEquality().hash(content);

  @override
  bool operator ==(covariant EpubByteContentFile other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return fileName == other.fileName &&
        contentMimeType == other.contentMimeType &&
        contentType == other.contentType &&
        listEquals(content, other.content);
  }
}
