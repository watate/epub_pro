library epubreadertest;

import 'dart:math';

import 'package:epub_plus/src/schema/opf/epub_metadata.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_contributor.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_creator.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_date.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_identifier.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_meta.dart';
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
    testMetadata = reference.copyWith();
  });

  group("EpubMetadata", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadata, equals(reference));
      });
      test("is false when Contributors changes", () async {
        testMetadata =
            testMetadata.copyWith(contributors: [EpubMetadataContributor()]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Coverages changes", () async {
        testMetadata = testMetadata
            .copyWith(coverages: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Creators changes", () async {
        testMetadata = testMetadata.copyWith(creators: [EpubMetadataCreator()]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Dates changes", () async {
        testMetadata = testMetadata.copyWith(dates: [EpubMetadataDate()]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Description changes", () async {
        testMetadata = testMetadata.copyWith(
            description: randomString.randomAlpha(length));
        expect(testMetadata, isNot(reference));
      });
      test("is false when Formats changes", () async {
        testMetadata =
            testMetadata.copyWith(formats: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Identifiers changes", () async {
        testMetadata =
            testMetadata.copyWith(identifiers: [EpubMetadataIdentifier()]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Languages changes", () async {
        testMetadata = testMetadata
            .copyWith(languages: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when MetaItems changes", () async {
        testMetadata = testMetadata.copyWith(metaItems: [EpubMetadataMeta()]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Publishers changes", () async {
        testMetadata = testMetadata
            .copyWith(publishers: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Relations changes", () async {
        testMetadata = testMetadata
            .copyWith(relations: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Rights changes", () async {
        testMetadata =
            testMetadata.copyWith(rights: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Sources changes", () async {
        testMetadata =
            testMetadata.copyWith(sources: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Subjects changes", () async {
        testMetadata =
            testMetadata.copyWith(subjects: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Titles changes", () async {
        testMetadata =
            testMetadata.copyWith(titles: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
      test("is false when Types changes", () async {
        testMetadata =
            testMetadata.copyWith(types: [randomString.randomAlpha(length)]);
        expect(testMetadata, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadata.hashCode, equals(reference.hashCode));
      });
      test("is false when Contributors changes", () async {
        testMetadata =
            testMetadata.copyWith(contributors: [EpubMetadataContributor()]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Coverages changes", () async {
        testMetadata = testMetadata
            .copyWith(coverages: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Creators changes", () async {
        testMetadata = testMetadata.copyWith(creators: [EpubMetadataCreator()]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Dates changes", () async {
        testMetadata = testMetadata.copyWith(dates: [EpubMetadataDate()]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Description changes", () async {
        testMetadata = testMetadata.copyWith(
            description: randomString.randomAlpha(length));
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Formats changes", () async {
        testMetadata =
            testMetadata.copyWith(formats: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Identifiers changes", () async {
        testMetadata =
            testMetadata.copyWith(identifiers: [EpubMetadataIdentifier()]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Languages changes", () async {
        testMetadata = testMetadata
            .copyWith(languages: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when MetaItems changes", () async {
        testMetadata = testMetadata.copyWith(metaItems: [EpubMetadataMeta()]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Publishers changes", () async {
        testMetadata = testMetadata
            .copyWith(publishers: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Relations changes", () async {
        testMetadata = testMetadata
            .copyWith(relations: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Rights changes", () async {
        testMetadata =
            testMetadata.copyWith(rights: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Sources changes", () async {
        testMetadata =
            testMetadata.copyWith(sources: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Subjects changes", () async {
        testMetadata =
            testMetadata.copyWith(subjects: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Titles changes", () async {
        testMetadata =
            testMetadata.copyWith(titles: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
      test("is false when Types changes", () async {
        testMetadata =
            testMetadata.copyWith(types: [randomString.randomAlpha(length)]);
        expect(testMetadata.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubMetadata {
  EpubMetadata copyWith({
    List<String>? titles,
    List<EpubMetadataCreator>? creators,
    List<String>? subjects,
    String? description,
    List<String>? publishers,
    List<EpubMetadataContributor>? contributors,
    List<EpubMetadataDate>? dates,
    List<String>? types,
    List<String>? formats,
    List<EpubMetadataIdentifier>? identifiers,
    List<String>? sources,
    List<String>? languages,
    List<String>? relations,
    List<String>? coverages,
    List<String>? rights,
    List<EpubMetadataMeta>? metaItems,
  }) {
    return EpubMetadata(
      titles: titles ?? List.from(this.titles),
      creators: creators ?? List.from(this.creators),
      subjects: subjects ?? List.from(this.subjects),
      description: description ?? this.description,
      publishers: publishers ?? List.from(this.publishers),
      contributors: contributors ?? List.from(this.contributors),
      dates: dates ?? List.from(this.dates),
      types: types ?? List.from(this.types),
      formats: formats ?? List.from(this.formats),
      identifiers: identifiers ?? List.from(this.identifiers),
      sources: sources ?? List.from(this.sources),
      languages: languages ?? List.from(this.languages),
      relations: relations ?? List.from(this.relations),
      coverages: coverages ?? List.from(this.coverages),
      rights: rights ?? List.from(this.rights),
      metaItems: metaItems ?? List.from(this.metaItems),
    );
  }
}
