import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_navigation_doc_author.dart';
import 'epub_navigation_doc_title.dart';
import 'epub_navigation_head.dart';
import 'epub_navigation_list.dart';
import 'epub_navigation_map.dart';
import 'epub_navigation_page_list.dart';

class EpubNavigation {
  final EpubNavigationHead? head;
  final EpubNavigationDocTitle? docTitle;
  final List<EpubNavigationDocAuthor> docAuthors;
  final EpubNavigationMap? navMap;
  final EpubNavigationPageList? pageList;
  final List<EpubNavigationList> navLists;

  const EpubNavigation({
    this.head,
    this.docTitle,
    this.docAuthors = const <EpubNavigationDocAuthor>[],
    this.navMap,
    this.pageList,
    this.navLists = const <EpubNavigationList>[],
  });

  @override
  int get hashCode {
    var objects = [
      head.hashCode,
      docTitle.hashCode,
      navMap.hashCode,
      pageList.hashCode,
      ...docAuthors.map((author) => author.hashCode),
      ...navLists.map((navList) => navList.hashCode),
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    var otherAs = other as EpubNavigation?;
    if (otherAs == null) {
      return false;
    }

    if (!collections.listsEqual(docAuthors, otherAs.docAuthors)) {
      return false;
    }
    if (!collections.listsEqual(navLists, otherAs.navLists)) {
      return false;
    }

    return head == otherAs.head &&
        docTitle == otherAs.docTitle &&
        navMap == otherAs.navMap &&
        pageList == otherAs.pageList;
  }
}
