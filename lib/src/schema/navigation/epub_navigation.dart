import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_navigation_doc_author.dart';
import 'epub_navigation_doc_title.dart';
import 'epub_navigation_head.dart';
import 'epub_navigation_list.dart';
import 'epub_navigation_map.dart';
import 'epub_navigation_page_list.dart';

class EpubNavigation {
  EpubNavigationHead? head;
  EpubNavigationDocTitle? docTitle;
  List<EpubNavigationDocAuthor>? docAuthors;
  EpubNavigationMap? navMap;
  EpubNavigationPageList? pageList;
  List<EpubNavigationList>? navLists;

  @override
  int get hashCode {
    var objects = [
      head.hashCode,
      docTitle.hashCode,
      navMap.hashCode,
      pageList.hashCode,
      ...docAuthors?.map((author) => author.hashCode) ?? [0],
      ...navLists?.map((navList) => navList.hashCode) ?? [0]
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
