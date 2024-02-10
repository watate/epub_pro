library epubreadertest;

import 'dart:math';

import 'package:epubx/src/schema/opf/epub_metadata.dart';
import 'package:epubx/src/schema/opf/epub_metadata_contributor.dart';
import 'package:epubx/src/schema/opf/epub_metadata_creator.dart';
import 'package:epubx/src/schema/opf/epub_metadata_date.dart';
import 'package:epubx/src/schema/opf/epub_metadata_identifier.dart';
import 'package:epubx/src/schema/opf/epub_metadata_meta.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final int length = 10;
  final RandomString randomString = RandomString(Random(123788));
  final RandomDataGenerator generator =
      RandomDataGenerator(Random(123778), length);

  var reference = generator.randomEpubMetadata();

  late EpubMetadata testMetadata;

  setUp(() async {
    testMetadata = EpubMetadata()
      ..contributors = List.from(reference.contributors ?? [])
      ..coverages = List.from(reference.coverages ?? [])
      ..creators = List.from(reference.creators ?? [])
      ..dates = List.from(reference.dates ?? [])
      ..description = reference.description
      ..formats = List.from(reference.formats ?? [])
      ..identifiers = List.from(reference.identifiers ?? [])
      ..languages = List.from(reference.languages ?? [])
      ..metaItems = List.from(reference.metaItems ?? [])
      ..publishers = List.from(reference.publishers ?? [])
      ..relations = List.from(reference.relations ?? [])
      ..rights = List.from(reference.rights ?? [])
      ..sources = List.from(reference.sources ?? [])
      ..subjects = List.from(reference.subjects ?? [])
      ..titles = List.from(reference.titles ?? [])
      ..types = List.from(reference.types ?? []);
  });

  group("EpubMetadata", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadata, equals(reference));
      });
      test("is false when Contributors changes", () async {
        testMetadata.contributors = [EpubMetadataContributor()];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Coverages changes", () async {
        testMetadata.coverages = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Creators changes", () async {
        testMetadata.creators = [EpubMetadataCreator()];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Dates changes", () async {
        testMetadata.dates = [EpubMetadataDate()];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Description changes", () async {
        testMetadata.description = randomString.randomAlpha(length);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Formats changes", () async {
        testMetadata.formats = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Identifiers changes", () async {
        testMetadata.identifiers = [EpubMetadataIdentifier()];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Languages changes", () async {
        testMetadata.languages = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when MetaItems changes", () async {
        testMetadata.metaItems = [EpubMetadataMeta()];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Publishers changes", () async {
        testMetadata.publishers = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Relations changes", () async {
        testMetadata.relations = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Rights changes", () async {
        testMetadata.rights = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Sources changes", () async {
        testMetadata.sources = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Subjects changes", () async {
        testMetadata.subjects = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Titles changes", () async {
        testMetadata.titles = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
      test("is false when Types changes", () async {
        testMetadata.types = [randomString.randomAlpha(length)];
        expect(testMetadata, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadata.hashCode, equals(reference.hashCode));
      });
      test("is false when Contributors changes", () async {
        testMetadata.contributors = [EpubMetadataContributor()];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Coverages changes", () async {
        testMetadata.coverages = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Creators changes", () async {
        testMetadata.creators = [EpubMetadataCreator()];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Dates changes", () async {
        testMetadata.dates = [EpubMetadataDate()];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Description changes", () async {
        testMetadata.description = randomString.randomAlpha(length);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Formats changes", () async {
        testMetadata.formats = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Identifiers changes", () async {
        testMetadata.identifiers = [EpubMetadataIdentifier()];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Languages changes", () async {
        testMetadata.languages = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when MetaItems changes", () async {
        testMetadata.metaItems = [EpubMetadataMeta()];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Publishers changes", () async {
        testMetadata.publishers = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Relations changes", () async {
        testMetadata.relations = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Rights changes", () async {
        testMetadata.rights = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Sources changes", () async {
        testMetadata.sources = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Subjects changes", () async {
        testMetadata.subjects = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Titles changes", () async {
        testMetadata.titles = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Types changes", () async {
        testMetadata.types = [randomString.randomAlpha(length)];
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
