import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_navigation_page_target.dart';

class EpubNavigationPageList {
  List<EpubNavigationPageTarget>? targets;

  @override
  int get hashCode {
    return hashObjects(targets?.map((target) => target.hashCode) ?? [0]);
  }

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigationPageList?;
    if (otherAs == null) return false;

    return collections.listsEqual(targets, otherAs.targets);
  }
}
