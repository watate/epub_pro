import 'dart:async';

import 'package:archive/archive.dart';
import 'package:image/image.dart';
import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import '../entities/epub_schema.dart';
import '../readers/book_cover_reader.dart';
import '../readers/chapter_reader.dart';
import 'epub_chapter_ref.dart';
import 'epub_content_ref.dart';

class EpubBookRef {
  Archive? _epubArchive;

  String? title;
  String? author;
  List<String?>? authors;
  EpubSchema? schema;
  EpubContentRef? content;
  EpubBookRef(Archive epubArchive) {
    _epubArchive = epubArchive;
  }

  @override
  int get hashCode {
    var objects = [
      title.hashCode,
      author.hashCode,
      schema.hashCode,
      content.hashCode,
      ...authors?.map((author) => author.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubBookRef) {
      return false;
    }

    return title == other.title &&
        author == other.author &&
        schema == other.schema &&
        content == other.content &&
        collections.listsEqual(authors, other.authors);
  }

  Archive? epubArchive() {
    return _epubArchive;
  }

  Future<List<EpubChapterRef>> getChapters() async {
    return ChapterReader.getChapters(this);
  }

  Future<Image?> readCover() async {
    return await BookCoverReader.readBookCover(this);
  }
}
