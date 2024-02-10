import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_navigation_label.dart';
import 'epub_navigation_target.dart';

class EpubNavigationList {
  String? id;
  String? classs;
  List<EpubNavigationLabel>? navigationLabels;
  List<EpubNavigationTarget>? navigationTargets;

  @override
  int get hashCode {
    var objects = [
      id.hashCode,
      classs.hashCode,
      ...navigationLabels?.map((label) => label.hashCode) ?? [0],
      ...navigationTargets?.map((target) => target.hashCode) ?? [0]
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigationList?;
    if (otherAs == null) return false;

    if (!(id == otherAs.id && classs == otherAs.classs)) {
      return false;
    }

    if (!collections.listsEqual(navigationLabels, otherAs.navigationLabels)) {
      return false;
    }
    if (!collections.listsEqual(navigationTargets, otherAs.navigationTargets)) {
      return false;
    }
    return true;
  }
}
