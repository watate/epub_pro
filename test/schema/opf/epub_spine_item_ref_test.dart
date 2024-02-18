library epubreadertest;

import 'dart:math';

import 'package:epub_plus/src/schema/opf/epub_spine_item_ref.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final int length = 10;
  final RandomString randomString = RandomString(Random(123788));

  var reference = EpubSpineItemRef(
    idRef: randomString.randomAlpha(length),
    isLinear: true,
  );

  late EpubSpineItemRef testSpineItemRef;

  setUp(() async {
    testSpineItemRef = reference.copyWith();
  });

  group("EpubSpineItemRef", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testSpineItemRef, equals(reference));
      });
      test("is false when IsLinear changes", () async {
        testSpineItemRef =
            testSpineItemRef.copyWith(isLinear: !testSpineItemRef.isLinear);

        expect(testSpineItemRef, isNot(reference));
      });
      test("is false when IdRef changes", () async {
        testSpineItemRef =
            testSpineItemRef.copyWith(idRef: randomString.randomAlpha(length));
        expect(testSpineItemRef, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testSpineItemRef.hashCode, equals(reference.hashCode));
      });
      test("is false when IsLinear changes", () async {
        testSpineItemRef =
            testSpineItemRef.copyWith(isLinear: !testSpineItemRef.isLinear);
        expect(testSpineItemRef.hashCode, isNot(reference.hashCode));
      });
      test("is false when IdRef changes", () async {
        testSpineItemRef =
            testSpineItemRef.copyWith(idRef: randomString.randomAlpha(length));
        expect(testSpineItemRef.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubSpineItemRef {
  EpubSpineItemRef copyWith({
    String? idRef,
    bool? isLinear,
  }) {
    return EpubSpineItemRef(
      idRef: idRef ?? this.idRef,
      isLinear: isLinear ?? this.isLinear,
    );
  }
}
