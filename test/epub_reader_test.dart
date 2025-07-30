library epubreadertest;

import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:epub_pro/epub_pro.dart';

void main() async {
  const fileName = "alicesAdventuresUnderGround.epub";
  String fullPath = path.join(
    io.Directory.current.path,
    "assets",
    fileName,
  );
  final targetFile = io.File(fullPath);

  late EpubBookRef epubRef;

  setUpAll(() async {
    if (!(await targetFile.exists())) {
      throw Exception("Specified epub file not found: $fullPath");
    }

    final bytes = await targetFile.readAsBytes();

    epubRef = await EpubReader.openBook(bytes);
  });

  group('EpubReader', () {
    test("Epub version", () async {
      expect(epubRef.schema?.package?.version, equals(EpubVersion.epub2));
    });

    test("Chapters count and hierarchy", () async {
      var t = epubRef.getChapters();

      // The new implementation makes orphaned spine items standalone chapters
      // Alice's Adventures now has 2 top-level items: orphaned wrap0000.html and Chapter I with sub-chapters
      expect(t.length, equals(2));

      // First is the orphaned wrap0000.html (now standalone)
      expect(t[0].contentFileName, equals('wrap0000.html'));
      expect(t[0].title, equals('wrap0000')); // Now has extracted title

      // Second is Chapter I which contains the actual chapters
      expect(t[1].title, equals("Chapter I"));
      expect(t[1].subChapters.length,
          greaterThan(4)); // Has many sub-items including chapters

      // Verify Chapter II is in the subchapters of Chapter I
      final chapterII = t[1].subChapters.firstWhere(
            (ch) => ch.title == "Chapter II",
            orElse: () => throw Exception("Chapter II not found"),
          );
      expect(chapterII, isNotNull);
    });

    test("Author and title", () async {
      expect(epubRef.author, equals("Lewis Carroll"));
      expect(
        epubRef.title,
        equals(
            '''Alice's Adventures Under Ground / Being a facsimile of the original Ms. book afterwards developed into "Alice's Adventures in Wonderland"'''),
      );
    });

    test("Cover", () async {
      final cover = await epubRef.readCover();
      expect(cover, isNotNull);
      expect(cover?.width, equals(581));
      expect(cover?.height, equals(1034));
    });
  });
}
