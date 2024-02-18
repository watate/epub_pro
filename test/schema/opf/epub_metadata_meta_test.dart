library epubreadertest;

import 'package:epub_plus/src/schema/opf/epub_metadata_meta.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubMetadataMeta(
    content: "some content",
    name: "Orthros",
    property: "Prop",
    refines: "Oil",
    id: "Unique",
    scheme: "A plot",
  );

  late EpubMetadataMeta testMetadataMeta;

  setUp(() async {
    testMetadataMeta = reference.copyWith();
  });

  group("EpubMetadataMeta", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataMeta, equals(reference));
      });

      test("is false when Refines changes", () async {
        testMetadataMeta = testMetadataMeta.copyWith(refines: "Natural Gas");
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Property changes", () async {
        testMetadataMeta =
            testMetadataMeta.copyWith(property: "A different property");
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Name changes", () async {
        testMetadataMeta = testMetadataMeta.copyWith(name: "NotOrthros");
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Content changes", () async {
        testMetadataMeta =
            testMetadataMeta.copyWith(content: "Different Content");
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Id changes", () async {
        testMetadataMeta = testMetadataMeta.copyWith(id: "A different Id");
        expect(testMetadataMeta, isNot(reference));
      });
      test("is false when Scheme changes", () async {
        testMetadataMeta =
            testMetadataMeta.copyWith(scheme: "A strange scheme");
        expect(testMetadataMeta, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataMeta.hashCode, equals(reference.hashCode));
      });
      test("is false when Refines changes", () async {
        testMetadataMeta = testMetadataMeta.copyWith(refines: "Natural Gas");
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Property changes", () async {
        testMetadataMeta =
            testMetadataMeta.copyWith(property: "A different property");
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Name changes", () async {
        testMetadataMeta = testMetadataMeta.copyWith(name: "NotOrthros");
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Content changes", () async {
        testMetadataMeta =
            testMetadataMeta.copyWith(content: "Different Content");
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testMetadataMeta = testMetadataMeta.copyWith(id: "A different Id");
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
      test("is false when Scheme changes", () async {
        testMetadataMeta =
            testMetadataMeta.copyWith(scheme: "A strange scheme");
        expect(testMetadataMeta.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubMetadataMeta {
  EpubMetadataMeta copyWith({
    String? content,
    String? id,
    String? name,
    String? property,
    String? refines,
    String? scheme,
  }) {
    return EpubMetadataMeta(
      content: content ?? this.content,
      id: id ?? this.id,
      name: name ?? this.name,
      property: property ?? this.property,
      refines: refines ?? this.refines,
      scheme: scheme ?? this.scheme,
    );
  }
}
