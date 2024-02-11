import 'package:collection/collection.dart';

import 'epub_metadata.dart';
import 'epub_navigation_label.dart';

class EpubNavigationTarget {
  final String? id;
  final String? classs;
  final String? value;
  final String? playOrder;
  final List<EpubNavigationLabel> navigationLabels;
  final EpubNavigationContent? content;

  const EpubNavigationTarget({
    this.id,
    this.classs,
    this.value,
    this.playOrder,
    this.navigationLabels = const <EpubNavigationLabel>[],
    this.content,
  });

  @override
  int get hashCode {
    return id.hashCode ^
        classs.hashCode ^
        value.hashCode ^
        playOrder.hashCode ^
        const DeepCollectionEquality().hash(navigationLabels) ^
        content.hashCode;
  }

  @override
  bool operator ==(covariant EpubNavigationTarget other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        other.classs == classs &&
        other.value == value &&
        other.playOrder == playOrder &&
        listEquals(other.navigationLabels, navigationLabels) &&
        other.content == content;
  }
}
