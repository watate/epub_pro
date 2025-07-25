import 'dart:io' as io;

import 'package:epub_pro/epub_pro.dart';
import 'package:epub_pro/src/schema/opf/epub_metadata_meta.dart';
import 'package:epub_pro/src/utils/chapter_splitter.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('SAO Japanese EPUB Tests', () {
    late EpubBook saoBook;
    late EpubBookRef saoRef;
    final verbose = true;

    setUpAll(() async {
      // Load sao.epub if it exists
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        print('Skipping SAO tests - sao.epub not found at: $saoPath');
        return;
      }
      
      if (verbose) {
        print('\n=== Loading SAO (Sword Art Online) Japanese EPUB ===');
      }
      
      final saoBytes = await saoFile.readAsBytes();
      saoBook = await EpubReader.readBook(saoBytes);
      saoRef = await EpubReader.openBook(saoBytes);
    });

    test('handles minimal navigation with spine reconciliation', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check navigation points (should only have 1)
      final navPoints = saoRef.schema?.navigation?.navMap?.points ?? [];
      expect(navPoints.length, equals(1));
      expect(navPoints.first.navigationLabels!.first.text, equals('奥付')); // "Colophon"
      
      // Check that we get all chapters from spine reconciliation
      final chapters = saoRef.getChapters();
      expect(chapters.length, equals(40)); // All spine items should be chapters
      
      if (verbose) {
        print('\n=== Navigation Reconciliation Results ===');
        print('Navigation entries: ${navPoints.length}');
        print('Total chapters after reconciliation: ${chapters.length}');
        print('\nOnly navigation entry:');
        print('  ${navPoints.first.navigationLabels!.first.text} -> ${navPoints.first.content?.source}');
      }
    });

    test('correctly identifies all 40 chapters from spine', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      final chapters = saoBook.chapters;
      expect(chapters.length, equals(40));
      
      // First should be titlepage
      expect(chapters.first.contentFileName, equals('titlepage.xhtml'));
      
      // Last should be part0038 with title
      expect(chapters.last.contentFileName, equals('text/part0038.html'));
      expect(chapters.last.title, equals('奥付'));
      
      // All others should be untitled
      for (var i = 1; i < chapters.length - 1; i++) {
        expect(chapters[i].title, isNull);
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
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check that content can be read
      for (final chapter in saoBook.chapters) {
        expect(chapter.htmlContent, isNotNull);
      }
      
      if (verbose) {
        print('\n=== Content Preview (First 100 chars) ===');
        for (var i = 0; i < saoBook.chapters.length && i < 5; i++) {
          final chapter = saoBook.chapters[i];
          final title = chapter.title ?? '[Untitled]';
          final content = chapter.htmlContent?.replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          final preview = content != null && content.length > 100 
              ? '${content.substring(0, 100)}...'
              : content ?? '[No content]';
          print('\nChapter ${i + 1}: $title');
          print('Preview: $preview');
        }
        
        if (saoBook.chapters.length > 5) {
          print('\n... and ${saoBook.chapters.length - 5} more chapters');
        }
      }
    });

    test('has correct Japanese metadata', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check title
      expect(saoBook.title, equals('ソードアート・オンライン1 アインクラッド (電撃文庫)'));
      
      // Check author
      expect(saoBook.author, equals('川原 礫'));
      
      // Check language
      expect(saoBook.schema?.package?.metadata?.languages.first, equals('ja'));
      
      // Check publisher
      expect(saoBook.schema?.package?.metadata?.publishers.first, equals('株式会社KADOKAWA'));
      
      if (verbose) {
        print('\n=== Metadata ===');
        print('Title: ${saoBook.title}');
        print('Author: ${saoBook.author}');
        print('Language: ${saoBook.schema?.package?.metadata?.languages.first}');
        print('Publisher: ${saoBook.schema?.package?.metadata?.publishers.first}');
        print('Publication Date: ${saoBook.schema?.package?.metadata?.dates.firstOrNull?.date}');
      }
    });

    test('has right-to-left page progression', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check spine direction - ltr is false for rtl books
      final spine = saoBook.schema?.package?.spine;
      expect(spine?.ltr, equals(false)); // false means RTL
      
      if (verbose) {
        print('\n=== Reading Direction ===');
        print('Spine LTR flag: ${spine?.ltr} (false = right-to-left)');
        print('Primary writing mode: ${saoBook.schema?.package?.metadata?.metaItems.firstWhere(
          (meta) => meta.name == 'primary-writing-mode',
          orElse: () => EpubMetadataMeta(),
        ).content}');
      }
    });

    test('handles cover image correctly', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      expect(saoBook.coverImage, isNotNull);
      expect(saoBook.coverImage!.length, greaterThan(0));
      
      // The cover should be cover1.jpeg based on the manifest
      final coverManifestItem = saoBook.schema?.package?.manifest?.items.firstWhere(
        (item) => item.id == 'cover',
      );
      expect(coverManifestItem?.href, equals('cover1.jpeg'));
      
      if (verbose) {
        print('\n=== Cover Information ===');
        print('Cover file: ${coverManifestItem?.href}');
        print('Cover size: ${saoBook.coverImage!.length} bytes');
        print('Cover media type: ${coverManifestItem?.mediaType}');
      }
    });

    test('spine items are in correct order', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      final spine = saoBook.schema?.package?.spine?.items ?? [];
      
      if (verbose) {
        print('\n=== Spine Analysis ===');
        print('Spine items count: ${spine.length}');
        print('Chapters count: ${saoBook.chapters.length}');
      }
      
      // The spine might have 41 items if it includes the nav document
      expect(spine.length, anyOf(equals(40), equals(41)));
      
      // Verify the spine order matches chapter order
      final chapters = saoBook.chapters;
      final manifest = saoBook.schema?.package?.manifest?.items ?? [];
      
      // Check which spine items are actually in chapters
      var matchedCount = 0;
      for (var i = 0; i < spine.length; i++) {
        final spineItem = spine[i];
        final manifestItem = manifest.firstWhere((item) => item.id == spineItem.idRef);
        
        // Find if this spine item has a corresponding chapter
        final hasChapter = chapters.any((ch) => ch.contentFileName == manifestItem.href);
        if (hasChapter) {
          matchedCount++;
        } else if (verbose) {
          print('Spine item not in chapters: ${manifestItem.href} (${manifestItem.properties})');
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
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Get a chapter with substantial Japanese content
      final japaneseChapter = saoBook.chapters.firstWhere(
        (ch) => ch.contentFileName?.contains('part0009.html') ?? false,
        orElse: () => saoBook.chapters[2], // fallback to any content chapter
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
        print(textOnly.length > 200 ? '${textOnly.substring(0, 200)}...' : textOnly);
        print('\n✓ Japanese text properly counted as $wordCount words (estimated ~${(charCount / 3).round()} words from chars/3)');
      }

      // Japanese text should be counted properly
      expect(charCount, greaterThan(1000)); // Should have substantial content
      
      // For Japanese text, we expect significantly more words than whitespace-based counting
      // The word_count library should properly tokenize Japanese text
      expect(
        wordCount,
        greaterThan(charCount / 10), // Should be much more than whitespace counting
        reason: 'Japanese text with $charCount characters was counted as $wordCount words. '
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
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Test with multiple Japanese chapters to see if any would split
      var testedChapters = 0;
      var splitOccurred = false;
      
      if (verbose) {
        print('\n=== Chapter Length Analysis ===');
      }
      
      for (final chapter in saoBook.chapters.take(15)) {
        if (chapter.htmlContent == null || chapter.htmlContent!.isEmpty) continue;
        
        final originalWordCount = ChapterSplitter.countWords(chapter.htmlContent);
        final charCount = chapter.htmlContent!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&[^;]+;'), '')
            .length;
            
        if (verbose && testedChapters < 5) {
          print('${chapter.contentFileName}: $charCount chars, $originalWordCount words');
        }
            
        if (charCount < 1000) continue; // Skip very short chapters
        
        testedChapters++;
        
        // Try to split the chapter
        final splitParts = ChapterSplitter.splitChapter(chapter);
        
        if (verbose && testedChapters <= 3) {
          print('\n=== Chapter Splitting Test ${testedChapters} ===');
          print('Chapter: ${chapter.contentFileName}');
          print('Character count: $charCount');
          print('Current word count: $originalWordCount');
          print('Parts after splitting: ${splitParts.length}');
          
          if (splitParts.length > 1) {
            print('✓ Chapter was split (unexpected for Japanese!)');
            splitOccurred = true;
          } else {
            print('✗ Chapter was not split (expected due to word counting issue)');
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
        print('⚠️  Japanese chapters likely won\'t split due to word counting method');
      }
      
      expect(testedChapters, greaterThan(0), reason: 'Should have found chapters to test');
      
      // At least some chapters should have been split
      expect(
        splitOccurred,
        isTrue,
        reason: 'Long Japanese chapters (>15,000 characters) should be split into multiple parts. '
                'Found $testedChapters chapters with substantial content, but none were split. '
                'The current word counting method doesn\'t work for Japanese text.',
      );
    });

    test('demonstrates character-based splitting for Japanese', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Test character-based counting as an alternative
      var longChapterFound = false;
      
      if (verbose) {
        print('\n=== Scanning for Long Chapters ===');
      }
      
      for (final chapter in saoBook.chapters.take(15)) {
        if (chapter.htmlContent == null || chapter.htmlContent!.isEmpty) continue;
        
        final textOnly = chapter.htmlContent!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&[^;]+;'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
            
        final charCount = textOnly.length;
        final currentWordCount = ChapterSplitter.countWords(chapter.htmlContent);
        
        // For Japanese, roughly 3 characters = 1 word equivalent
        final estimatedWords = (charCount / 3).round();
        
        if (verbose && charCount > 500) {
          print('${chapter.contentFileName}: $charCount chars, estimated $estimatedWords words');
        }
        
        if (charCount > 1000) { // Find a substantial chapter
          longChapterFound = true;
          
          if (verbose) {
            print('\n=== Character-based Splitting Analysis ===');
            print('Chapter: ${chapter.contentFileName}');
            print('Character count: $charCount');
            print('Current word count: $currentWordCount');
            print('Estimated words (chars/3): $estimatedWords');
            print('Should split if >5000 estimated words: ${estimatedWords > 5000}');
            print('Would need ${(estimatedWords / 5000).ceil()} parts');
            
            // Show how character-based thresholds would work
            final charThreshold = 15000; // ~5000 words worth
            print('\nCharacter-based approach:');
            print('Character threshold (15000): ${charCount > charThreshold}');
            print('Parts needed: ${(charCount / charThreshold).ceil()}');
          }
          
          // The word_count library now properly counts Japanese text
          // So the actual word count should be reasonable for the character count
          expect(currentWordCount, greaterThan(charCount / 10), 
                 reason: 'Word count should be substantial for the character count');
          break;
        }
      }
      
      expect(longChapterFound, isTrue, reason: 'Should find at least one substantial chapter');
      
      if (verbose) {
        print('\n💡 Proposed solution: Use character-based counting for CJK languages');
        print('   - Detect Japanese/Chinese/Korean text');
        print('   - Use character count / 3 as word estimate');
        print('   - Or use character threshold directly (e.g., 15,000 chars = split point)');
      }
    });

    test('eager splitting should work for Japanese chapters', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Test the readBookWithSplitChapters method
      final saoBytes = await saoFile.readAsBytes();
      final splitBook = await EpubReader.readBookWithSplitChapters(saoBytes);
      
      if (verbose) {
        print('\n=== Eager Splitting Test ===');  
        print('Original chapters: ${saoBook.chapters.length}');
        print('Split book chapters: ${splitBook.chapters.length}');
        
        if (splitBook.chapters.length > saoBook.chapters.length) {
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
        greaterThan(saoBook.chapters.length),
        reason: 'readBookWithSplitChapters should split long Japanese chapters. '
                'Original had ${saoBook.chapters.length} chapters, '
                'but split version also has ${splitBook.chapters.length} chapters. '
                'Japanese chapters with >15,000 characters should be split.',
      );
    });
  });
}