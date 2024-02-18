import 'package:epub_plus/src/schema/opf/epub_manifest.dart';
import 'package:xml/xml.dart' show XmlBuilder;

class EpubManifestWriter {
  static void writeManifest(XmlBuilder builder, EpubManifest? manifest) {
    builder.element(
      'manifest',
      nest: () {
        for (var item in manifest!.items) {
          builder.element(
            'item',
            nest: () {
              builder
                ..attribute('id', item.id!)
                ..attribute('href', item.href!)
                ..attribute('media-type', item.mediaType!);
            },
          );
        }
      },
    );
  }
}
