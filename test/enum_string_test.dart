library epubtest;

import 'package:test/test.dart';

import 'package:epub_plus/epub_plus.dart';

void main() {
  group('EnumFromString', () {
    test("Enum One", () {
      expect(
        EnumFromString<Simple>(Simple.values).get("ONE"),
        equals(Simple.one),
      );
    });

    test("Enum Two", () {
      expect(
        EnumFromString<Simple>(Simple.values).get("TWO"),
        equals(Simple.two),
      );
    });

    test("Enum One Lower Case", () {
      expect(
        EnumFromString<Simple>(Simple.values).get("one"),
        equals(Simple.one),
      );
    });

    test("Enum null", () {
      expect(EnumFromString<Simple>(Simple.values).get("null"), isNull);
    });
  });
}

enum Simple { one, two, three }
