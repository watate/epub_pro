library epubreadertest;

import 'package:epub_plus/src/schema/opf/epub_manifest.dart';
import 'package:epub_plus/src/schema/opf/epub_manifest_item.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubManifest(
    items: [
      EpubManifestItem(
        fallback: "Some Fallback",
        fallbackStyle: "A Very Stylish Fallback",
        href: "Some HREF",
        id: "Some ID",
        mediaType: "MKV",
        requiredModules: "nodejs require()",
        requiredNamespace: ".NET Namespace",
      )
    ],
  );

  late EpubManifest testManifest;

  setUp(() async {
    testManifest = EpubManifest(items: List.from(reference.items));
  });

  group("EpubManifest", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testManifest, equals(reference));
      });

      test("is false when Items changes", () async {
        testManifest.items.add(EpubManifestItem(
          fallback: "Some Different Fallback",
          fallbackStyle: "A less than Stylish Fallback",
          href: "Some Different HREF",
          id: "Some Different ID",
          mediaType: "RealPlayer",
          requiredModules: "require()",
          requiredNamespace: "Namespace",
        ));

        expect(testManifest, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testManifest.hashCode, equals(reference.hashCode));
      });

      test("is false when Items changes", () async {
        testManifest.items.add(EpubManifestItem(
          fallback: "Some Different Fallback",
          fallbackStyle: "A less than Stylish Fallback",
          href: "Some Different HREF",
          id: "Some Different ID",
          mediaType: "RealPlayer",
          requiredModules: "require()",
          requiredNamespace: "Namespace",
        ));

        expect(testManifest.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
