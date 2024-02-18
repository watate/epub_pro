library epubreadertest;

import 'package:archive/archive.dart';
import 'package:epub_plus/epub_plus.dart';
import 'package:epub_plus/src/ref_entities/epub_byte_content_file_ref.dart';
import 'package:epub_plus/src/ref_entities/epub_content_file_ref.dart';
import 'package:epub_plus/src/ref_entities/epub_content_ref.dart';
import 'package:epub_plus/src/ref_entities/epub_text_content_file_ref.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubContentRef();

  late EpubContentRef testContent;
  late EpubTextContentFileRef textContentFile;
  late EpubByteContentFileRef byteContentFile;

  setUp(() async {
    var arch = Archive();
    var refBook = EpubBookRef(epubArchive: arch);

    testContent = EpubContentRef();

    textContentFile = EpubTextContentFileRef(
      epubBookRef: refBook,
      contentMimeType: "application/text",
      contentType: EpubContentType.other,
      fileName: "orthros.txt",
    );

    byteContentFile = EpubByteContentFileRef(
      epubBookRef: refBook,
      contentMimeType: "application/orthros",
      contentType: EpubContentType.other,
      fileName: "orthros.bin",
    );
  });

  group("EpubContentRef", () {
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

extension on EpubContentRef {
  EpubContentRef copyWith({
    Map<String, EpubTextContentFileRef>? html,
    Map<String, EpubTextContentFileRef>? css,
    Map<String, EpubByteContentFileRef>? images,
    Map<String, EpubByteContentFileRef>? fonts,
    Map<String, EpubContentFileRef>? allFiles,
  }) {
    return EpubContentRef(
      html: html ?? this.html,
      css: css ?? this.css,
      images: images ?? this.images,
      fonts: fonts ?? this.fonts,
      allFiles: allFiles ?? this.allFiles,
    );
  }
}
