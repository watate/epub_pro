library epubreadertest;

import 'package:epubx/src/schema/opf/epub_metadata_meta.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubMetadataMeta()
    ..content = "some content"
    ..name = "Orthros"
    ..property = "Prop"
    ..refines = "Oil"
    ..id = "Unique"
    ..scheme = "A plot";

  late EpubMetadataMeta testMetadataMeta;

  setUp(() async {
    testMetadataMeta = EpubMetadataMeta()
      ..content = reference.content
      ..name = reference.name
      ..property = reference.property
      ..refines = reference.refines
      ..id = reference.id
      ..scheme = reference.scheme;
  });

  group("EpubMetadataMeta", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataMeta, equals(reference));
      });

      test("is false when Refines changes", () async {
        testMetadataMeta.refines = "Natural gas";
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Property changes", () async {
        testMetadataMeta.property = "A different Property";
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Name changes", () async {
        testMetadataMeta.id = "notOrthros";
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Content changes", () async {
        testMetadataMeta.content = "A different Content";
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Id changes", () async {
        testMetadataMeta.id = "A different ID";
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Scheme changes", () async {
        testMetadataMeta.scheme = "A strange scheme";
        expect(testMetadataMeta, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataMeta.hashCode, equals(reference.hashCode));
      });
      test("is false when Refines changes", () async {
        testMetadataMeta.refines = "Natural Gas";
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Property changes", () async {
        testMetadataMeta.property = "A different property";
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Name changes", () async {
        testMetadataMeta.name = "NotOrthros";
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Content changes", () async {
        testMetadataMeta.content = "Different Content";
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testMetadataMeta.id = "A different Id";
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Scheme changes", () async {
        testMetadataMeta.scheme = "A strange scheme";
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
