// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

import 'epub_metadata.dart';
import 'epub_navigation_label.dart';

class EpubNavigationPoint {
  final String? id;
  final String? classs;
  final String? playOrder;
  final List<EpubNavigationLabel> navigationLabels;
  final EpubNavigationContent? content;
  final List<EpubNavigationPoint> childNavigationPoints;

  const EpubNavigationPoint({
    this.id,
    this.classs,
    this.playOrder,
    this.navigationLabels = const <EpubNavigationLabel>[],
    this.content,
    this.childNavigationPoints = const <EpubNavigationPoint>[],
  });

  @override
  int get hashCode {
    return id.hashCode ^
        classs.hashCode ^
        playOrder.hashCode ^
        const DeepCollectionEquality().hash(navigationLabels) ^
        content.hashCode ^
        const DeepCollectionEquality().hash(childNavigationPoints);
  }

  @override
  bool operator ==(covariant EpubNavigationPoint other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        other.classs == classs &&
        other.playOrder == playOrder &&
        listEquals(other.navigationLabels, navigationLabels) &&
        other.content == content &&
        listEquals(other.childNavigationPoints, childNavigationPoints);
  }

  @override
  String toString() {
    return 'Id: $id, Content.Source: ${content?.source}';
  }
}
