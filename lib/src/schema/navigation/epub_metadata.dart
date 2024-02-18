// ignore_for_file: public_member_api_docs, sort_constructors_first

class EpubNavigationContent {
  final String? id;
  final String? source;

  const EpubNavigationContent({
    this.id,
    this.source,
  });

  @override
  int get hashCode => id.hashCode ^ source.hashCode;

  @override
  bool operator ==(covariant EpubNavigationContent other) {
    if (identical(this, other)) return true;

    return other.id == id && other.source == source;
  }

  @override
  String toString() {
    return 'Source: $source';
  }
}
