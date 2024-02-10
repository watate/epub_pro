library epubreadertest;

import 'package:epubx/src/schema/opf/epub_manifest_item.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubManifestItem()
    ..fallback = "Some Fallback"
    ..fallbackStyle = "A Very Stylish Fallback"
    ..href = "Some HREF"
    ..id = "Some ID"
    ..mediaType = "MKV"
    ..requiredModules = "nodejs require()"
    ..requiredNamespace = ".NET Namespace";

  late EpubManifestItem testManifestItem;

  setUp(() async {
    testManifestItem = EpubManifestItem()
      ..fallback = reference.fallback
      ..fallbackStyle = reference.fallbackStyle
      ..href = reference.href
      ..id = reference.id
      ..mediaType = reference.mediaType
      ..requiredModules = reference.requiredModules
      ..requiredNamespace = reference.requiredNamespace;
  });

  group("EpubManifestItem", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testManifestItem, equals(reference));
      });

      test("is false when Fallback changes", () async {
        testManifestItem.fallback = "Some Different Fallback";
        expect(testManifestItem, isNot(reference));
      });
      test("is false when FallbackStyle changes", () async {
        testManifestItem.fallbackStyle = "A less than Stylish Fallback";
        expect(testManifestItem, isNot(reference));
      });
      test("is false when Href changes", () async {
        testManifestItem.href = "A different Href";
        expect(testManifestItem, isNot(reference));
      });
      test("is false when Id changes", () async {
        testManifestItem.id = "A guarenteed unique Id";
        expect(testManifestItem, isNot(reference));
      });
      test("is false when MediaType changes", () async {
        testManifestItem.mediaType = "RealPlayer";
        expect(testManifestItem, isNot(reference));
      });
      test("is false when RequiredModules changes", () async {
        testManifestItem.requiredModules = "A non node-js module";
        expect(testManifestItem, isNot(reference));
      });
      test("is false when RequiredNamespaces changes", () async {
        testManifestItem.requiredNamespace = "Some non-dot net namespace";
        expect(testManifestItem, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testManifestItem.hashCode, equals(reference.hashCode));
      });

      test("is false when Fallback changes", () async {
        testManifestItem.fallback = "Some Different Fallback";
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when FallbackStyle changes", () async {
        testManifestItem.fallbackStyle = "A less than Stylish Fallback";
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when Href changes", () async {
        testManifestItem.href = "A different Href";
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testManifestItem.id = "A guarenteed unique Id";
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when MediaType changes", () async {
        testManifestItem.mediaType = "RealPlayer";
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when RequiredModules changes", () async {
        testManifestItem.requiredModules = "A non node-js module";
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when RequiredNamespaces changes", () async {
        testManifestItem.requiredNamespace = "Some non-dot net namespace";
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
