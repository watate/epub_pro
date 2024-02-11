import 'package:collection/collection.dart';

import 'epub_manifest_item.dart';

class EpubManifest {
  final List<EpubManifestItem> items;

  const EpubManifest({
    this.items = const <EpubManifestItem>[],
  });

  @override
  int get hashCode => const DeepCollectionEquality().hash(items);

  @override
  bool operator ==(covariant EpubManifest other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.items, items);
  }
}
