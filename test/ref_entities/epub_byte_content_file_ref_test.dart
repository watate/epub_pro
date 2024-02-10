library epubreadertest;

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:epubx/src/ref_entities/epub_byte_content_file_ref.dart';
import 'package:test/test.dart';

main() async {
  Archive arch = Archive();
  EpubBookRef ref = EpubBookRef(arch);

  var reference = EpubByteContentFileRef(ref);
  reference
    ..ContentMimeType = "application/test"
    ..ContentType = EpubContentType.OTHER
    ..FileName = "orthrosFile";

  late EpubByteContentFileRef testFileRef;

  setUp(() async {
    Archive arch2 = Archive();
    EpubBookRef ref2 = EpubBookRef(arch2);

    testFileRef = EpubByteContentFileRef(ref2);
    testFileRef
      ..ContentMimeType = "application/test"
      ..ContentType = EpubContentType.OTHER
      ..FileName = "orthrosFile";
  });

  group("EpubByteContentFileRef", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testFileRef, equals(reference));
      });

      test("is false when ContentMimeType changes", () async {
        testFileRef.ContentMimeType = "application/different";
        expect(testFileRef, isNot(reference));
      });

      test("is false when ContentType changes", () async {
        testFileRef.ContentType = EpubContentType.CSS;
        expect(testFileRef, isNot(reference));
      });

      test("is false when FileName changes", () async {
        testFileRef.FileName = "a_different_file_name.txt";
        expect(testFileRef, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is the same for equivalent content", () async {
        expect(testFileRef.hashCode, equals(reference.hashCode));
      });

      test('changes when ContentMimeType changes', () async {
        testFileRef.ContentMimeType = "application/orthros";
        expect(testFileRef.hashCode, isNot(reference.hashCode));
      });

      test('changes when ContentType changes', () async {
        testFileRef.ContentType = EpubContentType.CSS;
        expect(testFileRef.hashCode, isNot(reference.hashCode));
      });

      test('changes when FileName changes', () async {
        testFileRef.FileName = "a_different_file_name";
        expect(testFileRef.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
