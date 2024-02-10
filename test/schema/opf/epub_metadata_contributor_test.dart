library epubreadertest;

import 'package:epubx/src/schema/opf/epub_metadata_contributor.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubMetadataContributor()
    ..contributor = "orthros"
    ..fileAs = "Large"
    ..role = "Creator";

  late EpubMetadataContributor testMetadataContributor;

  setUp(() async {
    testMetadataContributor = EpubMetadataContributor()
      ..contributor = reference.contributor
      ..fileAs = reference.fileAs
      ..role = reference.role;
  });

  group("EpubMetadataContributor", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataContributor, equals(reference));
      });

      test("is false when Contributor changes", () async {
        testMetadataContributor.contributor = "NotOrthros";
        expect(testMetadataContributor, isNot(reference));
      });
      test("is false when FileAs changes", () async {
        testMetadataContributor.fileAs = "Small";
        expect(testMetadataContributor, isNot(reference));
      });
      test("is false when Role changes", () async {
        testMetadataContributor.role = "Copier";
        expect(testMetadataContributor, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataContributor.hashCode, equals(reference.hashCode));
      });

      test("is false when Contributor changes", () async {
        testMetadataContributor.contributor = "NotOrthros";
        expect(testMetadataContributor.hashCode, isNot(reference.hashCode));
      });
      test("is false when FileAs changes", () async {
        testMetadataContributor.fileAs = "Small";
        expect(testMetadataContributor.hashCode, isNot(reference.hashCode));
      });
      test("is false when Role changes", () async {
        testMetadataContributor.role = "Copier";
        expect(testMetadataContributor.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
