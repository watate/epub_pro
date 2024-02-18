// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

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
    return head.hashCode ^
        docTitle.hashCode ^
        const DeepCollectionEquality().hash(docAuthors) ^
        navMap.hashCode ^
        pageList.hashCode ^
        const DeepCollectionEquality().hash(navLists);
  }

  @override
  bool operator ==(covariant EpubNavigation other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.head == head &&
        other.docTitle == docTitle &&
        listEquals(other.docAuthors, docAuthors) &&
        other.navMap == navMap &&
        other.pageList == pageList &&
        listEquals(other.navLists, navLists);
  }
}
