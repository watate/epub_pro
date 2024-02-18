import 'package:collection/collection.dart';

class EpubChapter {
  final String? title;
  final String? contentFileName;
  final String? anchor;
  final String? htmlContent;
  final List<EpubChapter> subChapters;

  const EpubChapter({
    this.title,
    this.contentFileName,
    this.anchor,
    this.htmlContent,
    this.subChapters = const <EpubChapter>[],
  });

  @override
  int get hashCode {
    return title.hashCode ^
        contentFileName.hashCode ^
        anchor.hashCode ^
        htmlContent.hashCode ^
        const DeepCollectionEquality().hash(subChapters);
  }

  @override
  bool operator ==(covariant EpubChapter other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.title == title &&
        other.contentFileName == contentFileName &&
        other.anchor == anchor &&
        other.htmlContent == htmlContent &&
        listEquals(other.subChapters, subChapters);
  }

  @override
  String toString() {
    return 'Title: $title, Subchapter count: ${subChapters.length}';
  }
}
