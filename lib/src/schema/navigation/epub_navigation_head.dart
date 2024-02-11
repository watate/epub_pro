import 'package:collection/collection.dart';

import 'epub_navigation_head_meta.dart';

class EpubNavigationHead {
  final List<EpubNavigationHeadMeta> metadata;

  const EpubNavigationHead({
    this.metadata = const <EpubNavigationHeadMeta>[],
  });

  @override
  int get hashCode => const DeepCollectionEquality().hash(metadata);

  @override
  bool operator ==(covariant EpubNavigationHead other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.metadata, metadata);
  }
}
