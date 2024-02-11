import 'package:collection/collection.dart';

import 'epub_navigation_point.dart';

class EpubNavigationMap {
  final List<EpubNavigationPoint> points;

  const EpubNavigationMap({
    this.points = const <EpubNavigationPoint>[],
  });

  @override
  int get hashCode => const DeepCollectionEquality().hash(points);

  @override
  bool operator ==(covariant EpubNavigationMap other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.points, points);
  }
}
