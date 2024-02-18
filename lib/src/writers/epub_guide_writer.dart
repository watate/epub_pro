import 'package:epub_plus/src/schema/opf/epub_guide.dart';
import 'package:xml/xml.dart' show XmlBuilder;

class EpubGuideWriter {
  static void writeGuide(XmlBuilder builder, EpubGuide? guide) {
    builder.element(
      'guide',
      nest: () {
        for (final guideItem in guide!.items) {
          builder.element(
            'reference',
            attributes: {
              'type': guideItem.type!,
              'title': guideItem.title!,
              'href': guideItem.href!
            },
          );
        }
      },
    );
  }
}
