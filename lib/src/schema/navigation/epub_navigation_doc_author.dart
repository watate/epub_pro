import 'package:collection/collection.dart';

class EpubNavigationDocAuthor {
  final List<String> authors;

  const EpubNavigationDocAuthor({
    this.authors = const <String>[],
  });

  @override
  int get hashCode => authors.fold(
        0,
        (hashCode, author) => hashCode ^ author.hashCode,
      );

  @override
  bool operator ==(covariant EpubNavigationDocAuthor other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.authors, authors);
  }
}
