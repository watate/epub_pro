import 'package:collection/collection.dart';

import 'epub_navigation_page_target.dart';

class EpubNavigationPageList {
  final List<EpubNavigationPageTarget> targets;

  const EpubNavigationPageList({
    this.targets = const <EpubNavigationPageTarget>[],
  });

  @override
  int get hashCode => const DeepCollectionEquality().hash(targets);

  @override
  bool operator ==(covariant EpubNavigationPageList other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.targets, targets);
  }
}
