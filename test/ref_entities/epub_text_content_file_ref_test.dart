library epubreadertest;

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:epubx/src/ref_entities/epub_text_content_file_ref.dart';
import 'package:test/test.dart';

main() async {
  var arch = Archive();
  var epubRef = EpubBookRef(arch);

  var reference = EpubTextContentFileRef(epubRef);
  reference
    ..ContentMimeType = "application/test"
    ..ContentType = EpubContentType.OTHER
    ..FileName = "orthrosFile";
  late EpubTextContentFileRef testFile;

  setUp(() async {
    var arch2 = Archive();
    var epubRef2 = EpubBookRef(arch2);

    testFile = EpubTextContentFileRef(epubRef2);
    testFile
      ..ContentMimeType = "application/test"
      ..ContentType = EpubContentType.OTHER
      ..FileName = "orthrosFile";
  });

  group("EpubTextContentFile", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testFile, equals(reference));
      });

      test("is false when ContentMimeType changes", () async {
        testFile.ContentMimeType = "application/different";
        expect(testFile, isNot(reference));
      });

      test("is false when ContentType changes", () async {
        testFile.ContentType = EpubContentType.CSS;
        expect(testFile, isNot(reference));
      });

      test("is false when FileName changes", () async {
        testFile.FileName = "a_different_file_name.txt";
        expect(testFile, isNot(reference));
      });
    });
    group(".hashCode", () {
      test("is the same for equivalent content", () async {
        expect(testFile.hashCode, equals(reference.hashCode));
      });

      test('changes when ContentMimeType changes', () async {
        testFile.ContentMimeType = "application/orthros";
        expect(testFile.hashCode, isNot(reference.hashCode));
      });

      test('changes when ContentType changes', () async {
        testFile.ContentType = EpubContentType.CSS;
        expect(testFile.hashCode, isNot(reference.hashCode));
      });

      test('changes when FileName changes', () async {
        testFile.FileName = "a_different_file_name";
        expect(testFile.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
