library epubreadertest;

import 'package:archive/archive.dart';
import 'package:epub_plus/epub_plus.dart';
import 'package:epub_plus/src/ref_entities/epub_content_ref.dart';
import 'package:epub_plus/src/ref_entities/epub_text_content_file_ref.dart';
import 'package:test/test.dart';

main() async {
  Archive arch = Archive();
  var reference = EpubBookRef(
    epubArchive: arch,
    author: "orthros",
    authors: ["orthros"],
    schema: EpubSchema(),
    title: "A Dissertation on Epubs",
  );

  late EpubBookRef testBookRef;

  setUp(() async {
    testBookRef = reference.copyWith();
  });

  group("EpubBookRef", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testBookRef, equals(reference));
      });

      test("is false when Content changes", () async {
        var file = EpubTextContentFileRef(
          epubBookRef: testBookRef,
          contentMimeType: "application/txt",
          contentType: EpubContentType.other,
          fileName: "orthros.txt",
        );

        EpubContentRef content = EpubContentRef(
          allFiles: {"hello": file},
        );

        testBookRef = testBookRef.copyWith(content: content);

        expect(testBookRef, isNot(reference));
      });

      test("is false when Author changes", () async {
        testBookRef = testBookRef.copyWith(author: "NotOrthros");
        expect(testBookRef, isNot(reference));
      });

      test("is false when AuthorList changes", () async {
        testBookRef = testBookRef.copyWith(authors: ["NotOrthros"]);
        expect(testBookRef, isNot(reference));
      });

      test("is false when Schema changes", () async {
        var schema = EpubSchema(
          contentDirectoryPath: "some/random/path",
        );
        testBookRef = testBookRef.copyWith(schema: schema);
        expect(testBookRef, isNot(reference));
      });

      test("is false when Title changes", () async {
        testBookRef = testBookRef.copyWith(title: "The Philosophy of Epubs");
        expect(testBookRef, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testBookRef.hashCode, equals(reference.hashCode));
      });

      test("is false when Content changes", () async {
        var file = EpubTextContentFileRef(
          epubBookRef: testBookRef,
          contentMimeType: "application/txt",
          contentType: EpubContentType.other,
          fileName: "orthros.txt",
        );

        EpubContentRef content = EpubContentRef(
          allFiles: {"hello": file},
        );

        testBookRef = testBookRef.copyWith(content: content);

        expect(testBookRef, isNot(reference));
      });

      test("is false when Author changes", () async {
        testBookRef = testBookRef.copyWith(author: "NotOrthros");
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });

      test("is false when AuthorList changes", () async {
        testBookRef = testBookRef.copyWith(authors: ["NotOrthros"]);
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });
      test("is false when Schema changes", () async {
        var schema = EpubSchema(
          contentDirectoryPath: "some/random/path",
        );
        testBookRef = testBookRef.copyWith(schema: schema);
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });

      test("is false when Title changes", () async {
        testBookRef = testBookRef.copyWith(title: "The Philosophy of Epubs");
        expect(testBookRef.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubBookRef {
  EpubBookRef copyWith({
    Archive? epubArchive,
    String? title,
    List<String>? authors,
    String? author,
    EpubSchema? schema,
    EpubContentRef? content,
  }) {
    return EpubBookRef(
      epubArchive: epubArchive ?? this.epubArchive,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      author: author ?? this.author,
      schema: schema ?? this.schema,
      content: content ?? this.content,
    );
  }
}
