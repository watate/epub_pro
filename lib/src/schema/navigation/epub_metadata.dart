import 'package:quiver/core.dart';

class EpubNavigationContent {
  String? id;
  String? source;

  @override
  int get hashCode => hash2(id.hashCode, source.hashCode);

  @override
  bool operator ==(other) {
    if (other is! EpubNavigationContent) {
      return false;
    }
    return id == other.id && source == other.source;
  }

  @override
  String toString() {
    return 'Source: $source';
  }
}
