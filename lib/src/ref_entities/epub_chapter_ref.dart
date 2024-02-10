import 'dart:async';

import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_text_content_file_ref.dart';

class EpubChapterRef {
  EpubTextContentFileRef? epubTextContentFileRef;

  String? title;
  String? contentFileName;
  String? anchor;
  List<EpubChapterRef>? subChapters;

  EpubChapterRef(this.epubTextContentFileRef);

  @override
  int get hashCode {
    var objects = [
      title.hashCode,
      contentFileName.hashCode,
      anchor.hashCode,
      epubTextContentFileRef.hashCode,
      ...subChapters?.map((subChapter) => subChapter.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubChapterRef) {
      return false;
    }
    return title == other.title &&
        contentFileName == other.contentFileName &&
        anchor == other.anchor &&
        epubTextContentFileRef == other.epubTextContentFileRef &&
        collections.listsEqual(subChapters, other.subChapters);
  }

  Future<String> readHtmlContent() async {
    return epubTextContentFileRef!.readContentAsText();
  }

  @override
  String toString() {
    return 'Title: $title, Subchapter count: ${subChapters!.length}';
  }
}
