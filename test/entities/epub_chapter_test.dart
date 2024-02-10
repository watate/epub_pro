library epubreadertest;

import 'package:epubx/epubx.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubChapter();
  reference
    ..anchor = "anchor"
    ..contentFileName = "orthros"
    ..htmlContent = "<html></html>"
    ..subChapters = []
    ..title = "A New Look at Chapters";

  late EpubChapter testChapter;
  setUp(() async {
    testChapter = EpubChapter();
    testChapter
      ..anchor = "anchor"
      ..contentFileName = "orthros"
      ..htmlContent = "<html></html>"
      ..subChapters = []
      ..title = "A New Look at Chapters";
  });

  group("EpubChapter", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testChapter, equals(reference));
      });

      test("is false when HtmlContent changes", () async {
        testChapter.htmlContent = "<html>I'm sure this isn't valid Html</html>";
        expect(testChapter, isNot(reference));
      });

      test("is false when Anchor changes", () async {
        testChapter.anchor = "NotAnAnchor";
        expect(testChapter, isNot(reference));
      });

      test("is false when ContentFileName changes", () async {
        testChapter.contentFileName = "NotOrthros";
        expect(testChapter, isNot(reference));
      });

      test("is false when SubChapters changes", () async {
        var chapter = EpubChapter();
        chapter
          ..title = "A Brave new Epub"
          ..contentFileName = "orthros.txt";
        testChapter.subChapters = [chapter];
        expect(testChapter, isNot(reference));
      });

      test("is false when Title changes", () async {
        testChapter.title = "A Boring Old World";
        expect(testChapter, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testChapter.hashCode, equals(reference.hashCode));
      });

      test("is true for equivalent objects", () async {
        expect(testChapter.hashCode, equals(reference.hashCode));
      });

      test("is false when HtmlContent changes", () async {
        testChapter.htmlContent = "<html>I'm sure this isn't valid Html</html>";
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when Anchor changes", () async {
        testChapter.anchor = "NotAnAnchor";
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when ContentFileName changes", () async {
        testChapter.contentFileName = "NotOrthros";
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when SubChapters changes", () async {
        var chapter = EpubChapter();
        chapter
          ..title = "A Brave new Epub"
          ..contentFileName = "orthros.txt";
        testChapter.subChapters = [chapter];
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when Title changes", () async {
        testChapter.title = "A Boring Old World";
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
