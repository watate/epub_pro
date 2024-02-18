library epubreadertest;

import 'package:epub_plus/src/schema/opf/epub_metadata_identifier.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubMetadataIdentifier(
    id: "Unique",
    identifier: "Identifier",
    scheme: "A plot",
  );

  late EpubMetadataIdentifier testMetadataIdentifier;

  setUp(() async {
    testMetadataIdentifier = reference.copyWith();
  });

  group("EpubMetadataIdentifier", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataIdentifier, equals(reference));
      });

      test("is false when Id changes", () async {
        testMetadataIdentifier =
            testMetadataIdentifier.copyWith(id: "Different");
        expect(testMetadataIdentifier, isNot(reference));
      });
      test("is false when Identifier changes", () async {
        testMetadataIdentifier =
            testMetadataIdentifier.copyWith(identifier: "Different");
        expect(testMetadataIdentifier, isNot(reference));
      });
      test("is false when Scheme changes", () async {
        testMetadataIdentifier =
            testMetadataIdentifier.copyWith(scheme: "Different");
        expect(testMetadataIdentifier, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataIdentifier.hashCode, equals(reference.hashCode));
      });

      test("is false when Id changes", () async {
        testMetadataIdentifier =
            testMetadataIdentifier.copyWith(id: "Different");
        expect(testMetadataIdentifier.hashCode, isNot(reference.hashCode));
      });
      test("is false when Identifier changes", () async {
        testMetadataIdentifier =
            testMetadataIdentifier.copyWith(identifier: "Different");
        expect(testMetadataIdentifier.hashCode, isNot(reference.hashCode));
      });
      test("is false when Scheme changes", () async {
        testMetadataIdentifier =
            testMetadataIdentifier.copyWith(scheme: "Different");
        expect(testMetadataIdentifier.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubMetadataIdentifier {
  EpubMetadataIdentifier copyWith({
    String? id,
    String? scheme,
    String? identifier,
  }) {
    return EpubMetadataIdentifier(
      id: id ?? this.id,
      scheme: scheme ?? this.scheme,
      identifier: identifier ?? this.identifier,
    );
  }
}
