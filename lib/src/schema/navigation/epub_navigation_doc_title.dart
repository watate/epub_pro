import 'package:collection/collection.dart';

class EpubNavigationDocTitle {
  final List<String> titles;

  const EpubNavigationDocTitle({
    this.titles = const <String>[],
  });

  @override
  int get hashCode => titles.fold(
        0,
        (hashCode, title) => hashCode ^ title.hashCode,
      );

  @override
  bool operator ==(covariant EpubNavigationDocTitle other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.titles, titles);
  }
}
