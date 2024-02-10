import 'package:quiver/core.dart';

class EpubGuideReference {
  String? type;
  String? title;
  String? href;

  @override
  int get hashCode => hash3(type.hashCode, title.hashCode, href.hashCode);

  @override
  bool operator ==(other) {
    var otherAs = other as EpubGuideReference?;
    if (otherAs == null) {
      return false;
    }

    return type == otherAs.type &&
        title == otherAs.title &&
        href == otherAs.href;
  }

  @override
  String toString() {
    return 'Type: $type, Href: $href';
  }
}
