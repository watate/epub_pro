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
    final items = <EpubGuideReference>[];

    guideNode.children.whereType<XmlElement>().forEach(
      (XmlElement guideReferenceNode) {
        if (guideReferenceNode.name.local.toLowerCase() == 'reference') {
          String? type, title, href;

          for (final attribute in guideReferenceNode.attributes) {
            final attributeValue = attribute.value;

            switch (attribute.name.local.toLowerCase()) {
              case 'type':
                type = attributeValue;
              case 'title':
                title = attributeValue;
              case 'href':
                href = attributeValue;
            }
          }
          if (type == null || type.isEmpty) {
            throw Exception('Incorrect EPUB guide: item type is missing');
          }
          if (href == null || href.isEmpty) {
            throw Exception('Incorrect EPUB guide: item href is missing');
          }

          final guideReference = EpubGuideReference(
            type: type,
            title: title,
            href: href,
          );

          items.add(guideReference);
        }
      },
    );
    return EpubGuide(items: items);
  }

  static EpubManifest readManifest(XmlElement manifestNode) {
    final items = <EpubManifestItem>[];
    manifestNode.children
        .whereType<XmlElement>()
        .forEach((XmlElement manifestItemNode) {
      if (manifestItemNode.name.local.toLowerCase() == 'item') {
        String? id,
            href,
            mediaType,
            mediaOverlay,
            requiredNamespace,
            requiredModules,
            fallback,
            fallbackStyle,
            properties;
        for (var manifestItemNodeAttribute in manifestItemNode.attributes) {
          var attributeValue = manifestItemNodeAttribute.value;
          switch (manifestItemNodeAttribute.name.local.toLowerCase()) {
            case 'id':
              id = attributeValue;
            case 'href':
              href = attributeValue;
            case 'media-type':
              mediaType = attributeValue;
            case 'media-overlay':
              mediaOverlay = attributeValue;
            case 'required-namespace':
              requiredNamespace = attributeValue;
            case 'required-modules':
              requiredModules = attributeValue;
            case 'fallback':
              fallback = attributeValue;
            case 'fallback-style':
              fallbackStyle = attributeValue;
            case 'properties':
              properties = attributeValue;
          }
        }

        if (id == null || id.isEmpty) {
          throw Exception('Incorrect EPUB manifest: item ID is missing');
        }
        if (href == null || href.isEmpty) {
          throw Exception('Incorrect EPUB manifest: item href is missing');
        }
        if (mediaType == null || mediaType.isEmpty) {
          throw Exception(
            'Incorrect EPUB manifest: item media type is missing',
          );
        }
        final manifestItem = EpubManifestItem(
          id: id,
          href: href,
          mediaType: mediaType,
          mediaOverlay: mediaOverlay,
          requiredNamespace: requiredNamespace,
          requiredModules: requiredModules,
          fallback: fallback,
          fallbackStyle: fallbackStyle,
          properties: properties,
        );

        items.add(manifestItem);
      }
    });
    return EpubManifest(items: items);
  }

  static EpubMetadata readMetadata(
    XmlElement metadataNode,
    EpubVersion? epubVersion,
  ) {
    String? description;
    final titles = <String>[];
    final creators = <EpubMetadataCreator>[];
    final subjects = <String>[];
    final publishers = <String>[];
    final contributors = <EpubMetadataContributor>[];
    final dates = <EpubMetadataDate>[];
    final types = <String>[];
    final formats = <String>[];
    final identifiers = <EpubMetadataIdentifier>[];
    final sources = <String>[];
    final languages = <String>[];
    final relations = <String>[];
    final coverages = <String>[];
    final rights = <String>[];
    final metaItems = <EpubMetadataMeta>[];
    metadataNode.children.whereType<XmlElement>().forEach(
      (XmlElement metadataItemNode) {
        final innerText = metadataItemNode.innerText;

        return switch (metadataItemNode.name.local.toLowerCase()) {
          'title' => titles.add(innerText),
          'creator' => creators.add(readMetadataCreator(metadataItemNode)),
          'subject' => subjects.add(innerText),
          'description' => description = innerText,
          'publisher' => publishers.add(innerText),
          'contributor' =>
            contributors.add(readMetadataContributor(metadataItemNode)),
          'date' => dates.add(readMetadataDate(metadataItemNode)),
          'type' => types.add(innerText),
          'format' => formats.add(innerText),
          'identifier' =>
            identifiers.add(readMetadataIdentifier(metadataItemNode)),
          'source' => sources.add(innerText),
          'language' => languages.add(innerText),
          'relation' => relations.add(innerText),
          'coverage' => coverages.add(innerText),
          'rights' => rights.add(innerText),
          'meta' when epubVersion == EpubVersion.epub2 =>
            metaItems.add(readMetadataMetaVersion2(metadataItemNode)),
          'meta' when epubVersion == EpubVersion.epub3 =>
            metaItems.add(readMetadataMetaVersion3(metadataItemNode)),
          _ => null,
        };
      },
    );
    return EpubMetadata(
      titles: titles,
      creators: creators,
      subjects: subjects,
      description: description,
      publishers: publishers,
      contributors: contributors,
      dates: dates,
      types: types,
      formats: formats,
      identifiers: identifiers,
      sources: sources,
      languages: languages,
      relations: relations,
      coverages: coverages,
      rights: rights,
      metaItems: metaItems,
    );
  }

  static EpubMetadataContributor readMetadataContributor(
      XmlElement metadataContributorNode) {
    String? contributor, role, fileAs;

    for (final attribute in metadataContributorNode.attributes) {
      final attributeValue = attribute.value;

      switch (attribute.name.local.toLowerCase()) {
        case 'role':
          role = attributeValue;
        case 'file-as':
          fileAs = attributeValue;
      }
    }
    contributor = metadataContributorNode.innerText;

    return EpubMetadataContributor(
      contributor: contributor,
      role: role,
      fileAs: fileAs,
    );
  }

  static EpubMetadataCreator readMetadataCreator(
      XmlElement metadataCreatorNode) {
    String? creator, role, fileAs;

    for (final attribute in metadataCreatorNode.attributes) {
      final attributeValue = attribute.value;

      switch (attribute.name.local.toLowerCase()) {
        case 'role':
          role = attributeValue;
        case 'file-as':
          fileAs = attributeValue;
      }
    }
    creator = metadataCreatorNode.innerText;

    return EpubMetadataCreator(
      creator: creator,
      role: role,
      fileAs: fileAs,
    );
  }

  static EpubMetadataDate readMetadataDate(XmlElement metadataDateNode) {
    String? event, date;

    var eventAttribute = metadataDateNode.getAttribute('event',
        namespace: metadataDateNode.name.namespaceUri);
    if (eventAttribute != null && eventAttribute.isNotEmpty) {
      event = eventAttribute;
    }
    date = metadataDateNode.innerText;

    return EpubMetadataDate(
      date: date,
      event: event,
    );
  }

  static EpubMetadataIdentifier readMetadataIdentifier(
    XmlElement metadataIdentifierNode,
  ) {
    String? id, scheme, identifier;

    for (final attribute in metadataIdentifierNode.attributes) {
      final attributeValue = attribute.value;

      switch (attribute.name.local.toLowerCase()) {
        case 'id':
          id = attributeValue;
        case 'scheme':
          scheme = attributeValue;
      }
    }
    identifier = metadataIdentifierNode.innerText;

    return EpubMetadataIdentifier(
      id: id,
      scheme: scheme,
      identifier: identifier,
    );
  }

  static EpubMetadataMeta readMetadataMetaVersion2(
    XmlElement metadataMetaNode,
  ) {
    String? name, content;
    for (final attribute in metadataMetaNode.attributes) {
      final attributeValue = attribute.value;

      switch (attribute.name.local.toLowerCase()) {
        case 'name':
          name = attributeValue;
        case 'content':
          content = attributeValue;
      }
    }
    return EpubMetadataMeta(
      name: name,
      content: content,
    );
  }

  static EpubMetadataMeta readMetadataMetaVersion3(
      XmlElement metadataMetaNode) {
    final attributes = <String, String>{};
    String? id, refines, property, scheme, content;
    for (var metadataMetaNodeAttribute in metadataMetaNode.attributes) {
      final attributeValue = metadataMetaNodeAttribute.value;

      final name = metadataMetaNodeAttribute.name.local.toLowerCase();

      attributes[name] = attributeValue;
      switch (name) {
        case 'id':
          id = attributeValue;
        case 'refines':
          refines = attributeValue;
        case 'property':
          property = attributeValue;
        case 'scheme':
          scheme = attributeValue;
      }
    }
    content = metadataMetaNode.innerText;

    return EpubMetadataMeta(
      id: id,
      refines: refines,
      property: property,
      scheme: scheme,
      content: content,
      attributes: attributes,
    );
  }

  static Future<EpubPackage> readPackage(
    Archive epubArchive,
    String rootFilePath,
  ) async {
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
    EpubVersion? version;
    final epubVersionValue = packageNode.getAttribute('version');
    if (epubVersionValue == '2.0') {
      version = EpubVersion.epub2;
    } else if (epubVersionValue == '3.0') {
      version = EpubVersion.epub3;
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
    final metadata = readMetadata(metadataNode, version);

    var manifestNode = packageNode
        .findElements('manifest', namespace: opfNamespace)
        .cast<XmlElement?>()
        .firstWhere((XmlElement? elem) => elem != null);
    if (manifestNode == null) {
      throw Exception('EPUB parsing error: manifest not found in the package.');
    }
    final manifest = readManifest(manifestNode);

    var spineNode = packageNode
        .findElements('spine', namespace: opfNamespace)
        .cast<XmlElement?>()
        .firstWhere((XmlElement? elem) => elem != null);
    if (spineNode == null) {
      throw Exception('EPUB parsing error: spine not found in the package.');
    }
    final spine = readSpine(spineNode);

    final guideNode = packageNode
        .findElements('guide', namespace: opfNamespace)
        .firstWhereOrNull((XmlElement? elem) => elem != null);
    EpubGuide? guide;
    if (guideNode != null) {
      guide = readGuide(guideNode);
    }

    return EpubPackage(
      version: version,
      metadata: metadata,
      manifest: manifest,
      spine: spine,
      guide: guide,
    );
  }

  static EpubSpine readSpine(XmlElement spineNode) {
    final items = <EpubSpineItemRef>[];
    final tableOfContents = spineNode.getAttribute('toc');

    final pageProgression =
        spineNode.getAttribute('page-progression-direction');
    final ltr =
        ((pageProgression == null) || pageProgression.toLowerCase() == 'ltr');

    spineNode.children.whereType<XmlElement>().forEach(
      (XmlElement spineItemNode) {
        if (spineItemNode.name.local.toLowerCase() == 'itemref') {
          String? idRef = spineItemNode.getAttribute('idref');
          if (idRef == null || idRef.isEmpty) {
            throw Exception('Incorrect EPUB spine: item ID ref is missing');
          }

          var linearAttribute = spineItemNode.getAttribute('linear');
          final isLinear = linearAttribute == null ||
              (linearAttribute.toLowerCase() == 'no');

          final spineItemRef = EpubSpineItemRef(
            idRef: idRef,
            isLinear: isLinear,
          );
          items.add(spineItemRef);
        }
      },
    );
    return EpubSpine(
      items: items,
      tableOfContents: tableOfContents,
      ltr: ltr,
    );
  }
}
