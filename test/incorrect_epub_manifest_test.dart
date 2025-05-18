library epubreadertest;

import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:epub_pro/epub_pro.dart';

void main() async {
  final assetsDir = io.Directory(path.join(io.Directory.current.path, "assets"));
  final epubFiles = assetsDir
      .listSync()
      .where((entity) => entity.path.endsWith('.epub'))
      .map((entity) => entity.path)
      .toList();

  for (final filePath in epubFiles) {
    final fileName = path.basename(filePath);
    group('Testing $fileName', () {
      late EpubBookRef epubRef;
      late EpubBook epubBook;
      final targetFile = io.File(filePath);

      setUpAll(() async {
        if (!(await targetFile.exists())) {
          throw Exception("Specified epub file not found: $filePath");
        }
        final bytes = await targetFile.readAsBytes();
        epubRef = await EpubReader.openBook(bytes);
        epubBook = await EpubReader.readBook(bytes);
      });

      test("Check version", () async {
        expect(epubRef.schema?.package?.version, equals(EpubVersion.epub2));
      });

      test("Check chapters", () async {
        var chapters = epubRef.getChapters();
        // print("chapters: $chapters");
        expect(chapters.length, greaterThan(0));
      });

      test("Check metadata", () async {
        expect(epubRef.author, isNotNull);
        expect(epubRef.title, isNotNull);
      });

      test("Check cover", () async {
        final cover = await epubRef.readCover();
        expect(cover, isNotNull);
      });

      test("Check read book", () async {
        final bytes = await targetFile.readAsBytes();
        final book = await EpubReader.readBook(bytes);
        expect(book, isNotNull);
      });

      // test("Check chapter content with readBook", () async {
      //   final chapterContent = epubBook.chapters[6].htmlContent;
      //   print("Chapter: $chapterContent");
      //   expect(chapterContent, isNotNull);
      // });
    });
  }
} 