import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_navigation_point.dart';

class EpubNavigationMap {
  List<EpubNavigationPoint>? points;

  @override
  int get hashCode {
    return hashObjects(points?.map((point) => point.hashCode) ?? [0]);
  }

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigationMap?;
    if (otherAs == null) return false;

    return collections.listsEqual(points, otherAs.points);
  }
}
