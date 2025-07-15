library epubreadertest;

import 'dart:math';

import 'package:epub_pro/src/schema/opf/epub_spine.dart';
import 'package:epub_pro/src/schema/opf/epub_spine_item_ref.dart';
import 'package:test/test.dart';

import '../../random_data_generator_helper.dart';

main() async {
  final int length = 10;
  final RandomString randomString = RandomString(Random(123788));

  final reference = EpubSpine(
    items: [
      EpubSpineItemRef(
        idRef: randomString.randomAlpha(length),
        isLinear: true,
      )
    ],
    tableOfContents: randomString.randomAlpha(length),
    ltr: true,
  );

  late EpubSpine testSpine;

  setUp(() async {
    testSpine = reference.copyWith();
  });

  group("EpubSpine", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testSpine, equals(reference));
      });
      test("is false when Items changes", () async {
        testSpine = testSpine.copyWith(
          items: [
            EpubSpineItemRef(
              idRef: randomString.randomAlpha(length),
              isLinear: false,
            )
          ],
        );
        expect(testSpine, isNot(reference));
      });
      test("is false when TableOfContents changes", () async {
        testSpine = testSpine.copyWith(
          tableOfContents: randomString.randomAlpha(length),
        );
        expect(testSpine, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testSpine.hashCode, equals(reference.hashCode));
      });
      test("is false when IsLinear changes", () async {
        testSpine = testSpine.copyWith(
          items: [
            EpubSpineItemRef(
              idRef: randomString.randomAlpha(length),
              isLinear: false,
            )
          ],
        );
        expect(testSpine.hashCode, isNot(reference.hashCode));
      });
      test("is false when TableOfContents changes", () async {
        testSpine = testSpine.copyWith(
          tableOfContents: randomString.randomAlpha(length),
        );
        expect(testSpine.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubSpine {
  EpubSpine copyWith({
    List<EpubSpineItemRef>? items,
    String? tableOfContents,
    bool? ltr,
  }) {
    return EpubSpine(
      items: items ?? List.from(this.items),
      tableOfContents: tableOfContents ?? this.tableOfContents,
      ltr: ltr ?? this.ltr,
    );
  }
}
