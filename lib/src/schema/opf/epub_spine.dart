import 'package:collection/collection.dart';

import 'epub_spine_item_ref.dart';

class EpubSpine {
  final String? tableOfContents;
  final List<EpubSpineItemRef> items;
  final bool ltr;

  const EpubSpine({
    this.tableOfContents,
    this.items = const <EpubSpineItemRef>[],
    required this.ltr,
  });

  @override
  int get hashCode =>
      tableOfContents.hashCode ^
      const DeepCollectionEquality().hash(items) ^
      ltr.hashCode;

  @override
  bool operator ==(covariant EpubSpine other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.tableOfContents == tableOfContents &&
        listEquals(other.items, items) &&
        other.ltr == ltr;
  }
}
