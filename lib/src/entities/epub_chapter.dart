import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

class EpubChapter {
  String? title;
  String? contentFileName;
  String? anchor;
  String? htmlContent;
  List<EpubChapter>? subChapters;

  @override
  int get hashCode {
    var objects = [
      title.hashCode,
      contentFileName.hashCode,
      anchor.hashCode,
      htmlContent.hashCode,
      ...subChapters?.map((subChapter) => subChapter.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubChapter) {
      return false;
    }
    return title == other.title &&
        contentFileName == other.contentFileName &&
        anchor == other.anchor &&
        htmlContent == other.htmlContent &&
        collections.listsEqual(subChapters, other.subChapters);
  }

  @override
  String toString() {
    return 'Title: $title, Subchapter count: ${subChapters!.length}';
  }
}
