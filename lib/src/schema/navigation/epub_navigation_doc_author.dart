import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

class EpubNavigationDocAuthor {
  List<String>? authors;

  EpubNavigationDocAuthor() {
    authors = <String>[];
  }

  @override
  int get hashCode {
    var objects = [...authors!.map((author) => author.hashCode)];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigationDocAuthor?;
    if (otherAs == null) return false;

    return collections.listsEqual(authors, otherAs.authors);
  }
}
