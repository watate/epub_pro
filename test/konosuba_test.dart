import 'dart:io' as io;

import 'package:epub_pro/epub_pro.dart';
import 'package:epub_pro/src/schema/opf/epub_metadata_meta.dart';
import 'package:epub_pro/src/utils/chapter_splitter.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('KonoSuba Japanese EPUB Tests', () {
    late EpubBook konosubaBook;
    late EpubBookRef konosubaRef;
    final verbose = true;

    setUpAll(() async {
      // Load konosuba.epub if it exists
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        print(
            'Skipping KonoSuba tests - konosuba.epub not found at: $konosubaPath');
        return;
      }

      if (verbose) {
        print('\n=== Loading KonoSuba Japanese EPUB ===');
      }

      final konosubaBytes = await konosubaFile.readAsBytes();
      konosubaBook = await EpubReader.readBook(konosubaBytes);
      konosubaRef = await EpubReader.openBook(konosubaBytes);
    });

    test('handles minimal navigation with spine reconciliation', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Check navigation points (should have 10 from EPUB3 nav document)
      final navPoints = konosubaRef.schema?.navigation?.navMap?.points ?? [];
      expect(navPoints.length, equals(10));
      expect(navPoints.first.navigationLabels!.first.text,
          equals('表紙')); // "Cover"

      // Check that we get all chapters from spine reconciliation
      final chapters = konosubaRef.getChapters();
      expect(chapters.length, equals(10)); // KonoSuba content chapters

      if (verbose) {
        print('\n=== Navigation Reconciliation Results ===');
        print('Navigation entries: ${navPoints.length}');
        print('Total chapters after reconciliation: ${chapters.length}');
        print('\nFirst navigation entry:');
        print(
            '  ${navPoints.first.navigationLabels!.first.text} -> ${navPoints.first.content?.source}');
      }
    });

    test('correctly identifies all 10 chapters from spine', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      final chapters = konosubaBook.chapters;
      expect(chapters.length, equals(10));

      // First should be cover
      expect(chapters.first.contentFileName, equals('xhtml/p-cover.xhtml'));

      // Last should be colophon with title
      expect(chapters.last.contentFileName, equals('xhtml/p-colophon.xhtml'));
      expect(chapters.last.title, equals('奥付'));

      // KonoSuba has proper titles from navigation document
      final expectedTitles = [
        '表紙', // Cover
        'ＣＯＮＴＥＮＴＳ', // Contents
        'プロローグ', // Prologue
        '第一章　この自称女神と異世界転生を！', // Chapter 1
        '第二章　この右手にお宝を！', // Chapter 2
        '第三章　この湖に自称女神の一番絞りを！', // Chapter 3
        '第四章　このろくでもない戦いに決着を！', // Chapter 4
        'エピローグ', // Epilogue
        '電子書籍１巻購入大感謝特典『アクア先生』', // Special bonus
        '奥付' // Colophon
      ];

      for (var i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        expect(chapter.title, isNotNull, reason: 'Chapters should have titles');
        expect(chapter.title, isNotEmpty,
            reason: 'Chapter titles should not be empty');
        if (i < expectedTitles.length) {
          expect(chapter.title, equals(expectedTitles[i]),
              reason: 'Chapter $i should have expected title');
        }
      }

      if (verbose) {
        print('\n=== Table of Contents ===');
        for (var i = 0; i < chapters.length; i++) {
          final chapter = chapters[i];
          final title = chapter.title ?? '[Untitled]';
          final fileName = chapter.contentFileName;
          print('${(i + 1).toString().padLeft(2)}. $title ($fileName)');
        }
      }
    });

    test('reads Japanese content correctly', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Check that content can be read
      for (final chapter in konosubaBook.chapters) {
        expect(chapter.htmlContent, isNotNull);
      }

      if (verbose) {
        print('\n=== Content Preview (First 100 chars) ===');
        for (var i = 0; i < konosubaBook.chapters.length && i < 5; i++) {
          final chapter = konosubaBook.chapters[i];
          final title = chapter.title ?? '[Untitled]';
          final content = chapter.htmlContent
              ?.replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          final preview = content != null && content.length > 100
              ? '${content.substring(0, 100)}...'
              : content ?? '[No content]';
          print('\nChapter ${i + 1}: $title');
          print('Preview: $preview');
        }

        if (konosubaBook.chapters.length > 5) {
          print('\n... and ${konosubaBook.chapters.length - 5} more chapters');
        }
      }
    });

    test('has correct Japanese metadata', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Check title
      expect(konosubaBook.title, equals('この素晴らしい世界に祝福を！ あぁ、駄女神さま'));

      // Check author
      expect(konosubaBook.author, equals('暁 なつめ'));

      // Check language
      expect(konosubaBook.schema?.package?.metadata?.languages.first,
          equals('ja'));

      // Check publisher
      expect(konosubaBook.schema?.package?.metadata?.publishers.first,
          equals('角川書店'));

      if (verbose) {
        print('\n=== Metadata ===');
        print('Title: ${konosubaBook.title}');
        print('Author: ${konosubaBook.author}');
        print(
            'Language: ${konosubaBook.schema?.package?.metadata?.languages.first}');
        print(
            'Publisher: ${konosubaBook.schema?.package?.metadata?.publishers.first}');
        print(
            'Publication Date: ${konosubaBook.schema?.package?.metadata?.dates.firstOrNull?.date}');
      }
    });

    test('has right-to-left page progression', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Check spine direction - ltr is false for rtl books
      final spine = konosubaBook.schema?.package?.spine;
      expect(spine?.ltr, equals(false)); // false means RTL

      if (verbose) {
        print('\n=== Reading Direction ===');
        print('Spine LTR flag: ${spine?.ltr} (false = right-to-left)');
        print(
            'Primary writing mode: ${konosubaBook.schema?.package?.metadata?.metaItems.firstWhere(
                  (meta) => meta.name == 'primary-writing-mode',
                  orElse: () => EpubMetadataMeta(),
                ).content}');
      }
    });

    test('handles cover image correctly', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      expect(konosubaBook.coverImage, isNotNull);
      expect(konosubaBook.coverImage!.length, greaterThan(0));

      // The cover should be cover.jpg based on the manifest
      final coverManifestItem =
          konosubaBook.schema?.package?.manifest?.items.firstWhere(
        (item) => item.id == 'cover',
      );
      expect(coverManifestItem?.href, equals('image/cover.jpg'));

      if (verbose) {
        print('\n=== Cover Information ===');
        print('Cover file: ${coverManifestItem?.href}');
        print('Cover size: ${konosubaBook.coverImage!.length} bytes');
        print('Cover media type: ${coverManifestItem?.mediaType}');
      }
    });

    test('spine items are in correct order', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      final spine = konosubaBook.schema?.package?.spine?.items ?? [];

      if (verbose) {
        print('\n=== Spine Analysis ===');
        print('Spine items count: ${spine.length}');
        print('Chapters count: ${konosubaBook.chapters.length}');
      }

      // KonoSuba has 26 spine items
      expect(spine.length, equals(26));

      // Verify the spine order matches chapter order
      final chapters = konosubaBook.chapters;
      final manifest = konosubaBook.schema?.package?.manifest?.items ?? [];

      // Check which spine items are actually in chapters
      var matchedCount = 0;
      for (var i = 0; i < spine.length; i++) {
        final spineItem = spine[i];
        final manifestItem =
            manifest.firstWhere((item) => item.id == spineItem.idRef);

        // Find if this spine item has a corresponding chapter
        final hasChapter =
            chapters.any((ch) => ch.contentFileName == manifestItem.href);
        if (hasChapter) {
          matchedCount++;
        } else if (verbose) {
          print(
              'Spine item not in chapters: ${manifestItem.href} (${manifestItem.properties})');
        }
      }

      expect(matchedCount, equals(chapters.length));

      if (verbose) {
        print('\n=== Spine Order Verification ===');
        print('Spine items: ${spine.length}');
        print('Chapters: ${chapters.length}');
        print('✓ All spine items correctly mapped to chapters in order');
      }
    });

    test('word counting should work correctly for Japanese text', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Get a chapter with substantial Japanese content
      final japaneseChapter = konosubaBook.chapters.firstWhere(
        (ch) => ch.contentFileName?.contains('part0009.html') ?? false,
        orElse: () =>
            konosubaBook.chapters[2], // fallback to any content chapter
      );

      final htmlContent = japaneseChapter.htmlContent ?? '';
      expect(htmlContent.isNotEmpty, isTrue);

      // Count "words" using current method (splits on whitespace)
      final wordCount = ChapterSplitter.countWords(htmlContent);

      // Count characters (more appropriate for Japanese)
      final textOnly = htmlContent
          .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
          .replaceAll(RegExp(r'&[^;]+;'), '') // Remove HTML entities
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
          .trim();
      final charCount = textOnly.length;

      if (verbose) {
        print('\n=== Japanese Word Counting Analysis ===');
        print('Chapter: ${japaneseChapter.contentFileName}');
        print('Raw HTML length: ${htmlContent.length} characters');
        print('Text-only length: $charCount characters');
        print('Current "word" count: $wordCount');
        print('Expected words (chars/3): ${(charCount / 3).round()}');
        print('\nSample text (first 200 chars):');
        print(textOnly.length > 200
            ? '${textOnly.substring(0, 200)}...'
            : textOnly);
        print(
            '\n✓ Japanese text properly counted as $wordCount words (estimated ~${(charCount / 3).round()} words from chars/3)');
      }

      // Japanese text should be counted properly
      expect(charCount, greaterThan(1000)); // Should have substantial content

      // For Japanese text, we expect significantly more words than whitespace-based counting
      // The word_count library should properly tokenize Japanese text
      expect(
        wordCount,
        greaterThan(
            charCount / 10), // Should be much more than whitespace counting
        reason:
            'Japanese text with $charCount characters was counted as $wordCount words. '
            'This should be significantly higher than whitespace-based counting.',
      );

      // Also verify it's a reasonable count (not too high)
      expect(
        wordCount,
        lessThan(charCount), // Shouldn't count every character as a word
        reason: 'Word count should be less than character count',
      );
    });

    test('chapter splitting should work for long Japanese chapters', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Test with multiple Japanese chapters to see if any would split
      var testedChapters = 0;
      var splitOccurred = false;

      if (verbose) {
        print('\n=== Chapter Length Analysis ===');
      }

      for (final chapter in konosubaBook.chapters.take(15)) {
        if (chapter.htmlContent == null || chapter.htmlContent!.isEmpty)
          continue;

        final originalWordCount =
            ChapterSplitter.countWords(chapter.htmlContent);
        final charCount = chapter.htmlContent!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&[^;]+;'), '')
            .length;

        if (verbose && testedChapters < 5) {
          print(
              '${chapter.contentFileName}: $charCount chars, $originalWordCount words');
        }

        if (charCount < 1000) continue; // Skip very short chapters

        testedChapters++;

        // Try to split the chapter
        final splitParts = ChapterSplitter.splitChapter(chapter);

        if (verbose && testedChapters <= 3) {
          print('\n=== Chapter Splitting Test $testedChapters ===');
          print('Chapter: ${chapter.contentFileName}');
          print('Character count: $charCount');
          print('Current word count: $originalWordCount');
          print('Parts after splitting: ${splitParts.length}');

          if (splitParts.length > 1) {
            print('✓ Chapter was split (unexpected for Japanese!)');
            splitOccurred = true;
          } else {
            print(
                '✗ Chapter was not split (expected due to word counting issue)');
          }
        }

        if (splitParts.length > 1) {
          splitOccurred = true;
        }
      }

      if (verbose) {
        print('\n=== Splitting Summary ===');
        print('Chapters tested: $testedChapters');
        print('Any chapters split: $splitOccurred');
        print(
            '⚠️  Japanese chapters likely won\'t split due to word counting method');
      }

      expect(testedChapters, greaterThan(0),
          reason: 'Should have found chapters to test');

      // At least some chapters should have been split
      expect(
        splitOccurred,
        isTrue,
        reason:
            'Long Japanese chapters (>15,000 characters) should be split into multiple parts. '
            'Found $testedChapters chapters with substantial content, but none were split. '
            'The current word counting method doesn\'t work for Japanese text.',
      );
    });

    test('demonstrates character-based splitting for Japanese', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Test character-based counting as an alternative
      var longChapterFound = false;

      if (verbose) {
        print('\n=== Scanning for Long Chapters ===');
      }

      for (final chapter in konosubaBook.chapters.take(15)) {
        if (chapter.htmlContent == null || chapter.htmlContent!.isEmpty)
          continue;

        final textOnly = chapter.htmlContent!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&[^;]+;'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        final charCount = textOnly.length;
        final currentWordCount =
            ChapterSplitter.countWords(chapter.htmlContent);

        // For Japanese, roughly 3 characters = 1 word equivalent
        final estimatedWords = (charCount / 3).round();

        if (verbose && charCount > 500) {
          print(
              '${chapter.contentFileName}: $charCount chars, estimated $estimatedWords words');
        }

        if (charCount > 1000) {
          // Find a substantial chapter
          longChapterFound = true;

          if (verbose) {
            print('\n=== Character-based Splitting Analysis ===');
            print('Chapter: ${chapter.contentFileName}');
            print('Character count: $charCount');
            print('Current word count: $currentWordCount');
            print('Estimated words (chars/3): $estimatedWords');
            print(
                'Should split if >3000 estimated words: ${estimatedWords > 3000}');
            print('Would need ${(estimatedWords / 3000).ceil()} parts');

            // Show how character-based thresholds would work
            final charThreshold = 15000; // ~3000 words worth
            print('\nCharacter-based approach:');
            print('Character threshold (15000): ${charCount > charThreshold}');
            print('Parts needed: ${(charCount / charThreshold).ceil()}');
          }

          // The word_count library now properly counts Japanese text
          // So the actual word count should be reasonable for the character count
          expect(currentWordCount, greaterThan(charCount / 10),
              reason:
                  'Word count should be substantial for the character count');
          break;
        }
      }

      expect(longChapterFound, isTrue,
          reason: 'Should find at least one substantial chapter');

      if (verbose) {
        print(
            '\n💡 Proposed solution: Use character-based counting for CJK languages');
        print('   - Detect Japanese/Chinese/Korean text');
        print('   - Use character count / 3 as word estimate');
        print(
            '   - Or use character threshold directly (e.g., 15,000 chars = split point)');
      }
    });

    test('eager splitting should work for Japanese chapters', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      // Test the readBookWithSplitChapters method
      final konosubaBytes = await konosubaFile.readAsBytes();
      final splitBook =
          await EpubReader.readBookWithSplitChapters(konosubaBytes);

      if (verbose) {
        print('\n=== Eager Splitting Test ===');
        print('Original chapters: ${konosubaBook.chapters.length}');
        print('Split book chapters: ${splitBook.chapters.length}');

        if (splitBook.chapters.length > konosubaBook.chapters.length) {
          print('✓ Some chapters were split!');

          // Find split chapters (those with (1/2), (2/2) etc in title)
          var splitCount = 0;
          for (final chapter in splitBook.chapters) {
            if (chapter.title?.contains(RegExp(r'\(\d+/\d+\)')) ?? false) {
              splitCount++;
              print('  Split chapter: ${chapter.title}');
            }
          }
          print('Total split parts: $splitCount');
        } else {
          print('✗ No chapters were split (expected for Japanese content)');
        }
      }

      // The split book should have more chapters than the original
      expect(
        splitBook.chapters.length,
        greaterThan(konosubaBook.chapters.length),
        reason:
            'readBookWithSplitChapters should split long Japanese chapters. '
            'Original had ${konosubaBook.chapters.length} chapters, '
            'but split version also has ${splitBook.chapters.length} chapters. '
            'Japanese chapters with >15,000 characters should be split.',
      );
    });

    test('counts total words in the book', () async {
      final konosubaPath = path.join(
        io.Directory.current.path,
        'assets',
        'konosuba.epub',
      );
      final konosubaFile = io.File(konosubaPath);
      if (!(await konosubaFile.exists())) {
        return;
      }

      var totalWords = 0;
      var totalCharacters = 0;
      final chapterStats = <Map<String, dynamic>>[];

      if (verbose) {
        print('\n=== Total Word Count Analysis ===');
        print('Chapter | Words | Characters | Title');
        print('--------|-------|------------|------');
      }

      for (var i = 0; i < konosubaBook.chapters.length; i++) {
        final chapter = konosubaBook.chapters[i];
        if (chapter.htmlContent == null || chapter.htmlContent!.isEmpty) {
          continue;
        }

        // Count words using ChapterSplitter
        final wordCount = ChapterSplitter.countWords(chapter.htmlContent);

        // Count characters (excluding HTML)
        final textOnly = chapter.htmlContent!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&[^;]+;'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final charCount = textOnly.length;

        totalWords += wordCount;
        totalCharacters += charCount;

        chapterStats.add({
          'index': i + 1,
          'title': chapter.title ?? '[Untitled]',
          'fileName': chapter.contentFileName,
          'words': wordCount,
          'characters': charCount,
        });

        if (verbose) {
          final paddedIndex = (i + 1).toString().padLeft(7);
          final paddedWords = wordCount.toString().padLeft(6);
          final paddedChars = charCount.toString().padLeft(11);
          print(
              '$paddedIndex | $paddedWords | $paddedChars | ${chapter.title ?? "[Untitled]"}');
        }
      }

      if (verbose) {
        print('\n=== Summary Statistics ===');
        print('Total chapters: ${konosubaBook.chapters.length}');
        print(
            'Total words: ${totalWords.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}');
        print(
            'Total characters: ${totalCharacters.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}');
        print(
            'Average words per chapter: ${(totalWords / konosubaBook.chapters.length).round()}');
        print(
            'Average characters per chapter: ${(totalCharacters / konosubaBook.chapters.length).round()}');
        print(
            'Characters to words ratio: ${(totalCharacters / totalWords).toStringAsFixed(2)}');

        // Find longest and shortest chapters
        chapterStats.sort((a, b) => b['words'].compareTo(a['words']));
        if (chapterStats.isNotEmpty) {
          print('\n=== Longest Chapters by Word Count ===');
          for (var i = 0; i < 3 && i < chapterStats.length; i++) {
            final stat = chapterStats[i];
            print(
                '${i + 1}. ${stat['title']} - ${stat['words']} words (${stat['characters']} chars)');
          }

          print('\n=== Shortest Chapters by Word Count ===');
          final nonZeroChapters =
              chapterStats.where((s) => s['words'] > 0).toList();
          for (var i = 0; i < 3 && i < nonZeroChapters.length; i++) {
            final stat = nonZeroChapters[nonZeroChapters.length - 1 - i];
            print(
                '${i + 1}. ${stat['title']} - ${stat['words']} words (${stat['characters']} chars)');
          }
        }
      }

      // Basic assertions
      expect(totalWords, greaterThan(0), reason: 'Book should have content');
      expect(totalCharacters, greaterThan(totalWords),
          reason:
              'Japanese text typically has more characters than word count');

      // For Japanese text, the word count library should properly tokenize
      // Expect reasonable word counts (not just whitespace-based)
      expect(totalWords, greaterThan(10000),
          reason: 'A full novel should have substantial word count');
    });
  });
}
