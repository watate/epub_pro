class EpubNavigationLabel {
  String? text;

  @override
  int get hashCode => text.hashCode;

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigationLabel?;
    if (otherAs == null) return false;
    return text == otherAs.text;
  }

  @override
  String toString() {
    return text!;
  }
}
