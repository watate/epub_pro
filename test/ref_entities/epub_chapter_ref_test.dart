library epubreadertest;

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:epubx/src/ref_entities/epub_text_content_file_ref.dart';
import 'package:test/test.dart';

main() async {
  var arch = Archive();
  var bookRef = EpubBookRef(arch);
  var contentFileRef = EpubTextContentFileRef(bookRef);
  var reference = EpubChapterRef(contentFileRef);

  reference
    ..Anchor = "anchor"
    ..ContentFileName = "orthros"
    ..SubChapters = []
    ..Title = "A New Look at Chapters";

  late EpubBookRef bookRef2;
  late EpubChapterRef testChapterRef;

  setUp(() async {
    var arch2 = Archive();
    bookRef2 = EpubBookRef(arch2);
    var contentFileRef2 = EpubTextContentFileRef(bookRef2);

    testChapterRef = EpubChapterRef(contentFileRef2);
    testChapterRef
      ..Anchor = "anchor"
      ..ContentFileName = "orthros"
      ..SubChapters = []
      ..Title = "A New Look at Chapters";
  });

  group("EpubChapterRef", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testChapterRef, equals(reference));
      });

      test("is false when Anchor changes", () async {
        testChapterRef.Anchor = "NotAnAnchor";
        expect(testChapterRef, isNot(reference));
      });

      test("is false when ContentFileName changes", () async {
        testChapterRef.ContentFileName = "NotOrthros";
        expect(testChapterRef, isNot(reference));
      });

      test("is false when SubChapters changes", () async {
        var subchapterContentFileRef = EpubTextContentFileRef(bookRef2);
        var chapter = EpubChapterRef(subchapterContentFileRef);
        chapter
          ..Title = "A Brave new Epub"
          ..ContentFileName = "orthros.txt";
        testChapterRef.SubChapters = [chapter];
        expect(testChapterRef, isNot(reference));
      });

      test("is false when Title changes", () async {
        testChapterRef.Title = "A Boring Old World";
        expect(testChapterRef, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testChapterRef.hashCode, equals(reference.hashCode));
      });

      test("is true for equivalent objects", () async {
        expect(testChapterRef.hashCode, equals(reference.hashCode));
      });

      test("is false when Anchor changes", () async {
        testChapterRef.Anchor = "NotAnAnchor";
        expect(testChapterRef.hashCode, isNot(reference.hashCode));
      });

      test("is false when ContentFileName changes", () async {
        testChapterRef.ContentFileName = "NotOrthros";
        expect(testChapterRef.hashCode, isNot(reference.hashCode));
      });

      test("is false when SubChapters changes", () async {
        var subchapterContentFileRef = EpubTextContentFileRef(bookRef2);
        var chapter = EpubChapterRef(subchapterContentFileRef);
        chapter
          ..Title = "A Brave new Epub"
          ..ContentFileName = "orthros.txt";
        testChapterRef.SubChapters = [chapter];
        expect(testChapterRef, isNot(reference));
      });

      test("is false when Title changes", () async {
        testChapterRef.Title = "A Boring Old World";
        expect(testChapterRef.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
