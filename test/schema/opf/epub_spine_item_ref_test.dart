library epubreadertest;

import 'dart:math';

import 'package:epubx/src/schema/opf/epub_spine_item_ref.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final int length = 10;
  final RandomString randomString = RandomString(Random(123788));

  var reference = EpubSpineItemRef()
    ..isLinear = true
    ..idRef = randomString.randomAlpha(length);

  late EpubSpineItemRef testSpineItemRef;

  setUp(() async {
    testSpineItemRef = EpubSpineItemRef()
      ..isLinear = reference.isLinear
      ..idRef = reference.idRef;
  });

  group("EpubSpineItemRef", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testSpineItemRef, equals(reference));
      });
      test("is false when IsLinear changes", () async {
        testSpineItemRef.isLinear = !(testSpineItemRef.isLinear ?? false);

        expect(testSpineItemRef, isNot(reference));
      });
      test("is false when IdRef changes", () async {
        testSpineItemRef.idRef = randomString.randomAlpha(length);
        expect(testSpineItemRef, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testSpineItemRef.hashCode, equals(reference.hashCode));
      });
      test("is false when IsLinear changes", () async {
        testSpineItemRef.isLinear = !(testSpineItemRef.isLinear ?? false);
        expect(testSpineItemRef.hashCode, isNot(reference.hashCode));
      });
      test("is false when IdRef changes", () async {
        testSpineItemRef.idRef = randomString.randomAlpha(length);
        expect(testSpineItemRef.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
