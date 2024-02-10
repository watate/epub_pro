library epubreadertest;

import 'package:epubx/epubx.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubSchema();
  reference
    ..package = EpubPackage()
    ..navigation = EpubNavigation()
    ..contentDirectoryPath = "some/random/path";
  reference.package?.version = EpubVersion.epub2;

  late EpubSchema testSchema;
  setUp(() async {
    testSchema = EpubSchema();
    testSchema
      ..package = EpubPackage()
      ..navigation = EpubNavigation()
      ..contentDirectoryPath = "some/random/path";
    testSchema.package?.version = EpubVersion.epub2;
  });

  group("EpubSchema", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testSchema, equals(reference));
      });

      test("is false when Package changes", () async {
        var package = EpubPackage()
          ..guide = EpubGuide()
          ..version = EpubVersion.epub3;

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
        var package = EpubPackage()
          ..guide = EpubGuide()
          ..version = EpubVersion.epub3;

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
