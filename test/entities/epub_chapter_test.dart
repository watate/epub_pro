library epubreadertest;

import 'package:epub_plus/epub_plus.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubChapter(
    anchor: "anchor",
    contentFileName: "orthros",
    htmlContent: "<html></html>",
    subChapters: [],
    title: "A New Look at Chapters",
  );

  late EpubChapter testChapter;
  setUp(() async {
    testChapter = reference.copyWith();
  });

  group("EpubChapter", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testChapter, equals(reference));
      });

      test("is false when HtmlContent changes", () async {
        testChapter = testChapter.copyWith(
            htmlContent: "<html>I'm sure this isn't valid Html</html>");
        expect(testChapter, isNot(reference));
      });

      test("is false when Anchor changes", () async {
        testChapter = testChapter.copyWith(anchor: "NotAnAnchor");
        expect(testChapter, isNot(reference));
      });

      test("is false when ContentFileName changes", () async {
        testChapter = testChapter.copyWith(contentFileName: "NotOrthros");
        expect(testChapter, isNot(reference));
      });

      test("is false when SubChapters changes", () async {
        var chapter = EpubChapter(
          title: "A Brave new Epub",
          contentFileName: "orthros.txt",
        );

        testChapter = testChapter.copyWith(subChapters: [chapter]);
        expect(testChapter, isNot(reference));
      });

      test("is false when Title changes", () async {
        testChapter = testChapter.copyWith(title: "A Boring Old World");
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
        testChapter = testChapter.copyWith(
            htmlContent: "<html>I'm sure this isn't valid Html</html>");
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when Anchor changes", () async {
        testChapter = testChapter.copyWith(anchor: "NotAnAnchor");
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when ContentFileName changes", () async {
        testChapter = testChapter.copyWith(contentFileName: "NotOrthros");
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when SubChapters changes", () async {
        var chapter = EpubChapter(
          title: "A Brave new Epub",
          contentFileName: "orthros.txt",
        );
        testChapter = testChapter.copyWith(subChapters: [chapter]);
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });

      test("is false when Title changes", () async {
        testChapter = testChapter.copyWith(title: "A Boring Old World");
        expect(testChapter.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubChapter {
  EpubChapter copyWith({
    String? anchor,
    String? contentFileName,
    String? htmlContent,
    List<EpubChapter>? subChapters,
    String? title,
  }) {
    return EpubChapter(
      anchor: anchor ?? this.anchor,
      contentFileName: contentFileName ?? this.contentFileName,
      htmlContent: htmlContent ?? this.htmlContent,
      subChapters: subChapters ?? this.subChapters,
      title: title ?? this.title,
    );
  }
}
