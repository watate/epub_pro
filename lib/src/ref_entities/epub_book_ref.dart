import 'dart:async';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:image/image.dart';

import '../entities/epub_chapter.dart';
import '../entities/epub_schema.dart';
import '../readers/book_cover_reader.dart';
import '../readers/chapter_reader.dart';
import '../utils/chapter_splitter.dart';
import 'epub_chapter_ref.dart';
import 'epub_content_ref.dart';

class EpubBookRef {
  final Archive epubArchive;
  final String? title;
  final String? author;
  final List<String> authors;
  final EpubSchema? schema;
  final EpubContentRef? content;

  const EpubBookRef({
    required this.epubArchive,
    this.title,
    this.author,
    this.authors = const [],
    this.schema,
    this.content,
  });

  @override
  int get hashCode {
    return title.hashCode ^
        author.hashCode ^
        authors.hashCode ^
        schema.hashCode ^
        content.hashCode;
  }

  @override
  bool operator ==(covariant EpubBookRef other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.title == title &&
        other.author == author &&
        listEquals(other.authors, authors) &&
        other.schema == schema &&
        other.content == content;
  }

  List<EpubChapterRef> getChapters() {
    return ChapterReader.getChapters(this);
  }

  /// Gets chapters and automatically splits any that exceed 5000 words.
  ///
  /// This method loads chapter content on-demand and splits long chapters
  /// into smaller parts of approximately 5000 words each.
  ///
  /// Returns a `Future<List<EpubChapter>>` instead of `List<EpubChapterRef>`
  /// because splitting requires reading the actual content.
  Future<List<EpubChapter>> getChaptersWithSplitting() async {
    final chapterRefs = getChapters();
    final result = <EpubChapter>[];

    for (final chapterRef in chapterRefs) {
      final splitChapters = await ChapterSplitter.splitChapterRef(chapterRef);
      result.addAll(splitChapters);
    }

    return result;
  }

  Future<Image?> readCover() async {
    return await BookCoverReader.readBookCover(this);
  }
}
