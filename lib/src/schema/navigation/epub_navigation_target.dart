import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_metadata.dart';
import 'epub_navigation_label.dart';

class EpubNavigationTarget {
  String? id;
  String? classs;
  String? value;
  String? playOrder;
  List<EpubNavigationLabel>? navigationLabels;
  EpubNavigationContent? content;

  @override
  int get hashCode {
    var objects = [
      id.hashCode,
      classs.hashCode,
      value.hashCode,
      playOrder.hashCode,
      content.hashCode,
      ...navigationLabels!.map((label) => label.hashCode)
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigationTarget?;
    if (otherAs == null) return false;

    if (!(id == otherAs.id &&
        classs == otherAs.classs &&
        value == otherAs.value &&
        playOrder == otherAs.playOrder &&
        content == otherAs.content)) {
      return false;
    }

    return collections.listsEqual(navigationLabels, otherAs.navigationLabels);
  }
}
