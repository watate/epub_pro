import 'package:collection/collection.dart';
import 'package:image/image.dart';

import 'epub_chapter.dart';
import 'epub_content.dart';
import 'epub_schema.dart';

class EpubBook {
  final String? title;
  final String? author;
  final List<String?> authors;
  final EpubSchema? schema;
  final EpubContent? content;
  final Image? coverImage;
  final List<EpubChapter> chapters;

  const EpubBook({
    this.title,
    this.author,
    this.authors = const <String>[],
    this.schema,
    this.content,
    this.coverImage,
    this.chapters = const <EpubChapter>[],
  });

  @override
  int get hashCode {
    final hash = const DeepCollectionEquality().hash;
    return title.hashCode ^
        author.hashCode ^
        hash(authors) ^
        schema.hashCode ^
        content.hashCode ^
        coverImage.hashCode ^
        hash(chapters);
  }

  @override
  bool operator ==(covariant EpubBook other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.title == title &&
        other.author == author &&
        listEquals(other.authors, authors) &&
        other.schema == schema &&
        other.content == content &&
        other.coverImage == coverImage &&
        listEquals(other.chapters, chapters);
  }
}
