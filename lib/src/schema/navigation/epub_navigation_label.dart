// ignore_for_file: public_member_api_docs, sort_constructors_first
class EpubNavigationLabel {
  final String? text;

  const EpubNavigationLabel({
    this.text,
  });

  @override
  int get hashCode => text.hashCode;

  @override
  bool operator ==(covariant EpubNavigationLabel other) {
    if (identical(this, other)) return true;

    return other.text == text;
  }

  @override
  String toString() => '$text';
}
