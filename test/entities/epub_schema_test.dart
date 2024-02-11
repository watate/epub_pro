library epubreadertest;

import 'package:epubx/epubx.dart';
import 'package:test/test.dart';

main() async {
  final reference = EpubSchema();
  reference
    ..package = EpubPackage(version: EpubVersion.epub2)
    ..navigation = EpubNavigation()
    ..contentDirectoryPath = "some/random/path";

  late EpubSchema testSchema;
  setUp(() async {
    testSchema = EpubSchema();
    testSchema
      ..package = EpubPackage(version: EpubVersion.epub2)
      ..navigation = EpubNavigation()
      ..contentDirectoryPath = "some/random/path";
  });

  group("EpubSchema", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testSchema, equals(reference));
      });

      test("is false when Package changes", () async {
        var package = EpubPackage(
          version: EpubVersion.epub3,
          guide: EpubGuide(),
        );

        testSchema.package = package;
        expect(testSchema, isNot(reference));
      });

      test("is false when Navigation changes", () async {
        testSchema.navigation = EpubNavigation(
          docTitle: EpubNavigationDocTitle(),
          docAuthors: [EpubNavigationDocAuthor()],
        );

        expect(testSchema, isNot(reference));
      });

      test("is false when ContentDirectoryPath changes", () async {
        testSchema.contentDirectoryPath = "some/other/random/path/to/dev/null";
        expect(testSchema, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testSchema.hashCode, equals(reference.hashCode));
      });

      test("is false when Package changes", () async {
        final package = EpubPackage(
          version: EpubVersion.epub3,
          guide: EpubGuide(),
        );

        testSchema.package = package;
        expect(testSchema.hashCode, isNot(reference.hashCode));
      });

      test("is false when Navigation changes", () async {
        testSchema.navigation = EpubNavigation(
          docTitle: EpubNavigationDocTitle(),
          docAuthors: [EpubNavigationDocAuthor()],
        );

        expect(testSchema.hashCode, isNot(reference.hashCode));
      });

      test("is false when ContentDirectoryPath changes", () async {
        testSchema.contentDirectoryPath = "some/other/random/path/to/dev/null";
        expect(testSchema.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
