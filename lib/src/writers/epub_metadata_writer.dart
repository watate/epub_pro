import 'package:epub_plus/src/schema/opf/epub_metadata.dart';
import 'package:epub_plus/src/schema/opf/epub_version.dart';
import 'package:xml/xml.dart' show XmlBuilder;

class EpubMetadataWriter {
  static const _dcNamespace = 'http://purl.org/dc/elements/1.1/';
  static const _opfNamespace = 'http://www.idpf.org/2007/opf';

  static void writeMetadata(
      XmlBuilder builder, EpubMetadata? meta, EpubVersion? version) {
    builder.element(
      'metadata',
      namespaces: {_opfNamespace: 'opf', _dcNamespace: 'dc'},
      nest: () {
        meta!
          ..titles.forEach((item) =>
              builder.element('title', nest: item, namespace: _dcNamespace))
          ..creators.forEach(
            (item) => builder.element(
              'creator',
              namespace: _dcNamespace,
              nest: () {
                if (item.role != null) {
                  builder.attribute('role', item.role!,
                      namespace: _opfNamespace);
                }
                if (item.fileAs != null) {
                  builder.attribute('file-as', item.fileAs!,
                      namespace: _opfNamespace);
                }
                builder.text(item.creator!);
              },
            ),
          )
          ..subjects.forEach((item) =>
              builder.element('subject', namespace: _dcNamespace, nest: item))
          ..publishers.forEach((item) =>
              builder.element('publisher', namespace: _dcNamespace, nest: item))
          ..contributors.forEach(
            (item) => builder.element(
              'contributor',
              namespace: _dcNamespace,
              nest: () {
                if (item.role != null) {
                  builder.attribute('role', item.role!,
                      namespace: _opfNamespace);
                }
                if (item.fileAs != null) {
                  builder.attribute('file-as', item.fileAs!,
                      namespace: _opfNamespace);
                }
                builder.text(item.contributor!);
              },
            ),
          )
          ..dates.forEach(
            (date) => builder.element(
              'date',
              namespace: _dcNamespace,
              nest: () {
                if (date.event != null) {
                  builder.attribute('event', date.event!,
                      namespace: _opfNamespace);
                }
                builder.text(date.date!);
              },
            ),
          )
          ..types.forEach((type) =>
              builder.element('type', namespace: _dcNamespace, nest: type))
          ..formats.forEach((format) =>
              builder.element('format', namespace: _dcNamespace, nest: format))
          ..identifiers.forEach(
            (id) => builder.element(
              'identifier',
              namespace: _dcNamespace,
              nest: () {
                if (id.id != null) builder.attribute('id', id.id!);
                if (id.scheme != null) {
                  builder.attribute('scheme', id.scheme!,
                      namespace: _opfNamespace);
                }
                builder.text(id.identifier!);
              },
            ),
          )
          ..sources.forEach((item) =>
              builder.element('source', namespace: _dcNamespace, nest: item))
          ..languages.forEach((item) =>
              builder.element('language', namespace: _dcNamespace, nest: item))
          ..relations.forEach((item) =>
              builder.element('relation', namespace: _dcNamespace, nest: item))
          ..coverages.forEach((item) =>
              builder.element('coverage', namespace: _dcNamespace, nest: item))
          ..rights.forEach((item) =>
              builder.element('rights', namespace: _dcNamespace, nest: item))
          ..metaItems.forEach(
            (metaitem) => builder.element(
              'meta',
              nest: () {
                if (version == EpubVersion.epub2) {
                  if (metaitem.name != null) {
                    builder.attribute('name', metaitem.name!);
                  }
                  if (metaitem.content != null) {
                    builder.attribute('content', metaitem.content!);
                  }
                } else if (version == EpubVersion.epub3) {
                  if (metaitem.id != null) {
                    builder.attribute('id', metaitem.id!);
                  }
                  if (metaitem.refines != null) {
                    builder.attribute('refines', metaitem.refines!);
                  }
                  if (metaitem.property != null) {
                    builder.attribute('property', metaitem.property!);
                  }
                  if (metaitem.scheme != null) {
                    builder.attribute('scheme', metaitem.scheme!);
                  }
                }
              },
            ),
          );

        if (meta.description != null) {
          builder.element(
            'description',
            namespace: _dcNamespace,
            nest: meta.description,
          );
        }
      },
    );
  }
}
