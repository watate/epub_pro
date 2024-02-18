class EpubGuideReference {
  final String? type;
  final String? title;
  final String? href;

  const EpubGuideReference({
    this.type,
    this.title,
    this.href,
  });

  @override
  int get hashCode => type.hashCode ^ title.hashCode ^ href.hashCode;

  @override
  bool operator ==(covariant EpubGuideReference other) {
    if (identical(this, other)) return true;

    return other.type == type && other.title == title && other.href == href;
  }

  @override
  String toString() {
    return 'Type: $type, Href: $href';
  }
}
