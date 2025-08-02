import 'dart:io' as io;

import 'package:epub_pro/epub_pro.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('BlackSwan Duplicate TOC Tests', () {
    late EpubBookRef blackSwanRef;

    setUpAll(() async {
      // Load blackSwan.epub if it exists
      final blackSwanPath = path.join(
        io.Directory.current.path,
        'assets',
        'blackSwan.epub',
      );
      final blackSwanFile = io.File(blackSwanPath);

      // Only run if the file exists
      if (!(await blackSwanFile.exists())) {
        return; // Skip setup if file doesn't exist
      }

      final blackSwanBytes = await blackSwanFile.readAsBytes();
      blackSwanRef = await EpubReader.openBook(blackSwanBytes);
    });

    test(
        'should not have duplicate TOC entries for same file with different anchors',
        () async {
      // Check if blackSwan.epub exists
      final blackSwanPath = path.join(
        io.Directory.current.path,
        'assets',
        'blackSwan.epub',
      );
      final blackSwanFile = io.File(blackSwanPath);

      if (!(await blackSwanFile.exists())) {
        // Skip test if file doesn't exist
        print('Skipping test: blackSwan.epub not found at $blackSwanPath');
        return;
      }

      final chapters = blackSwanRef.getChapters();

      // Collect all content file names (without anchors) from chapters
      final contentFileNames = <String>[];

      void collectContentFileNames(List<EpubChapterRef> chapters) {
        for (final chapter in chapters) {
          if (chapter.contentFileName != null) {
            contentFileNames.add(chapter.contentFileName!);
          }
          // Recursively collect from sub-chapters
          if (chapter.subChapters.isNotEmpty) {
            collectContentFileNames(chapter.subChapters);
          }
        }
      }

      collectContentFileNames(chapters);

      // Check for duplicates - should not have any
      final uniqueContentFiles = contentFileNames.toSet();
      expect(contentFileNames.length, equals(uniqueContentFiles.length),
          reason:
              'Found duplicate content files in TOC: ${contentFileNames.where((file) => contentFileNames.where((f) => f == file).length > 1).toSet()}');

      // Specifically check for the problematic file from blackSwan.epub
      final part0004Files = contentFileNames
          .where((file) => file.contains('part0004_split_000.html'))
          .toList();
      expect(part0004Files.length, equals(1),
          reason:
              'part0004_split_000.html should appear only once in TOC, but found ${part0004Files.length} times');
    });

    test('should maintain proper chapter hierarchy despite skipping duplicates',
        () async {
      // Check if blackSwan.epub exists
      final blackSwanPath = path.join(
        io.Directory.current.path,
        'assets',
        'blackSwan.epub',
      );
      final blackSwanFile = io.File(blackSwanPath);

      if (!(await blackSwanFile.exists())) {
        // Skip test if file doesn't exist
        print('Skipping test: blackSwan.epub not found at $blackSwanPath');
        return;
      }

      final chapters = blackSwanRef.getChapters();

      // Should still have chapters
      expect(chapters.isNotEmpty, isTrue);

      // Look for the Prologue chapter that should have been kept (first occurrence)
      final prologueChapter = chapters
          .where((ch) => (ch.title?.contains('Prologue') ?? false))
          .toList();
      expect(prologueChapter.length, equals(1),
          reason: 'Should have exactly one Prologue chapter');

      // The Prologue should reference part0004_split_000.html
      expect(prologueChapter.first.contentFileName,
          equals('text/part0004_split_000.html'));
    });
  });
}
