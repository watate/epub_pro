import 'package:collection/collection.dart';

class EpubNavigationDocAuthor {
  final List<String> authors;

  const EpubNavigationDocAuthor({
    this.authors = const <String>[],
  });

  @override
  int get hashCode => const DeepCollectionEquality().hash(authors);

  @override
  bool operator ==(covariant EpubNavigationDocAuthor other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.authors, authors);
  }
}
