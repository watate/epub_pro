import 'package:collection/collection.dart';

class EpubNavigationDocTitle {
  final List<String> titles;

  const EpubNavigationDocTitle({
    this.titles = const <String>[],
  });

  @override
  int get hashCode => const DeepCollectionEquality().hash(titles);

  @override
  bool operator ==(covariant EpubNavigationDocTitle other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.titles, titles);
  }
}
