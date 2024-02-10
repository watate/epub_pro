import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_metadata.dart';
import 'epub_navigation_label.dart';

class EpubNavigationPoint {
  String? id;
  String? classs;
  String? playOrder;
  List<EpubNavigationLabel>? navigationLabels;
  EpubNavigationContent? content;
  List<EpubNavigationPoint>? childNavigationPoints;

  @override
  int get hashCode {
    var objects = [
      id.hashCode,
      classs.hashCode,
      playOrder.hashCode,
      content.hashCode,
      ...navigationLabels!.map((label) => label.hashCode),
      ...childNavigationPoints!.map((point) => point.hashCode)
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigationPoint?;
    if (otherAs == null) {
      return false;
    }

    if (!collections.listsEqual(navigationLabels, otherAs.navigationLabels)) {
      return false;
    }

    if (!collections.listsEqual(
        childNavigationPoints, otherAs.childNavigationPoints)) return false;

    return id == otherAs.id &&
        classs == otherAs.classs &&
        playOrder == otherAs.playOrder &&
        content == otherAs.content;
  }

  @override
  String toString() {
    return 'Id: $id, Content.Source: ${content!.source}';
  }
}
