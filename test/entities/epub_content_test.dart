library epubreadertest;

import 'package:epub_plus/epub_plus.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubContent();

  late EpubContent testContent;
  late EpubTextContentFile textContentFile;
  late EpubByteContentFile byteContentFile;

  setUp(() async {
    testContent = EpubContent();

    textContentFile = EpubTextContentFile(
      content: "Some string",
      contentMimeType: "application/text",
      contentType: EpubContentType.other,
      fileName: "orthros.txt",
    );

    byteContentFile = EpubByteContentFile(
      content: [0, 1, 2, 3],
      contentMimeType: "application/orthros",
      contentType: EpubContentType.other,
      fileName: "orthros.bin",
    );
  });

  group("EpubContent", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testContent, equals(reference));
      });

      test("is false when Html changes", () async {
        testContent = testContent.copyWith(html: {"someKey": textContentFile});
        expect(testContent, isNot(reference));
      });

      test("is false when Css changes", () async {
        testContent = testContent.copyWith(css: {"someKey": textContentFile});
        expect(testContent, isNot(reference));
      });

      test("is false when Images changes", () async {
        testContent =
            testContent.copyWith(images: {"someKey": byteContentFile});
        expect(testContent, isNot(reference));
      });

      test("is false when Fonts changes", () async {
        testContent = testContent.copyWith(fonts: {"someKey": byteContentFile});
        expect(testContent, isNot(reference));
      });

      test("is false when AllFiles changes", () async {
        testContent =
            testContent.copyWith(allFiles: {"someKey": byteContentFile});
        expect(testContent, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testContent.hashCode, equals(reference.hashCode));
      });

      test("is false when Html changes", () async {
        testContent = testContent.copyWith(html: {"someKey": textContentFile});
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when Css changes", () async {
        testContent = testContent.copyWith(css: {"someKey": textContentFile});
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when Images changes", () async {
        testContent =
            testContent.copyWith(images: {"someKey": byteContentFile});
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when Fonts changes", () async {
        testContent = testContent.copyWith(fonts: {"someKey": byteContentFile});
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when AllFiles changes", () async {
        testContent =
            testContent.copyWith(allFiles: {"someKey": byteContentFile});
        expect(testContent.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubContent {
  EpubContent copyWith({
    Map<String, EpubTextContentFile>? html,
    Map<String, EpubTextContentFile>? css,
    Map<String, EpubByteContentFile>? images,
    Map<String, EpubByteContentFile>? fonts,
    Map<String, EpubContentFile>? allFiles,
  }) {
    return EpubContent(
      html: html ?? this.html,
      css: css ?? this.css,
      images: images ?? this.images,
      fonts: fonts ?? this.fonts,
      allFiles: allFiles ?? this.allFiles,
    );
  }
}
