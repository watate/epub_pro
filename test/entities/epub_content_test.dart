library epubreadertest;

import 'package:epubx/epubx.dart';
import 'package:test/test.dart';

main() async {
  var reference = EpubContent();

  late EpubContent testContent;
  late EpubTextContentFile textContentFile;
  late EpubByteContentFile byteContentFile;

  setUp(() async {
    testContent = EpubContent();

    textContentFile = EpubTextContentFile();
    textContentFile
      ..Content = "Some string"
      ..ContentMimeType = "application/text"
      ..ContentType = EpubContentType.OTHER
      ..FileName = "orthros.txt";

    byteContentFile = EpubByteContentFile()
      ..Content = [0, 1, 2, 3]
      ..ContentMimeType = "application/orthros"
      ..ContentType = EpubContentType.OTHER
      ..FileName = "orthros.bin";
  });

  group("EpubContent", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testContent, equals(reference));
      });

      test("is false when Html changes", () async {
        testContent.Html?["someKey"] = textContentFile;
        expect(testContent, isNot(reference));
      });

      test("is false when Css changes", () async {
        testContent.Css?["someKey"] = textContentFile;
        expect(testContent, isNot(reference));
      });

      test("is false when Images changes", () async {
        testContent.Images?["someKey"] = byteContentFile;
        expect(testContent, isNot(reference));
      });

      test("is false when Fonts changes", () async {
        testContent.Fonts?["someKey"] = byteContentFile;
        expect(testContent, isNot(reference));
      });

      test("is false when AllFiles changes", () async {
        testContent.AllFiles?["someKey"] = byteContentFile;
        expect(testContent, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testContent.hashCode, equals(reference.hashCode));
      });

      test("is false when Html changes", () async {
        testContent.Html?["someKey"] = textContentFile;
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when Css changes", () async {
        testContent.Css?["someKey"] = textContentFile;
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when Images changes", () async {
        testContent.Images?["someKey"] = byteContentFile;
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when Fonts changes", () async {
        testContent.Fonts?["someKey"] = byteContentFile;
        expect(testContent.hashCode, isNot(reference.hashCode));
      });

      test("is false when AllFiles changes", () async {
        testContent.AllFiles?["someKey"] = byteContentFile;
        expect(testContent.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
