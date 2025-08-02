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

      // After fixing duplicate detection, Alice's Adventures now has 4 top-level chapters:
      // - wrap0000.html (orphaned spine item)
      // - Main title page content (duplicate references consolidated)  
      // - Chapter III
      // - THE END
      expect(t.length, equals(4));

      // First is the orphaned wrap0000.html (now standalone)
      expect(t[0].contentFileName, equals('wrap0000.html'));
      expect(t[0].title, equals('wrap0000')); // Now has extracted title

      // Second is the consolidated title page content
      expect(t[1].title, equals("ALICE'S ADVENTURES UNDER GROUND"));
      expect(t[1].contentFileName, equals('@public@vhost@g@gutenberg@html@files@19002@19002-h@19002-h-0.htm.html'));

      // Third is Chapter III 
      expect(t[2].title, equals("Chapter III"));

      // Fourth is THE END
      expect(t[3].title, equals("THE END."));

      // After duplicate detection fix, Chapter II is no longer present because
      // it referenced the same HTML file as Chapter I (just different anchor)
      // This is the correct behavior - duplicate file references are filtered out
      expect(t[1].subChapters.length, equals(0));
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
