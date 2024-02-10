library epubreadertest;

import 'package:epubx/epubx.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubSchema();
  reference
    ..Package = EpubPackage()
    ..Navigation = EpubNavigation()
    ..ContentDirectoryPath = "some/random/path";
  reference.Package?.Version = EpubVersion.Epub2;

  late EpubSchema testSchema;
  setUp(() async {
    testSchema = EpubSchema();
    testSchema
      ..Package = EpubPackage()
      ..Navigation = EpubNavigation()
      ..ContentDirectoryPath = "some/random/path";
    testSchema.Package?.Version = EpubVersion.Epub2;
  });

  group("EpubSchema", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testSchema, equals(reference));
      });

      test("is false when Package changes", () async {
        var package = EpubPackage()
          ..Guide = EpubGuide()
          ..Version = EpubVersion.Epub3;

        testSchema.Package = package;
        expect(testSchema, isNot(reference));
      });

      test("is false when Navigation changes", () async {
        testSchema.Navigation = EpubNavigation()
          ..DocTitle = EpubNavigationDocTitle()
          ..DocAuthors = [EpubNavigationDocAuthor()];

        expect(testSchema, isNot(reference));
      });

      test("is false when ContentDirectoryPath changes", () async {
        testSchema.ContentDirectoryPath = "some/other/random/path/to/dev/null";
        expect(testSchema, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testSchema.hashCode, equals(reference.hashCode));
      });

      test("is false when Package changes", () async {
        var package = EpubPackage()
          ..Guide = EpubGuide()
          ..Version = EpubVersion.Epub3;

        testSchema.Package = package;
        expect(testSchema.hashCode, isNot(reference.hashCode));
      });

      test("is false when Navigation changes", () async {
        testSchema.Navigation = EpubNavigation()
          ..DocTitle = EpubNavigationDocTitle()
          ..DocAuthors = [EpubNavigationDocAuthor()];

        expect(testSchema.hashCode, isNot(reference.hashCode));
      });

      test("is false when ContentDirectoryPath changes", () async {
        testSchema.ContentDirectoryPath = "some/other/random/path/to/dev/null";
        expect(testSchema.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
