library epubreadertest;

import 'package:epub_plus/src/schema/opf/epub_manifest_item.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubManifestItem(
      fallback: "Some Fallback",
      fallbackStyle: "A Very Stylish Fallback",
      href: "Some HREF",
      id: "Some ID",
      mediaType: "MKV",
      requiredModules: "nodejs require()",
      requiredNamespace: ".NET Namespace");

  late EpubManifestItem testManifestItem;

  setUp(() async {
    testManifestItem = reference.copyWith();
  });

  group("EpubManifestItem", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testManifestItem, equals(reference));
      });

      test("is false when Fallback changes", () async {
        testManifestItem =
            testManifestItem.copyWith(fallback: "Some Different Fallback");
        expect(testManifestItem, isNot(reference));
      });
      test("is false when FallbackStyle changes", () async {
        testManifestItem = testManifestItem.copyWith(
            fallbackStyle: "A less than Stylish Fallback");
        expect(testManifestItem, isNot(reference));
      });
      test("is false when Href changes", () async {
        testManifestItem = testManifestItem.copyWith(href: "A different Href");
        expect(testManifestItem, isNot(reference));
      });
      test("is false when Id changes", () async {
        testManifestItem =
            testManifestItem.copyWith(id: "A guarenteed unique Id");
        expect(testManifestItem, isNot(reference));
      });
      test("is false when MediaType changes", () async {
        testManifestItem = testManifestItem.copyWith(mediaType: "RealPlayer");
        expect(testManifestItem, isNot(reference));
      });
      test("is false when RequiredModules changes", () async {
        testManifestItem =
            testManifestItem.copyWith(requiredModules: "A non node-js module");
        expect(testManifestItem, isNot(reference));
      });
      test("is false when RequiredNamespaces changes", () async {
        testManifestItem = testManifestItem.copyWith(
            requiredNamespace: "Some non-dot net namespace");
        expect(testManifestItem, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testManifestItem.hashCode, equals(reference.hashCode));
      });

      test("is false when Fallback changes", () async {
        testManifestItem =
            testManifestItem.copyWith(fallback: "Some Different Fallback");
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when FallbackStyle changes", () async {
        testManifestItem = testManifestItem.copyWith(
            fallbackStyle: "A less than Stylish Fallback");
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when Href changes", () async {
        testManifestItem = testManifestItem.copyWith(href: "A different Href");
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testManifestItem =
            testManifestItem.copyWith(id: "A guarenteed unique Id");
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when MediaType changes", () async {
        testManifestItem = testManifestItem.copyWith(mediaType: "RealPlayer");
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when RequiredModules changes", () async {
        testManifestItem =
            testManifestItem.copyWith(requiredModules: "A non node-js module");
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
      test("is false when RequiredNamespaces changes", () async {
        testManifestItem = testManifestItem.copyWith(
            requiredNamespace: "Some non-dot net namespace");
        expect(testManifestItem.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubManifestItem {
  EpubManifestItem copyWith({
    String? id,
    String? href,
    String? mediaType,
    String? mediaOverlay,
    String? requiredNamespace,
    String? requiredModules,
    String? fallback,
    String? fallbackStyle,
    String? properties,
  }) {
    return EpubManifestItem(
      id: id ?? this.id,
      href: href ?? this.href,
      mediaType: mediaType ?? this.mediaType,
      mediaOverlay: mediaOverlay ?? this.mediaOverlay,
      requiredNamespace: requiredNamespace ?? this.requiredNamespace,
      requiredModules: requiredModules ?? this.requiredModules,
      fallback: fallback ?? this.fallback,
      fallbackStyle: fallbackStyle ?? this.fallbackStyle,
      properties: properties ?? this.properties,
    );
  }
}
