library epubreadertest;

import 'package:epub_plus/epub_plus.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubByteContentFile(
    content: [0, 1, 2, 3],
    contentMimeType: "application/test",
    contentType: EpubContentType.other,
    fileName: "orthrosFile",
  );

  late EpubByteContentFile testFile;

  setUp(() async {
    testFile = reference.copyWith();
  });

  group("EpubByteContentFile", () {
    test(".equals is true for equivalent objects", () async {
      expect(testFile, equals(reference));
    });

    test(".equals is false when Content changes", () async {
      testFile = testFile.copyWith(content: [3, 2, 1, 0]);
      expect(testFile, isNot(reference));
    });

    test(".equals is false when ContentMimeType changes", () async {
      testFile = testFile.copyWith(contentMimeType: "application/different");
      expect(testFile, isNot(reference));
    });

    test(".equals is false when ContentType changes", () async {
      testFile = testFile.copyWith(contentType: EpubContentType.css);
      expect(testFile, isNot(reference));
    });

    test(".equals is false when FileName changes", () async {
      testFile = testFile.copyWith(fileName: "a_different_file_name");
      expect(testFile, isNot(reference));
    });

    test(".hashCode is the same for equivalent content", () async {
      expect(testFile.hashCode, equals(reference.hashCode));
    });

    test('.hashCode changes when Content changes', () async {
      testFile = testFile.copyWith(content: [3, 2, 1, 0]);
      expect(testFile.hashCode, isNot(reference.hashCode));
    });

    test('.hashCode changes when ContentMimeType changes', () async {
      testFile = testFile.copyWith(contentMimeType: "application/different");
      expect(testFile.hashCode, isNot(reference.hashCode));
    });

    test('.hashCode changes when ContentType changes', () async {
      testFile = testFile.copyWith(contentType: EpubContentType.css);
      expect(testFile.hashCode, isNot(reference.hashCode));
    });

    test('.hashCode changes when FileName changes', () async {
      testFile = testFile.copyWith(fileName: "a_different_file_name");
      expect(testFile.hashCode, isNot(reference.hashCode));
    });
  });
}

extension on EpubByteContentFile {
  EpubByteContentFile copyWith({
    List<int>? content,
    String? contentMimeType,
    EpubContentType? contentType,
    String? fileName,
  }) {
    return EpubByteContentFile(
      content: content ?? this.content,
      contentMimeType: contentMimeType ?? this.contentMimeType,
      contentType: contentType ?? this.contentType,
      fileName: fileName ?? this.fileName,
    );
  }
}
