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
      
      // The new implementation preserves the NCX hierarchy better
      // Alice's Adventures has 3 top-level items, with chapters nested under Chapter I
      expect(t.length, equals(3));
      
      // First is the orphaned wrap0000.html
      expect(t[0].contentFileName, equals('wrap0000.html'));
      expect(t[0].title, isNull);
      
      // Second is the title/front matter
      expect(t[1].title, equals("ALICE'S ADVENTURES UNDER GROUND"));
      expect(t[1].subChapters.length, equals(3)); // Has 3 sub-items
      
      // Third is Chapter I which contains the actual chapters
      expect(t[2].title, equals("Chapter I"));
      expect(t[2].subChapters.length, greaterThan(4)); // Has many sub-items including chapters
      
      // Verify Chapter II is in the subchapters of Chapter I
      final chapterII = t[2].subChapters.firstWhere(
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
