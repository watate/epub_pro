library epubreadertest;

import 'dart:math';

import 'package:epub_plus/epub_plus.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final int length = 10;

  final RandomDataGenerator generator =
      RandomDataGenerator(Random(123778), length);

  final reference =
      generator.randomEpubPackage().copyWith(version: EpubVersion.epub3);

  late EpubPackage testPackage;

  setUp(() async {
    testPackage = reference.copyWith();
  });

  group("EpubSpine", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testPackage, equals(reference));
      });
      test("is false when Guide changes", () async {
        testPackage = testPackage.copyWith(guide: generator.randomEpubGuide());
        expect(testPackage, isNot(reference));
      });
      test("is false when Manifest changes", () async {
        testPackage =
            testPackage.copyWith(manifest: generator.randomEpubManifest());
        expect(testPackage, isNot(reference));
      });
      test("is false when Metadata changes", () async {
        testPackage =
            testPackage.copyWith(metadata: generator.randomEpubMetadata());
        expect(testPackage, isNot(reference));
      });
      test("is false when Spine changes", () async {
        testPackage = testPackage.copyWith(spine: generator.randomEpubSpine());
        expect(testPackage, isNot(reference));
      });
      test("is false when Version changes", () async {
        testPackage = testPackage.copyWith(
            version: testPackage.version == EpubVersion.epub2
                ? EpubVersion.epub3
                : EpubVersion.epub2);
        expect(testPackage, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testPackage.hashCode, equals(reference.hashCode));
      });
      test("is false when Guide changes", () async {
        testPackage = testPackage.copyWith(guide: generator.randomEpubGuide());
        expect(testPackage.hashCode, isNot(reference.hashCode));
      });
      test("is false when Manifest changes", () async {
        testPackage =
            testPackage.copyWith(manifest: generator.randomEpubManifest());
        expect(testPackage.hashCode, isNot(reference.hashCode));
      });
      test("is false when Metadata changes", () async {
        testPackage =
            testPackage.copyWith(metadata: generator.randomEpubMetadata());
        expect(testPackage.hashCode, isNot(reference.hashCode));
      });
      test("is false when Spine changes", () async {
        testPackage = testPackage.copyWith(spine: generator.randomEpubSpine());
        expect(testPackage.hashCode, isNot(reference.hashCode));
      });
      test("is false when Version changes", () async {
        testPackage = testPackage.copyWith(
            version: testPackage.version == EpubVersion.epub2
                ? EpubVersion.epub3
                : EpubVersion.epub2);
        expect(testPackage.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
