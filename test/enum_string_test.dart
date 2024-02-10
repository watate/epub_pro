library epubtest;

import 'package:test/test.dart';

import 'package:epubx/epubx.dart';

main() {
  test("Enum One", () {
    expect(
        EnumFromString<Simple>(Simple.values).get("ONE"), equals(Simple.one));
  });
  test("Enum Two", () {
    expect(
        EnumFromString<Simple>(Simple.values).get("TWO"), equals(Simple.two));
  });
  test("Enum One", () {
    expect(EnumFromString<Simple>(Simple.values).get("THREE"),
        equals(Simple.three));
  });
  test("Enum One Lower Case", () {
    expect(
        EnumFromString<Simple>(Simple.values).get("one"), equals(Simple.one));
  });
}

enum Simple { one, two, three }
