import 'dart:async';

import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:xml/xml.dart';

import '../schema/opf/epub_guide.dart';
import '../schema/opf/epub_guide_reference.dart';
import '../schema/opf/epub_manifest.dart';
import '../schema/opf/epub_manifest_item.dart';
import '../schema/opf/epub_metadata.dart';
import '../schema/opf/epub_metadata_contributor.dart';
import '../schema/opf/epub_metadata_creator.dart';
import '../schema/opf/epub_metadata_date.dart';
import '../schema/opf/epub_metadata_identifier.dart';
import '../schema/opf/epub_metadata_meta.dart';
import '../schema/opf/epub_package.dart';
import '../schema/opf/epub_spine.dart';
import '../schema/opf/epub_spine_item_ref.dart';
import '../schema/opf/epub_version.dart';

class PackageReader {
  static EpubGuide readGuide(XmlElement guideNode) {
    var result = EpubGuide();
    result.items = <EpubGuideReference>[];
    guideNode.children.whereType<XmlElement>().forEach(
      (XmlElement guideReferenceNode) {
        if (guideReferenceNode.name.local.toLowerCase() == 'reference') {
          var guideReference = EpubGuideReference();
          for (var guideReferenceNodeAttribute
              in guideReferenceNode.attributes) {
            var attributeValue = guideReferenceNodeAttribute.value;
            switch (guideReferenceNodeAttribute.name.local.toLowerCase()) {
              case 'type':
                guideReference.type = attributeValue;
              case 'title':
                guideReference.title = attributeValue;
              case 'href':
                guideReference.href = attributeValue;
            }
          }
          if (guideReference.type == null || guideReference.type!.isEmpty) {
            throw Exception('Incorrect EPUB guide: item type is missing');
          }
          if (guideReference.href == null || guideReference.href!.isEmpty) {
            throw Exception('Incorrect EPUB guide: item href is missing');
          }
          result.items!.add(guideReference);
        }
      },
    );
    return result;
  }

  static EpubManifest readManifest(XmlElement manifestNode) {
    var result = EpubManifest();
    result.items = <EpubManifestItem>[];
    manifestNode.children
        .whereType<XmlElement>()
        .forEach((XmlElement manifestItemNode) {
      if (manifestItemNode.name.local.toLowerCase() == 'item') {
        var manifestItem = EpubManifestItem();
        for (var manifestItemNodeAttribute in manifestItemNode.attributes) {
          var attributeValue = manifestItemNodeAttribute.value;
          switch (manifestItemNodeAttribute.name.local.toLowerCase()) {
            case 'id':
              manifestItem.id = attributeValue;

            case 'href':
              manifestItem.href = attributeValue;
            case 'media-type':
              manifestItem.mediaType = attributeValue;
            case 'media-overlay':
              manifestItem.mediaOverlay = attributeValue;
            case 'required-namespace':
              manifestItem.requiredNamespace = attributeValue;
            case 'required-modules':
              manifestItem.requiredModules = attributeValue;
            case 'fallback':
              manifestItem.fallback = attributeValue;
            case 'fallback-style':
              manifestItem.fallbackStyle = attributeValue;
            case 'properties':
              manifestItem.properties = attributeValue;
          }
        }

        if (manifestItem.id == null || manifestItem.id!.isEmpty) {
          throw Exception('Incorrect EPUB manifest: item ID is missing');
        }
        if (manifestItem.href == null || manifestItem.href!.isEmpty) {
          throw Exception('Incorrect EPUB manifest: item href is missing');
        }
        if (manifestItem.mediaType == null || manifestItem.mediaType!.isEmpty) {
          throw Exception(
              'Incorrect EPUB manifest: item media type is missing');
        }
        result.items!.add(manifestItem);
      }
    });
    return result;
  }

