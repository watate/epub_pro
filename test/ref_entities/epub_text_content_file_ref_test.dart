library epubreadertest;

import 'package:archive/archive.dart';
import 'package:epub_plus/epub_plus.dart';
import 'package:epub_plus/src/ref_entities/epub_text_content_file_ref.dart';
import 'package:test/test.dart';

main() async {
  var arch = Archive();
  var epubRef = EpubBookRef(epubArchive: arch);

  var reference = EpubTextContentFileRef(
    epubBookRef: epubRef,
    contentMimeType: "application/test",
    contentType: EpubContentType.other,
    fileName: "orthrosFile",
  );

  late EpubTextContentFileRef testFile;

  setUp(() async {
    var arch2 = Archive();
    var epubRef2 = EpubBookRef(epubArchive: arch2);

    testFile = reference.copyWith(epubBookRef: epubRef2);
  });

  group("EpubTextContentFile", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testFile, equals(reference));
      });

      test("is false when ContentMimeType changes", () async {
        testFile = testFile.copyWith(contentMimeType: "application/different");
        expect(testFile, isNot(reference));
      });

      test("is false when ContentType changes", () async {
        testFile = testFile.copyWith(contentType: EpubContentType.css);
        expect(testFile, isNot(reference));
      });

      test("is false when FileName changes", () async {
        testFile = testFile.copyWith(fileName: "a_different_file_name");
        expect(testFile, isNot(reference));
      });
    });
    group(".hashCode", () {
      test("is the same for equivalent content", () async {
        expect(testFile.hashCode, equals(reference.hashCode));
      });

      test('changes when ContentMimeType changes', () async {
        testFile = testFile.copyWith(contentMimeType: "application/different");
        expect(testFile.hashCode, isNot(reference.hashCode));
      });

      test('changes when ContentType changes', () async {
        testFile = testFile.copyWith(contentType: EpubContentType.css);
        expect(testFile.hashCode, isNot(reference.hashCode));
      });

      test('changes when FileName changes', () async {
        testFile = testFile.copyWith(fileName: "a_different_file_name");
        expect(testFile.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubTextContentFileRef {
  EpubTextContentFileRef copyWith({
    EpubBookRef? epubBookRef,
    String? contentMimeType,
    EpubContentType? contentType,
    String? fileName,
  }) {
    return EpubTextContentFileRef(
      epubBookRef: epubBookRef ?? this.epubBookRef,
      contentMimeType: contentMimeType ?? this.contentMimeType,
      contentType: contentType ?? this.contentType,
      fileName: fileName ?? this.fileName,
    );
  }
}
