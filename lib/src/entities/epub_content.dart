import 'package:collection/collection.dart';

import 'epub_byte_content_file.dart';
import 'epub_content_file.dart';
import 'epub_text_content_file.dart';

class EpubContent {
  final Map<String, EpubTextContentFile> html;
  final Map<String, EpubTextContentFile> css;
  final Map<String, EpubByteContentFile> images;
  final Map<String, EpubByteContentFile> fonts;
  final Map<String, EpubContentFile> allFiles;

  const EpubContent({
    this.html = const <String, EpubTextContentFile>{},
    this.css = const <String, EpubTextContentFile>{},
    this.images = const <String, EpubByteContentFile>{},
    this.fonts = const <String, EpubByteContentFile>{},
    this.allFiles = const <String, EpubContentFile>{},
  });

  @override
  int get hashCode {
    final hash = const DeepCollectionEquality().hash;

    return hash(html) ^ hash(css) ^ hash(images) ^ hash(fonts) ^ hash(allFiles);
  }

  @override
  bool operator ==(covariant EpubContent other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return mapEquals(other.html, html) &&
        mapEquals(other.css, css) &&
        mapEquals(other.images, images) &&
        mapEquals(other.fonts, fonts) &&
        mapEquals(other.allFiles, allFiles);
  }
}