  static EpubMetadata readMetadata(
      XmlElement metadataNode, EpubVersion? epubVersion) {
    var result = EpubMetadata();
    result.titles = <String>[];
    result.creators = <EpubMetadataCreator>[];
    result.subjects = <String>[];
    result.publishers = <String>[];
    result.contributors = <EpubMetadataContributor>[];
    result.dates = <EpubMetadataDate>[];
    result.types = <String>[];
    result.formats = <String>[];
    result.identifiers = <EpubMetadataIdentifier>[];
    result.sources = <String>[];
    result.languages = <String>[];
    result.relations = <String>[];
    result.coverages = <String>[];
    result.rights = <String>[];
    result.metaItems = <EpubMetadataMeta>[];
    metadataNode.children.whereType<XmlElement>().forEach(
      (XmlElement metadataItemNode) {
        var innerText = metadataItemNode.value;
        if (innerText == null) return;

        switch (metadataItemNode.name.local.toLowerCase()) {
          case 'title':
            result.titles!.add(innerText);
          case 'creator':
            var creator = readMetadataCreator(metadataItemNode);
            result.creators!.add(creator);
          case 'subject':
            result.subjects!.add(innerText);
          case 'description':
            result.description = innerText;
          case 'publisher':
            result.publishers!.add(innerText);
          case 'contributor':
            var contributor = readMetadataContributor(metadataItemNode);
            result.contributors!.add(contributor);
          case 'date':
            var date = readMetadataDate(metadataItemNode);
            result.dates!.add(date);
          case 'type':
            result.types!.add(innerText);
          case 'format':
            result.formats!.add(innerText);
          case 'identifier':
            var identifier = readMetadataIdentifier(metadataItemNode);
            result.identifiers!.add(identifier);
          case 'source':
            result.sources!.add(innerText);
          case 'language':
            result.languages!.add(innerText);
          case 'relation':
            result.relations!.add(innerText);
          case 'coverage':
            result.coverages!.add(innerText);
          case 'rights':
            result.rights!.add(innerText);
          case 'meta':
            if (epubVersion == EpubVersion.epub2) {
              var meta = readMetadataMetaVersion2(metadataItemNode);
              result.metaItems!.add(meta);
            } else if (epubVersion == EpubVersion.epub3) {
              var meta = readMetadataMetaVersion3(metadataItemNode);
              result.metaItems!.add(meta);
            }
        }
      },
    );
    return result;
  }

  static EpubMetadataContributor readMetadataContributor(
      XmlElement metadataContributorNode) {
    var result = EpubMetadataContributor();
    for (var metadataContributorNodeAttribute
        in metadataContributorNode.attributes) {
      var attributeValue = metadataContributorNodeAttribute.value;
      switch (metadataContributorNodeAttribute.name.local.toLowerCase()) {
        case 'role':
          result.role = attributeValue;
        case 'file-as':
          result.fileAs = attributeValue;
      }
    }
    result.contributor = metadataContributorNode.value;
    return result;
  }

  static EpubMetadataCreator readMetadataCreator(
      XmlElement metadataCreatorNode) {
    var result = EpubMetadataCreator();
    for (var metadataCreatorNodeAttribute in metadataCreatorNode.attributes) {
      var attributeValue = metadataCreatorNodeAttribute.value;
      switch (metadataCreatorNodeAttribute.name.local.toLowerCase()) {
        case 'role':
          result.role = attributeValue;
        case 'file-as':
          result.fileAs = attributeValue;
      }
    }
    result.creator = metadataCreatorNode.value;
    return result;
  }

  static EpubMetadataDate readMetadataDate(XmlElement metadataDateNode) {
    var result = EpubMetadataDate();
    var eventAttribute = metadataDateNode.getAttribute('event',
        namespace: metadataDateNode.name.namespaceUri);
    if (eventAttribute != null && eventAttribute.isNotEmpty) {
      result.event = eventAttribute;
    }
    result.date = metadataDateNode.value;
    return result;
  }

  static EpubMetadataIdentifier readMetadataIdentifier(
      XmlElement metadataIdentifierNode) {
    var result = EpubMetadataIdentifier();
    for (var metadataIdentifierNodeAttribute
        in metadataIdentifierNode.attributes) {
      var attributeValue = metadataIdentifierNodeAttribute.value;
      switch (metadataIdentifierNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
        case 'scheme':
          result.scheme = attributeValue;
      }
    }
    result.identifier = metadataIdentifierNode.value;
    return result;
  }

  static EpubMetadataMeta readMetadataMetaVersion2(
      XmlElement metadataMetaNode) {
    var result = EpubMetadataMeta();
    for (var metadataMetaNodeAttribute in metadataMetaNode.attributes) {
      var attributeValue = metadataMetaNodeAttribute.value;
      switch (metadataMetaNodeAttribute.name.local.toLowerCase()) {
        case 'name':
          result.name = attributeValue;
        case 'content':
          result.content = attributeValue;
      }
    }
    return result;
  }

