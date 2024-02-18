library epubreadertest;

import 'package:epub_plus/src/schema/opf/epub_metadata_date.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubMetadataDate(
    date: "a date",
    event: "Some important event",
  );

  late EpubMetadataDate testMetadataDate;

  setUp(() async {
    testMetadataDate = reference.copyWith();
  });

  group("EpubMetadataIdentifier", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataDate, equals(reference));
      });

      test("is false when Date changes", () async {
        testMetadataDate = testMetadataDate.copyWith(date: "A different date");
        expect(testMetadataDate, isNot(reference));
      });
      test("is false when Event changes", () async {
        testMetadataDate =
            testMetadataDate.copyWith(event: "A non important event");
        expect(testMetadataDate, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testMetadataDate.hashCode, equals(reference.hashCode));
      });

      test("is false when Date changes", () async {
        testMetadataDate = testMetadataDate.copyWith(date: "A different date");
        expect(testMetadataDate.hashCode, isNot(reference.hashCode));
      });
      test("is false when Event changes", () async {
        testMetadataDate =
            testMetadataDate.copyWith(event: "A non important event");
        expect(testMetadataDate.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubMetadataDate {
  EpubMetadataDate copyWith({
    String? date,
    String? event,
  }) {
    return EpubMetadataDate(
      date: date ?? this.date,
      event: event ?? this.event,
    );
  }
}
