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
          'EPUB parsing error: TOC item $tocId not found in EPUB manifest.',
        );
      }

      _tocFileEntryPath =
          ZipPathUtils.combine(contentDirectoryPath, tocManifestItem.href);
      var tocFileEntry = epubArchive.files.cast<ArchiveFile?>().firstWhere(
          (ArchiveFile? file) =>
              file!.name.toLowerCase() == _tocFileEntryPath!.toLowerCase(),
          orElse: () => null);
      if (tocFileEntry == null) {
        throw Exception(
          'EPUB parsing error: TOC file $_tocFileEntryPath not found in archive.',
        );
      }

      var containerDocument = xml.XmlDocument.parse(
        convert.utf8.decode(tocFileEntry.content),
      );

      var ncxNamespace = 'http://www.daisy.org/z3986/2005/ncx/';
      var ncxNode = containerDocument
          .findAllElements('ncx', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere(
            (xml.XmlElement? elem) => elem != null,
            orElse: () => null,
          );

      if (ncxNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain ncx element.');
      }

      var headNode = ncxNode
          .findAllElements('head', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere(
            (xml.XmlElement? elem) => elem != null,
            orElse: () => null,
          );

      if (headNode == null) {
        throw Exception(
          'EPUB parsing error: TOC file does not contain head element.',
        );
      }

      final navigationHead = readNavigationHead(headNode);

      final docTitleNode = ncxNode
          .findElements('docTitle', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere(
            (xml.XmlElement? elem) => elem != null,
            orElse: () => null,
          );

      if (docTitleNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain docTitle element.');
      }

      final navigationDocTitle = readNavigationDocTitle(docTitleNode);
      final docAuthors = <EpubNavigationDocAuthor>[];
      ncxNode.findElements('docAuthor', namespace: ncxNamespace).forEach(
        (xml.XmlElement docAuthorNode) {
          var navigationDocAuthor = readNavigationDocAuthor(docAuthorNode);
          docAuthors.add(navigationDocAuthor);
        },
      );

      var navMapNode = ncxNode
          .findElements('navMap', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (navMapNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain navMap element.');
      }

      final navMap = readNavigationMap(navMapNode);
      var pageListNode = ncxNode
          .findElements('pageList', namespace: ncxNamespace)
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      final pageList = switch (pageListNode) {
        xml.XmlElement element => readNavigationPageList(element),
        null => null,
      };

      final navLists = <EpubNavigationList>[];
      ncxNode.findElements('navList', namespace: ncxNamespace).forEach(
        (xml.XmlElement navigationListNode) {
          final navigationList = readNavigationList(navigationListNode);
          navLists.add(navigationList);
        },
      );

      return EpubNavigation(
        head: navigationHead,
        docTitle: navigationDocTitle,
        docAuthors: docAuthors,
        navMap: navMap,
        pageList: pageList,
        navLists: navLists,
      );
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
      final tocFileEntry = epubArchive.files.cast<ArchiveFile?>().firstWhere(
            (ArchiveFile? file) =>
                file!.name.toLowerCase() == _tocFileEntryPath!.toLowerCase(),
            orElse: () => null,
          );
      if (tocFileEntry == null) {
        throw Exception(
          'EPUB parsing error: TOC file $_tocFileEntryPath not found in archive.',
        );
      }
      //Get relative toc file path
      _tocFileEntryPath =
          '${((_tocFileEntryPath!.split('/')..removeLast())..removeAt(0)).join('/')}/';

      var containerDocument =
          xml.XmlDocument.parse(convert.utf8.decode(tocFileEntry.content));

      final headNode = containerDocument
          .findAllElements('head')
          .cast<xml.XmlElement?>()
          .firstWhere(
            (xml.XmlElement? elem) => elem != null,
            orElse: () => null,
          );
      if (headNode == null) {
        throw Exception(
            'EPUB parsing error: TOC file does not contain head element.');
      }

      final titles = package.metadata!.titles ?? <String>[];
      final docTitle = EpubNavigationDocTitle(titles: titles);

      final navNode = containerDocument
          .findAllElements('nav')
          .cast<xml.XmlElement?>()
          .firstWhere((xml.XmlElement? elem) => elem != null,
              orElse: () => null);
      if (navNode == null) {
        throw Exception(
          'EPUB parsing error: TOC file does not contain head element.',
        );
      }
      final navMapNode = navNode.findElements('ol').single;

      final navMap = readNavigationMapV3(navMapNode);

      //TODO : Implement pagesLists
//      xml.XmlElement pageListNode = ncxNode
//          .findElements("pageList", namespace: ncxNamespace)
//          .firstWhere((xml.XmlElement elem) => elem != null,
//          orElse: () => null);
//      if (pageListNode != null) {
//        EpubNavigationPageList pageList = readNavigationPageList(pageListNode);
//        result.PageList = pageList;
//      }
      return EpubNavigation(
        docTitle: docTitle,
        navMap: navMap,
      );
    }
  }

  static EpubNavigationContent readNavigationContent(
    xml.XmlElement navigationContentNode,
  ) {
    String? id, source;

    for (final attribute in navigationContentNode.attributes) {
      var attributeValue = attribute.value;
      switch (attribute.name.local.toLowerCase()) {
        case 'id':
          id = attributeValue;
        case 'src':
          source = attributeValue;
      }
    }
    if (source == null || source.isEmpty) {
      throw Exception(
        'Incorrect EPUB navigation content: content source is missing.',
      );
    }

    return EpubNavigationContent(
      id: id,
      source: source,
    );
  }

  static EpubNavigationContent readNavigationContentV3(
    xml.XmlElement navigationContentNode,
  ) {
    String? id, source;

    for (final attribute in navigationContentNode.attributes) {
      var attributeValue = attribute.value;

      switch (attribute.name.local.toLowerCase()) {
        case 'id':
          id = attributeValue;
        case 'href':
          if (_tocFileEntryPath!.length < 2 ||
              attributeValue.startsWith(_tocFileEntryPath!)) {
            source = attributeValue;
          } else {
            source = path.normalize(_tocFileEntryPath! + attributeValue);
          }
      }
    }
    // element with span, the content will be null;
    // if (result.Source == null || result.Source!.isEmpty) {
    //   throw Exception(
    //       'Incorrect EPUB navigation content: content source is missing.');
    // }
    return EpubNavigationContent(
      id: id,
      source: source,
    );
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
    final authors = <String>[];
    docAuthorNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement textNode) {
        if (textNode.name.local.toLowerCase() == 'text' &&
            textNode.value != null) {
          authors.add(textNode.value!);
        }
      },
    );
    return EpubNavigationDocAuthor(authors: authors);
  }

  static EpubNavigationDocTitle readNavigationDocTitle(
    xml.XmlElement docTitleNode,
  ) {
    final titles = <String>[];
    docTitleNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement textNode) {
        if (textNode.name.local.toLowerCase() == 'text' &&
            textNode.value != null) {
          titles.add(textNode.value!);
        }
      },
    );
    return EpubNavigationDocTitle(titles: titles);
  }

  static EpubNavigationHead readNavigationHead(xml.XmlElement headNode) {
    var result = EpubNavigationHead();
    result.metadata = <EpubNavigationHeadMeta>[];

    headNode.children.whereType<xml.XmlElement>().forEach(
      (xml.XmlElement metaNode) {
        if (metaNode.name.local.toLowerCase() == 'meta') {
          String? name, content, scheme;

          for (final metaNodeAttribute in metaNode.attributes) {
            final attributeValue = metaNodeAttribute.value;

            switch (metaNodeAttribute.name.local.toLowerCase()) {
              case 'name':
                name = attributeValue;
              case 'content':
                content = attributeValue;
              case 'scheme':
                scheme = attributeValue;
            }
          }

          if (name == null || name.isEmpty) {
            throw Exception(
              'Incorrect EPUB navigation meta: meta name is missing.',
            );
          }
          if (content == null) {
            throw Exception(
              'Incorrect EPUB navigation meta: meta content is missing.',
            );
          }

          final meta = EpubNavigationHeadMeta(
            name: name,
            content: content,
            scheme: scheme,
          );

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
