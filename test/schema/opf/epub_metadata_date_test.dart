library epubreadertest;

import 'package:epubx/src/schema/opf/epub_metadata_date.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubMetadataDate()
    ..date = "a date"
    ..event = "Some important event";

  late EpubMetadataDate testMetadataDate;

  setUp(() async {
    testMetadataDate = EpubMetadataDate()
      ..date = reference.date
      ..event = reference.event;
  });

  group("EpubMetadataIdentifier", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataDate, equals(reference));
      });

      test("is false when Date changes", () async {
        testMetadataDate.date = "A different Date";
        expect(testMetadataDate, isNot(reference));
      });
      test("is false when Event changes", () async {
        testMetadataDate.event = "A non important event";
        expect(testMetadataDate, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataDate.hashCode, equals(reference.hashCode));
      });

      test("is false when Date changes", () async {
        testMetadataDate.date = "A different date";
        expect(testMetadataDate.hashCode, isNot(reference.hashCode));
      });
      test("is false when Event changes", () async {
        testMetadataDate.event = "A non important event";
        expect(testMetadataDate.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
