// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

import 'epub_guide_reference.dart';

class EpubGuide {
  final List<EpubGuideReference> items;

  const EpubGuide({
    this.items = const <EpubGuideReference>[],
  });

  @override
  int get hashCode => const DeepCollectionEquality().hash(items);

  @override
  bool operator ==(covariant EpubGuide other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.items, items);
  }
}
