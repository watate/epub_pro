library epubreadertest;

import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:epub_pro/epub_pro.dart';

main() async {
  String fileName = "alicesAdventuresUnderGround.epub";
  String fullPath =
      path.join(io.Directory.current.path, "assets", fileName);
  var targetFile = io.File(fullPath);
  if (!(await targetFile.exists())) {
    throw Exception("Specified epub file not found: $fullPath");
  }
  List<int> bytes = await targetFile.readAsBytes();
  test("Test Epub Image", () async {
    EpubBook epubRef = await EpubReader.readBook(bytes);

    expect(epubRef.coverImage, isNotNull);

    // expect(3, epubRef.CoverImage.format);
    // expect(581, epubRef.CoverImage.width);
    // expect(1034, epubRef.CoverImage.height);
  });

  test("Test Epub Ref Image", () async {
    EpubBookRef epubRef = await EpubReader.openBook(bytes);

    Image? coverImage = await epubRef.readCover();

    expect(coverImage, isNotNull);

    // expect(3, coverImage.format);
    // expect(581, coverImage.width);
    // expect(1034, coverImage.height);
  });
}
