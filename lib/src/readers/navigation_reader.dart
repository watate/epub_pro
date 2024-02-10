import 'dart:async';

import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:epubx/src/schema/opf/epub_version.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path/path.dart' as path;

import '../schema/navigation/epub_metadata.dart';
import '../schema/navigation/epub_navigation.dart';
import '../schema/navigation/epub_navigation_doc_author.dart';
import '../schema/navigation/epub_navigation_doc_title.dart';
import '../schema/navigation/epub_navigation_head.dart';
import '../schema/navigation/epub_navigation_head_meta.dart';
import '../schema/navigation/epub_navigation_label.dart';
import '../schema/navigation/epub_navigation_list.dart';
import '../schema/navigation/epub_navigation_map.dart';
import '../schema/navigation/epub_navigation_page_list.dart';
import '../schema/navigation/epub_navigation_page_target.dart';
import '../schema/navigation/epub_navigation_page_target_type.dart';
import '../schema/navigation/epub_navigation_point.dart';
import '../schema/navigation/epub_navigation_target.dart';
import '../schema/opf/epub_manifest_item.dart';
import '../schema/opf/epub_package.dart';
import '../utils/enum_from_string.dart';
import '../utils/zip_path_utils.dart';

// ignore: omit_local_variable_types

class NavigationReader {
  static String? _tocFileEntryPath;

