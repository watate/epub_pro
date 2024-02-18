import 'dart:async';

import 'package:collection/collection.dart';

import 'epub_text_content_file_ref.dart';

class EpubChapterRef {
  final EpubTextContentFileRef? epubTextContentFileRef;
  final String? title;
  final String? contentFileName;
  final String? anchor;
  final List<EpubChapterRef> subChapters;

  const EpubChapterRef({
    this.epubTextContentFileRef,
    this.title,
    this.contentFileName,
    this.anchor,
    this.subChapters = const <EpubChapterRef>[],
  });

  @override
  int get hashCode {
    final hash = const DeepCollectionEquality().hash;
    return epubTextContentFileRef.hashCode ^
        title.hashCode ^
        contentFileName.hashCode ^
        anchor.hashCode ^
        hash(subChapters);
  }

  @override
  bool operator ==(covariant EpubChapterRef other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.epubTextContentFileRef == epubTextContentFileRef &&
        other.title == title &&
        other.contentFileName == contentFileName &&
        other.anchor == anchor &&
        listEquals(other.subChapters, subChapters);
  }

  Future<String> readHtmlContent() async {
    return epubTextContentFileRef!.readContentAsText();
  }

  @override
  String toString() {
    return 'Title: $title, Subchapter count: ${subChapters.length}';
  }
}
