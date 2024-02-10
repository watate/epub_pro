library epubreadertest;

import 'package:epubx/epubx.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubBook();
  reference
    ..Author = "orthros"
    ..AuthorList = ["orthros"]
    ..Chapters = [EpubChapter()]
    ..Content = EpubContent()
    ..CoverImage = Image(width: 100, height: 100)
    ..Schema = EpubSchema()
    ..title = "A Dissertation on Epubs";

  late EpubBook testBook;
  setUp(() async {
    testBook = EpubBook();
    testBook
      ..Author = "orthros"
      ..AuthorList = ["orthros"]
      ..Chapters = [EpubChapter()]
      ..Content = EpubContent()
      ..CoverImage = Image(width: 100, height: 100)
      ..Schema = EpubSchema()
      ..title = "A Dissertation on Epubs";
  });

  group("EpubBook", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testBook, equals(reference));
      });

      test("is false when Content changes", () async {
        var file = EpubTextContentFile();
        file
          ..Content = "Hello"
          ..ContentMimeType = "application/txt"
          ..ContentType = EpubContentType.OTHER
          ..FileName = "orthros.txt";

        EpubContent content = EpubContent();
        content.AllFiles?["hello"] = file;
        testBook.Content = content;

        expect(testBook, isNot(reference));
      });

      test("is false when Author changes", () async {
        testBook.Author = "NotOrthros";
        expect(testBook, isNot(reference));
      });

      test("is false when AuthorList changes", () async {
        testBook.AuthorList = ["NotOrthros"];
        expect(testBook, isNot(reference));
      });

      test("is false when Chapters changes", () async {
        var chapter = EpubChapter();
        chapter
          ..Title = "A Brave new Epub"
          ..ContentFileName = "orthros.txt";
        testBook.Chapters = [chapter];
        expect(testBook, isNot(reference));
      });

      test("is false when CoverImage changes", () async {
        testBook.CoverImage = Image(width: 200, height: 200);
        expect(testBook, isNot(reference));
      });

      test("is false when Schema changes", () async {
        var schema = EpubSchema();
        schema.ContentDirectoryPath = "some/random/path";
        testBook.Schema = schema;
        expect(testBook, isNot(reference));
      });

      test("is false when Title changes", () async {
        testBook.title = "The Philosophy of Epubs";
        expect(testBook, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testBook.hashCode, equals(reference.hashCode));
      });

      test("is false when Content changes", () async {
        var file = EpubTextContentFile();
        file
          ..Content = "Hello"
          ..ContentMimeType = "application/txt"
          ..ContentType = EpubContentType.OTHER
          ..FileName = "orthros.txt";

        EpubContent content = EpubContent();
        content.AllFiles?["hello"] = file;
        testBook.Content = content;

        expect(testBook.hashCode, isNot(reference.hashCode));
      });

      test("is false when Author changes", () async {
        testBook.Author = "NotOrthros";
        expect(testBook.hashCode, isNot(reference.hashCode));
      });

      test("is false when AuthorList changes", () async {
        testBook.AuthorList = ["NotOrthros"];
        expect(testBook.hashCode, isNot(reference.hashCode));
      });

      test("is false when Chapters changes", () async {
        var chapter = EpubChapter();
        chapter
          ..Title = "A Brave new Epub"
          ..ContentFileName = "orthros.txt";
        testBook.Chapters = [chapter];
        expect(testBook.hashCode, isNot(reference.hashCode));
      });

      test("is false when CoverImage changes", () async {
        testBook.CoverImage = Image(width: 200, height: 200);
        expect(testBook.hashCode, isNot(reference.hashCode));
      });

      test("is false when Schema changes", () async {
        var schema = EpubSchema();
        schema.ContentDirectoryPath = "some/random/path";
        testBook.Schema = schema;
        expect(testBook.hashCode, isNot(reference.hashCode));
      });

      test("is false when Title changes", () async {
        testBook.title = "The Philosophy of Epubs";
        expect(testBook.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