  static EpubMetadataMeta readMetadataMetaVersion3(
      XmlElement metadataMetaNode) {
    var result = EpubMetadataMeta();
    result.ttributes = {};
    for (var metadataMetaNodeAttribute in metadataMetaNode.attributes) {
      var attributeValue = metadataMetaNodeAttribute.value;
      result.ttributes![metadataMetaNodeAttribute.name.local.toLowerCase()] =
          attributeValue;
      switch (metadataMetaNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.id = attributeValue;
        case 'refines':
          result.refines = attributeValue;
        case 'property':
          result.property = attributeValue;
        case 'scheme':
          result.scheme = attributeValue;
      }
    }
    result.content = metadataMetaNode.value;
    return result;
  }

  static Future<EpubPackage> readPackage(
      Archive epubArchive, String rootFilePath) async {
    var rootFileEntry = epubArchive.files.firstWhereOrNull(
        (ArchiveFile testFile) => testFile.name == rootFilePath);
    if (rootFileEntry == null) {
      throw Exception('EPUB parsing error: root file not found in archive.');
    }
    var containerDocument =
        XmlDocument.parse(convert.utf8.decode(rootFileEntry.content));
    var opfNamespace = 'http://www.idpf.org/2007/opf';
    var packageNode = containerDocument
        .findElements('package', namespace: opfNamespace)
        .firstWhere((XmlElement? elem) => elem != null);
    var result = EpubPackage();
    var epubVersionValue = packageNode.getAttribute('version');
    if (epubVersionValue == '2.0') {
      result.version = EpubVersion.epub2;
    } else if (epubVersionValue == '3.0') {
      result.version = EpubVersion.epub3;
    } else {
      throw Exception('Unsupported EPUB version: $epubVersionValue.');
    }
    var metadataNode = packageNode
        .findElements('metadata', namespace: opfNamespace)
        .cast<XmlElement?>()
        .firstWhere((XmlElement? elem) => elem != null);
    if (metadataNode == null) {
      throw Exception('EPUB parsing error: metadata not found in the package.');
    }
    var metadata = readMetadata(metadataNode, result.version);
    result.metadata = metadata;
    var manifestNode = packageNode
        .findElements('manifest', namespace: opfNamespace)
        .cast<XmlElement?>()
        .firstWhere((XmlElement? elem) => elem != null);
    if (manifestNode == null) {
      throw Exception('EPUB parsing error: manifest not found in the package.');
    }
    var manifest = readManifest(manifestNode);
    result.manifest = manifest;

    var spineNode = packageNode
        .findElements('spine', namespace: opfNamespace)
        .cast<XmlElement?>()
        .firstWhere((XmlElement? elem) => elem != null);
    if (spineNode == null) {
      throw Exception('EPUB parsing error: spine not found in the package.');
    }
    var spine = readSpine(spineNode);
    result.spine = spine;
    var guideNode = packageNode
        .findElements('guide', namespace: opfNamespace)
        .firstWhereOrNull((XmlElement? elem) => elem != null);
    if (guideNode != null) {
      var guide = readGuide(guideNode);
      result.guide = guide;
    }
    return result;
  }

  static EpubSpine readSpine(XmlElement spineNode) {
    var result = EpubSpine();
    result.items = <EpubSpineItemRef>[];
    var tocAttribute = spineNode.getAttribute('toc');
    result.tableOfContents = tocAttribute;
    var pageProgression = spineNode.getAttribute('page-progression-direction');
    result.ltr =
        ((pageProgression == null) || pageProgression.toLowerCase() == 'ltr');
    spineNode.children.whereType<XmlElement>().forEach(
      (XmlElement spineItemNode) {
        if (spineItemNode.name.local.toLowerCase() == 'itemref') {
          var spineItemRef = EpubSpineItemRef();
          var idRefAttribute = spineItemNode.getAttribute('idref');
          if (idRefAttribute == null || idRefAttribute.isEmpty) {
            throw Exception('Incorrect EPUB spine: item ID ref is missing');
          }
          spineItemRef.idRef = idRefAttribute;
          var linearAttribute = spineItemNode.getAttribute('linear');
          spineItemRef.isLinear = linearAttribute == null ||
              (linearAttribute.toLowerCase() == 'no');
          result.items!.add(spineItemRef);
        }
      },
    );
    return result;
  }
}
