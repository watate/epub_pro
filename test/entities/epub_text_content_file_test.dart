library epubreadertest;

import 'package:epub_plus/epub_plus.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubTextContentFile(
    content: "Hello",
    contentMimeType: "application/test",
    contentType: EpubContentType.other,
    fileName: "orthrosFile",
  );

  late EpubTextContentFile testFile;

  setUp(() async {
    testFile = reference.copyWith();
  });

  group("EpubTextContentFile", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testFile, equals(reference));
      });

      test("is false when Content changes", () async {
        testFile = testFile.copyWith(content: "Goodbye");
        expect(testFile, isNot(reference));
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

      test('changes when Content changes', () async {
        testFile = testFile.copyWith(content: "Goodbye");
        expect(testFile.hashCode, isNot(reference.hashCode));
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

extension on EpubTextContentFile {
  EpubTextContentFile copyWith({
    String? content,
    String? contentMimeType,
    EpubContentType? contentType,
    String? fileName,
  }) {
    return EpubTextContentFile(
      content: content ?? this.content,
      contentMimeType: contentMimeType ?? this.contentMimeType,
      contentType: contentType ?? this.contentType,
      fileName: fileName ?? this.fileName,
    );
  }
}
