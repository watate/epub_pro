import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_byte_content_file.dart';
import 'epub_content_file.dart';
import 'epub_text_content_file.dart';

class EpubContent {
  Map<String, EpubTextContentFile>? html;
  Map<String, EpubTextContentFile>? css;
  Map<String, EpubByteContentFile>? images;
  Map<String, EpubByteContentFile>? fonts;
  Map<String, EpubContentFile>? allFiles;

  EpubContent() {
    html = <String, EpubTextContentFile>{};
    css = <String, EpubTextContentFile>{};
    images = <String, EpubByteContentFile>{};
    fonts = <String, EpubByteContentFile>{};
    allFiles = <String, EpubContentFile>{};
  }

  @override
  int get hashCode {
    var objects = [
      ...html!.keys.map((key) => key.hashCode),
      ...html!.values.map((value) => value.hashCode),
      ...css!.keys.map((key) => key.hashCode),
      ...css!.values.map((value) => value.hashCode),
      ...images!.keys.map((key) => key.hashCode),
      ...images!.values.map((value) => value.hashCode),
      ...fonts!.keys.map((key) => key.hashCode),
      ...fonts!.values.map((value) => value.hashCode),
      ...allFiles!.keys.map((key) => key.hashCode),
      ...allFiles!.values.map((value) => value.hashCode),
    ];

    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubContent) {
      return false;
    }
    return collections.mapsEqual(html, other.html) &&
        collections.mapsEqual(css, other.css) &&
        collections.mapsEqual(images, other.images) &&
        collections.mapsEqual(fonts, other.fonts) &&
        collections.mapsEqual(allFiles, other.allFiles);
  }
}
