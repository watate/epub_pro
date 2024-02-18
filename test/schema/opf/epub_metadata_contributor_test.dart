library epubreadertest;

import 'package:epub_plus/src/schema/opf/epub_metadata_contributor.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubMetadataContributor(
    contributor: "orthros",
    fileAs: "Large",
    role: "Creator",
  );

  late EpubMetadataContributor testMetadataContributor;

  setUp(() async {
    testMetadataContributor = reference.copyWith();
  });

  group("EpubMetadataContributor", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataContributor, equals(reference));
      });

      test("is false when Contributor changes", () async {
        testMetadataContributor = testMetadataContributor.copyWith(
          contributor: "NotOrthros",
        );
        expect(testMetadataContributor, isNot(reference));
      });
      test("is false when FileAs changes", () async {
        testMetadataContributor = testMetadataContributor.copyWith(
          fileAs: "Small",
        );
        expect(testMetadataContributor, isNot(reference));
      });
      test("is false when Role changes", () async {
        testMetadataContributor = testMetadataContributor.copyWith(
          role: "Copier",
        );
        expect(testMetadataContributor, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataContributor.hashCode, equals(reference.hashCode));
      });

      test("is false when Contributor changes", () async {
        testMetadataContributor = testMetadataContributor.copyWith(
          contributor: "NotOrthros",
        );
        expect(testMetadataContributor.hashCode, isNot(reference.hashCode));
      });
      test("is false when FileAs changes", () async {
        testMetadataContributor = testMetadataContributor.copyWith(
          fileAs: "Small",
        );
        expect(testMetadataContributor.hashCode, isNot(reference.hashCode));
      });
      test("is false when Role changes", () async {
        testMetadataContributor = testMetadataContributor.copyWith(
          role: "Copier",
        );
        expect(testMetadataContributor.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubMetadataContributor {
  EpubMetadataContributor copyWith({
    String? contributor,
    String? fileAs,
    String? role,
  }) {
    return EpubMetadataContributor(
      contributor: contributor ?? this.contributor,
      fileAs: fileAs ?? this.fileAs,
      role: role ?? this.role,
    );
  }
}
