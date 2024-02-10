library epubreadertest;

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:epubx/src/ref_entities/epub_content_ref.dart';
import 'package:epubx/src/ref_entities/epub_text_content_file_ref.dart';
import 'package:test/test.dart';

main() async {
  Archive arch = Archive();
  var reference = EpubBookRef(arch);
  reference
    ..Author = "orthros"
    ..AuthorList = ["orthros"]
    ..Schema = EpubSchema()
    ..Title = "A Dissertation on Epubs";

  late EpubBookRef testBookRef;

  setUp(() async {
    testBookRef = EpubBookRef(arch);
    testBookRef
      ..Author = "orthros"
      ..AuthorList = ["orthros"]
      ..Schema = EpubSchema()
      ..Title = "A Dissertation on Epubs";
  });

  group("EpubBookRef", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testBookRef, equals(reference));
      });

      test("is false when Content changes", () async {
        var file = EpubTextContentFileRef(testBookRef);
        file
          ..ContentMimeType = "application/txt"
          ..ContentType = EpubContentType.OTHER
          ..FileName = "orthros.txt";

        EpubContentRef content = EpubContentRef();
        content.AllFiles?["hello"] = file;

        testBookRef.Content = content;

        expect(testBookRef, isNot(reference));
      });

      test("is false when Author changes", () async {
        testBookRef.Author = "NotOrthros";
        expect(testBookRef, isNot(reference));
      });

      test("is false when AuthorList changes", () async {
        testBookRef.AuthorList = ["NotOrthros"];
        expect(testBookRef, isNot(reference));
      });

      test("is false when Schema changes", () async {
        var schema = EpubSchema();
        schema.ContentDirectoryPath = "some/random/path";
        testBookRef.Schema = schema;
        expect(testBookRef, isNot(reference));
      });

      test("is false when Title changes", () async {
        testBookRef.Title = "The Philosophy of Epubs";
        expect(testBookRef, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testBookRef.hashCode, equals(reference.hashCode));
      });

      test("is false when Content changes", () async {
        var file = EpubTextContentFileRef(testBookRef);
        file
          ..ContentMimeType = "application/txt"
          ..ContentType = EpubContentType.OTHER
          ..FileName = "orthros.txt";

        EpubContentRef content = EpubContentRef();
        content.AllFiles?["hello"] = file;

        testBookRef.Content = content;

        expect(testBookRef, isNot(reference));
      });

      test("is false when Author changes", () async {
        testBookRef.Author = "NotOrthros";
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });

      test("is false when AuthorList changes", () async {
        testBookRef.AuthorList = ["NotOrthros"];
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });
      test("is false when Schema changes", () async {
        var schema = EpubSchema();
        schema.ContentDirectoryPath = "some/random/path";
        testBookRef.Schema = schema;
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });

      test("is false when Title changes", () async {
        testBookRef.Title = "The Philosophy of Epubs";
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
