library epubreadertest;

import 'package:epub_plus/epub_plus.dart';
import 'package:test/test.dart';

main() async {
  final reference = EpubSchema(
    package: EpubPackage(version: EpubVersion.epub2),
    navigation: EpubNavigation(),
    contentDirectoryPath: "some/random/path",
  );

  late EpubSchema testSchema;

  setUp(() async {
    testSchema = reference.copyWith();
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

        testSchema = testSchema.copyWith(package: package);
        expect(testSchema, isNot(reference));
      });

      test("is false when Navigation changes", () async {
        testSchema = testSchema.copyWith(
          navigation: EpubNavigation(
            docTitle: EpubNavigationDocTitle(),
            docAuthors: [EpubNavigationDocAuthor()],
          ),
        );

        expect(testSchema, isNot(reference));
      });

      test("is false when ContentDirectoryPath changes", () async {
        testSchema = testSchema.copyWith(
            contentDirectoryPath: "some/other/random/path/to/dev/null");
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

        testSchema = testSchema.copyWith(package: package);
        expect(testSchema.hashCode, isNot(reference.hashCode));
      });

      test("is false when Navigation changes", () async {
        testSchema = testSchema.copyWith(
          navigation: EpubNavigation(
            docTitle: EpubNavigationDocTitle(),
            docAuthors: [EpubNavigationDocAuthor()],
          ),
        );

        expect(testSchema.hashCode, isNot(reference.hashCode));
      });

      test("is false when ContentDirectoryPath changes", () async {
        testSchema = testSchema.copyWith(
            contentDirectoryPath: "some/other/random/path/to/dev/null");
        expect(testSchema.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubSchema {
  EpubSchema copyWith({
    EpubPackage? package,
    EpubNavigation? navigation,
    String? contentDirectoryPath,
  }) {
    return EpubSchema(
      package: package ?? this.package,
      navigation: navigation ?? this.navigation,
      contentDirectoryPath: contentDirectoryPath ?? this.contentDirectoryPath,
    );
  }
}