  static Future<EpubNavigation> readNavigation(Archive epubArchive,
      String contentDirectoryPath, EpubPackage package) async {
    var result = EpubNavigation();
    if (package.version == EpubVersion.epub2) {
      var tocId = package.spine!.tableOfContents;
      if (tocId == null || tocId.isEmpty) {
        throw Exception('EPUB parsing error: TOC ID is empty.');
      }

      var tocManifestItem =
          package.manifest!.items!.cast<EpubManifestItem?>().firstWhere(
                (EpubManifestItem? item) =>
                    item!.id!.toLowerCase() == tocId.toLowerCase(),
                orElse: () => null,
              );
      if (tocManifestItem == null) {
        throw Exception(
            'EPUB parsing error: TOC item $tocId not found in EPUB manifest.');
      }

      _tocFileEntryPath =
          ZipPathUtils.combine(contentDirectoryPath, tocManifestItem.href);
      var tocFileEntry = epubArchive.files.cast<ArchiveFile?>().firstWhere(
          (ArchiveFile? file) =>
              file!.name.toLowerCase() == _tocFileEntryPath!.toLowerCase(),
          orElse: () => null);
      if (tocFileEntry == null) {
        throw Exception(
            'EPUB parsing error: TOC file $_tocFileEntryPath not found in archive.');
      }

      var containerDocument =
          xml.XmlDocument.parse(convert.utf8.decode(tocFileEntry.content));

      var ncxNamespace = 'http://www.daisy.org/z3986/2005/ncx/';
      var ncxNode = containerDocument
          .findAllElements('ncx', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (ncxNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain ncx element.');
      }

      var headNode = ncxNode
          .findAllElements('head', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (headNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain head element.');
      }

      var navigationHead = readNavigationHead(headNode);
      result.head = navigationHead;
      var docTitleNode = ncxNode
          .findElements('docTitle', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (docTitleNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain docTitle element.');
      }

      var navigationDocTitle = readNavigationDocTitle(docTitleNode);
      result.docTitle = navigationDocTitle;
      result.docAuthors = <EpubNavigationDocAuthor>[];
      ncxNode
          .findElements('docAuthor', namespace: ncxNamespace)
          .forEach((xml.XmlElement docAuthorNode) {
        var navigationDocAuthor = readNavigationDocAuthor(docAuthorNode);
        result.docAuthors!.add(navigationDocAuthor);
      });

      var navMapNode = ncxNode
          .findElements('navMap', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (navMapNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain navMap element.');
      }

      var navMap = readNavigationMap(navMapNode);
      result.navMap = navMap;
      var pageListNode = ncxNode
          .findElements('pageList', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (pageListNode != null) {
        var pageList = readNavigationPageList(pageListNode);
        result.pageList = pageList;
      }

      result.navLists = <EpubNavigationList>[];
      ncxNode
          .findElements('navList', namespace: ncxNamespace)
          .forEach((xml.XmlElement navigationListNode) {
        var navigationList = readNavigationList(navigationListNode);
        result.navLists!.add(navigationList);
      });
    } else {
      //Version 3

      var tocManifestItem = package.manifest!.items!
          .cast<EpubManifestItem?>()
          .firstWhere((element) => element!.properties == 'nav',
              orElse: () => null);
      if (tocManifestItem == null) {
        throw Exception(
            'EPUB parsing error: TOC item, not found in EPUB manifest.');
      }

      _tocFileEntryPath =
          ZipPathUtils.combine(contentDirectoryPath, tocManifestItem.href);
      var tocFileEntry = epubArchive.files.cast<ArchiveFile?>().firstWhere(
          (ArchiveFile? file) =>
              file!.name.toLowerCase() == _tocFileEntryPath!.toLowerCase(),
          orElse: () => null);
      if (tocFileEntry == null) {
        throw Exception(
            'EPUB parsing error: TOC file $_tocFileEntryPath not found in archive.');
      }
      //Get relative toc file path
      _tocFileEntryPath =
          '${((_tocFileEntryPath!.split('/')..removeLast())..removeAt(0)).join('/')}/';

      var containerDocument =
          xml.XmlDocument.parse(convert.utf8.decode(tocFileEntry.content));

      var headNode = containerDocument
          .findAllElements('head')
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (headNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain head element.');
      }

      result.docTitle = EpubNavigationDocTitle();
      result.docTitle!.titles = package.metadata!.titles;
//      result.DocTitle.Titles.add(headNode.findAllElements("title").firstWhere((element) =>  element != null, orElse: () => null).text.trim());

      result.docAuthors = <EpubNavigationDocAuthor>[];

      var navNode = containerDocument
          .findAllElements('nav')
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (navNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain head element.');
      }
      var navMapNode = navNode.findElements('ol').single;

      var navMap = readNavigationMapV3(navMapNode);
      result.navMap = navMap;

      //TODO : Implement pagesLists
//      xml.XmlElement pageListNode = ncxNode
//          .findElements("pageList", namespace: ncxNamespace)
//          .firstWhere((xml.XmlElement elem) => elem != null,
//          orElse: () => null);
//      if (pageListNode != null) {
//        EpubNavigationPageList pageList = readNavigationPageList(pageListNode);
//        result.PageList = pageList;
//      }
    }

    return result;
  }

  static EpubNavigationContent readNavigationContent(
    xml.XmlElement navigationContentNode,
  ) {
    var result = EpubNavigationContent();
    for (final navigationContentNodeAttribute
        in navigationContentNode.attributes) {
      var attributeValue = navigationContentNodeAttribute.value;
      switch (navigationContentNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
        case 'src':
          result.source = attributeValue;
      }
    }
    if (result.source == null || result.source!.isEmpty) {
      throw Exception(
          'Incorrect EPUB navigation content: content source is missing.');
    }

    return result;
  }

  static EpubNavigationContent readNavigationContentV3(
      xml.XmlElement navigationContentNode) {
    var result = EpubNavigationContent();
    for (var navigationContentNodeAttribute
        in navigationContentNode.attributes) {
      var attributeValue = navigationContentNodeAttribute.value;
      switch (navigationContentNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
          break;
        case 'href':
          if (_tocFileEntryPath!.length < 2 ||
              attributeValue.startsWith(_tocFileEntryPath!)) {
            result.source = attributeValue;
          } else {
            result.source = path.normalize(_tocFileEntryPath! + attributeValue);
          }

          break;
      }
    }
    // element with span, the content will be null;
    // if (result.Source == null || result.Source!.isEmpty) {
    //   throw Exception(
    //       'Incorrect EPUB navigation content: content source is missing.');
    // }
    return result;
  }

  static String extractContentPath(String tocFileEntryPath, String ref) {
    if (!tocFileEntryPath.endsWith('/')) {
      tocFileEntryPath = '$tocFileEntryPath/';
    }
    var r = tocFileEntryPath + ref;
    r = r.replaceAll('/./', '/');
    r = r.replaceAll(RegExp(r'/[^/]+/\.\./'), '/');
    r = r.replaceAll(RegExp(r'^[^/]+/\.\./'), '');
    return r;
  }

  static EpubNavigationDocAuthor readNavigationDocAuthor(
    xml.XmlElement docAuthorNode,
  ) {
    var result = EpubNavigationDocAuthor();
    result.authors = <String>[];
    docAuthorNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement textNode) {
        if (textNode.name.local.toLowerCase() == 'text' &&
            textNode.value != null) {
          result.authors!.add(textNode.value!);
        }
      },
    );
    return result;
  }

  static EpubNavigationDocTitle readNavigationDocTitle(
    xml.XmlElement docTitleNode,
  ) {
    var result = EpubNavigationDocTitle();
    result.titles = <String>[];
    docTitleNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement textNode) {
        if (textNode.name.local.toLowerCase() == 'text' &&
            textNode.value != null) {
          result.titles!.add(textNode.value!);
        }
      },
    );
    return result;
  }

  static EpubNavigationHead readNavigationHead(xml.XmlElement headNode) {
    var result = EpubNavigationHead();
    result.metadata = <EpubNavigationHeadMeta>[];

    headNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement metaNode) {
        if (metaNode.name.local.toLowerCase() == 'meta') {
          var meta = EpubNavigationHeadMeta();
          for (var metaNodeAttribute in metaNode.attributes) {
            var attributeValue = metaNodeAttribute.value;
            switch (metaNodeAttribute.name.local.toLowerCase()) {
              case 'name':
                meta.name = attributeValue;
              case 'content':
                meta.content = attributeValue;
              case 'scheme':
                meta.scheme = attributeValue;
            }
          }

          if (meta.name == null || meta.name!.isEmpty) {
            throw Exception(
                'Incorrect EPUB navigation meta: meta name is missing.');
          }
          if (meta.content == null) {
            throw Exception(
                'Incorrect EPUB navigation meta: meta content is missing.');
          }

          result.metadata!.add(meta);
        }
      },
    );
    return result;
  }

  static EpubNavigationLabel readNavigationLabel(
      xml.XmlElement navigationLabelNode) {
    var result = EpubNavigationLabel();

    var navigationLabelTextNode = navigationLabelNode
        .findElements('text', namespace: navigationLabelNode.name.namespaceUri)
        .firstWhereOrNull((xml.XmlElement? elem) => elem != null);
    if (navigationLabelTextNode == null) {
      throw Exception(
          'Incorrect EPUB navigation label: label text element is missing.');
    }

    result.text = navigationLabelTextNode.value;

    return result;
  }

  static EpubNavigationLabel readNavigationLabelV3(
      xml.XmlElement navigationLabelNode) {
    var result = EpubNavigationLabel();
    result.text = navigationLabelNode.value?.trim();
    return result;
  }

  static EpubNavigationList readNavigationList(
      xml.XmlElement navigationListNode) {
    var result = EpubNavigationList();
    for (var navigationListNodeAttribute in navigationListNode.attributes) {
      var attributeValue = navigationListNodeAttribute.value;
      switch (navigationListNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
          break;
        case 'class':
          result.classs = attributeValue;
          break;
      }
    }
    navigationListNode.children
        .whereType<xml.XmlElement>()
        .forEach((xml.XmlElement navigationListChildNode) {
      switch (navigationListChildNode.name.local.toLowerCase()) {
        case 'navlabel':
          var navigationLabel = readNavigationLabel(navigationListChildNode);
          result.navigationLabels!.add(navigationLabel);
          break;
        case 'navtarget':
          var navigationTarget = readNavigationTarget(navigationListChildNode);
          result.navigationTargets!.add(navigationTarget);
          break;
      }
    });
    // if (result.NavigationLabels!.isEmpty) {
    //   throw Exception(
    //       'Incorrect EPUB navigation page target: at least one navLabel element is required.');
    // }
    return result;
  }

  static EpubNavigationMap readNavigationMap(xml.XmlElement navigationMapNode) {
    var result = EpubNavigationMap();
    result.points = <EpubNavigationPoint>[];
    navigationMapNode.children
        .whereType<xml.XmlElement>()
        .forEach((xml.XmlElement navigationPointNode) {
      if (navigationPointNode.name.local.toLowerCase() == 'navpoint') {
        var navigationPoint = readNavigationPoint(navigationPointNode);
        result.points!.add(navigationPoint);
      }
    });
    return result;
  }

  static EpubNavigationMap readNavigationMapV3(
      xml.XmlElement navigationMapNode) {
    var result = EpubNavigationMap();
    result.points = <EpubNavigationPoint>[];
    navigationMapNode.children
        .whereType<xml.XmlElement>()
        .forEach((xml.XmlElement navigationPointNode) {
      if (navigationPointNode.name.local.toLowerCase() == 'li') {
        var navigationPoint = readNavigationPointV3(navigationPointNode);
        result.points!.add(navigationPoint);
      }
    });
    return result;
  }

  static EpubNavigationPageList readNavigationPageList(
      xml.XmlElement navigationPageListNode) {
    var result = EpubNavigationPageList();
    result.targets = <EpubNavigationPageTarget>[];
    navigationPageListNode.children
        .whereType<xml.XmlElement>()
        .forEach((xml.XmlElement pageTargetNode) {
      if (pageTargetNode.name.local == 'pageTarget') {
        var pageTarget = readNavigationPageTarget(pageTargetNode);
        result.targets!.add(pageTarget);
      }
    });

    return result;
  }

  static EpubNavigationPageTarget readNavigationPageTarget(
      xml.XmlElement navigationPageTargetNode) {
    var result = EpubNavigationPageTarget();
    result.navigationLabels = <EpubNavigationLabel>[];
    for (var navigationPageTargetNodeAttribute
        in navigationPageTargetNode.attributes) {
      var attributeValue = navigationPageTargetNodeAttribute.value;
      switch (navigationPageTargetNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
          break;
        case 'value':
          result.value = attributeValue;
          break;
        case 'type':
          var converter = EnumFromString<EpubNavigationPageTargetType>(
              EpubNavigationPageTargetType.values);
          var type = converter.get(attributeValue);
          result.type = type;
          break;
        case 'class':
          result.classs = attributeValue;
          break;
        case 'playorder':
          result.playOrder = attributeValue;
          break;
      }
    }
    if (result.type == EpubNavigationPageTargetType.undefined) {
      throw Exception(
          'Incorrect EPUB navigation page target: page target type is missing.');
    }

    navigationPageTargetNode.children
        .whereType<xml.XmlElement>()
        .forEach((xml.XmlElement navigationPageTargetChildNode) {
      switch (navigationPageTargetChildNode.name.local.toLowerCase()) {
        case 'navlabel':
          var navigationLabel =
              readNavigationLabel(navigationPageTargetChildNode);
          result.navigationLabels!.add(navigationLabel);
          break;
        case 'content':
          var content = readNavigationContent(navigationPageTargetChildNode);
          result.content = content;
          break;
      }
    });
    if (result.navigationLabels!.isEmpty) {
      throw Exception(
          'Incorrect EPUB navigation page target: at least one navLabel element is required.');
    }

    return result;
  }

  static EpubNavigationPoint readNavigationPoint(
      xml.XmlElement navigationPointNode) {
    var result = EpubNavigationPoint();
    for (var navigationPointNodeAttribute in navigationPointNode.attributes) {
      var attributeValue = navigationPointNodeAttribute.value;
      switch (navigationPointNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
          break;
        case 'class':
          result.classs = attributeValue;
          break;
        case 'playorder':
          result.playOrder = attributeValue;
          break;
      }
    }
    if (result.id == null || result.id!.isEmpty) {
      throw Exception('Incorrect EPUB navigation point: point ID is missing.');
    }

    result.navigationLabels = <EpubNavigationLabel>[];
    result.childNavigationPoints = <EpubNavigationPoint>[];
    navigationPointNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement navigationPointChildNode) {
        switch (navigationPointChildNode.name.local.toLowerCase()) {
          case 'navlabel':
            var navigationLabel = readNavigationLabel(navigationPointChildNode);
            result.navigationLabels!.add(navigationLabel);
            break;
          case 'content':
            var content = readNavigationContent(navigationPointChildNode);
            result.content = content;
            break;
          case 'navpoint':
            var childNavigationPoint =
                readNavigationPoint(navigationPointChildNode);
            result.childNavigationPoints!.add(childNavigationPoint);
            break;
        }
      },
    );

    if (result.navigationLabels!.isEmpty) {
      throw Exception(
          'EPUB parsing error: navigation point ${result.id} should contain at least one navigation label.');
    }
    if (result.content == null) {
      throw Exception(
          'EPUB parsing error: navigation point ${result.id} should contain content.');
    }

    return result;
  }

  static EpubNavigationPoint readNavigationPointV3(
      xml.XmlElement navigationPointNode) {
    var result = EpubNavigationPoint();

    result.navigationLabels = <EpubNavigationLabel>[];
    result.childNavigationPoints = <EpubNavigationPoint>[];
    navigationPointNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement navigationPointChildNode) {
        switch (navigationPointChildNode.name.local.toLowerCase()) {
          case 'a':
          case 'span':
            var navigationLabel =
                readNavigationLabelV3(navigationPointChildNode);
            result.navigationLabels!.add(navigationLabel);
            var content = readNavigationContentV3(navigationPointChildNode);
            result.content = content;
            break;
          case 'ol':
            for (var point
                in readNavigationMapV3(navigationPointChildNode).points!) {
              result.childNavigationPoints!.add(point);
            }
            break;
        }
      },
    );

    if (result.navigationLabels!.isEmpty) {
      throw Exception(
          'EPUB parsing error: navigation point ${result.id} should contain at least one navigation label.');
    }
    if (result.content == null) {
      throw Exception(
          'EPUB parsing error: navigation point ${result.id} should contain content.');
    }

    return result;
  }

  static EpubNavigationTarget readNavigationTarget(
      xml.XmlElement navigationTargetNode) {
    var result = EpubNavigationTarget();
    for (var navigationPageTargetNodeAttribute
        in navigationTargetNode.attributes) {
      var attributeValue = navigationPageTargetNodeAttribute.value;
      switch (navigationPageTargetNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
        case 'value':
          result.value = attributeValue;
        case 'class':
          result.classs = attributeValue;
        case 'playorder':
          result.playOrder = attributeValue;
      }
    }
    if (result.id == null || result.id!.isEmpty) {
      throw Exception(
          'Incorrect EPUB navigation target: navigation target ID is missing.');
    }

    navigationTargetNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement navigationTargetChildNode) {
        switch (navigationTargetChildNode.name.local.toLowerCase()) {
          case 'navlabel':
            var navigationLabel =
                readNavigationLabel(navigationTargetChildNode);
            result.navigationLabels!.add(navigationLabel);
          case 'content':
            var content = readNavigationContent(navigationTargetChildNode);
            result.content = content;
        }
      },
    );
    if (result.navigationLabels!.isEmpty) {
      throw Exception(
        'Incorrect EPUB navigation target: at least one navLabel element is required.',
      );
    }

    return result;
  }
}
