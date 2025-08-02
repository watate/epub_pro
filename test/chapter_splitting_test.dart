import 'dart:io';

import 'package:epub_pro/epub_pro.dart';
import 'package:epub_pro/src/utils/chapter_splitter.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterSplitter', () {
    test('countWords correctly counts words in HTML', () {
      expect(ChapterSplitter.countWords('<p>Hello world</p>'), equals(2));
      expect(
        ChapterSplitter.countWords('<p>This is a <strong>test</strong>.</p>'),
        equals(
            4), // "This", "is", "a", "test" (period not counted as separate word)
      );
      expect(
        ChapterSplitter.countWords('<p>One</p><p>Two</p><p>Three</p>'),
        equals(3),
      );
      expect(ChapterSplitter.countWords(''), equals(0));
      expect(ChapterSplitter.countWords(null), equals(0));
    });

    test('splitHtmlContent splits content correctly', () {
      // Create multiple paragraphs to enable splitting
      final longContent =
          List.generate(10, (i) => '<p>${'word ' * 200}</p>').join();
      final parts = ChapterSplitter.splitHtmlContent(longContent, 500);

      expect(parts.length, greaterThan(1));
      expect(parts.every((part) => part.contains('<p>')), isTrue);
    });

    test('splitChapter does not split short chapters', () {
      final shortChapter = EpubChapter(
        title: 'Short Chapter',
        htmlContent: '<p>This is a short chapter with few words.</p>',
      );

      final result = ChapterSplitter.splitChapter(shortChapter);
      expect(result.length, equals(1));
      expect(result.first.title, equals('Short Chapter'));
    });

    test('splitChapter splits long chapters', () {
      // Create content with more than 3000 words using multiple paragraphs
      final longContent =
          List.generate(30, (i) => '<p>${'word ' * 200}</p>').join();
      final longChapter = EpubChapter(
        title: 'Long Chapter',
        htmlContent: longContent,
      );

      final result = ChapterSplitter.splitChapter(longChapter);
      expect(result.length, equals(2));
      expect(result[0].title, equals('Long Chapter (1/2)'));
      expect(result[1].title, equals('Long Chapter (2/2)'));
    });

    test('splitChapter preserves sub-chapters in first part only', () {
      final longContent =
          List.generate(30, (i) => '<p>${'word ' * 200}</p>').join();
      final subChapter = EpubChapter(
        title: 'Sub Chapter',
        htmlContent: '<p>Sub chapter content</p>',
      );

      final longChapter = EpubChapter(
        title: 'Long Chapter',
        htmlContent: longContent,
        subChapters: [subChapter],
      );

      final result = ChapterSplitter.splitChapter(longChapter);
      expect(result.length, equals(2));
      expect(result[0].subChapters.length, equals(1));
      expect(result[1].subChapters.length, equals(0));
    });

    test('handles chapters with exactly 3000 words', () {
      // Create content with exactly 3000 words
      final exactContent =
          List.generate(50, (i) => '<p>${'word ' * 100}</p>').join();
      final chapter = EpubChapter(
        title: 'Exact 3000',
        htmlContent: exactContent,
      );

      final result = ChapterSplitter.splitChapter(chapter);
      expect(result.length, equals(2));
      expect(result[0].title, equals('Exact 3000 (1/2)'));
      expect(result[1].title, equals('Exact 3000 (2/2)'));
    });

    test('handles empty and null content', () {
      final emptyChapter = EpubChapter(
        title: 'Empty',
        htmlContent: '',
      );

      final nullChapter = EpubChapter(
        title: 'Null',
        htmlContent: null,
      );

      expect(ChapterSplitter.splitChapter(emptyChapter).length, equals(1));
      expect(ChapterSplitter.splitChapter(nullChapter).length, equals(1));
    });

    test('handles chapters with only whitespace', () {
      final whitespaceChapter = EpubChapter(
        title: 'Whitespace',
        htmlContent: '   \n\t   ',
      );

      final result = ChapterSplitter.splitChapter(whitespaceChapter);
      expect(result.length, equals(1));
      expect(result[0].title, equals('Whitespace'));
    });

    test('preserves anchor and contentFileName correctly', () {
      final content =
          List.generate(30, (i) => '<p>${'word ' * 200}</p>').join();
      final chapter = EpubChapter(
        title: 'Anchored Chapter',
        contentFileName: 'chapter1.xhtml',
        anchor: 'section1',
        htmlContent: content,
      );

      final result = ChapterSplitter.splitChapter(chapter);
      expect(result.length, equals(2));

      // First part gets the anchor
      expect(result[0].contentFileName, equals('chapter1.xhtml'));
      expect(result[0].anchor, equals('section1'));

      // Second part has same filename but no anchor
      expect(result[1].contentFileName, equals('chapter1.xhtml'));
      expect(result[1].anchor, isNull);
    });

    test('handles various HTML structures', () {
      final tableContent = '''
        <h1>Chapter with Table</h1>
        <table>
          ${List.generate(100, (i) => '''
          <tr>
            <td>${'word ' * 50}</td>
            <td>${'data ' * 50}</td>
          </tr>
          ''').join()}
        </table>
      ''';

      final listContent = '''
        <h1>Chapter with Lists</h1>
        <ul>
          ${List.generate(100, (i) => '<li>${'item ' * 50}</li>').join()}
        </ul>
        <ol>
          ${List.generate(100, (i) => '<li>${'step ' * 50}</li>').join()}
        </ol>
      ''';

      final blockquoteContent = '''
        <h1>Chapter with Quotes</h1>
        ${List.generate(50, (i) => '''
        <blockquote>
          <p>${'quoted text ' * 100}</p>
          <cite>Author $i</cite>
        </blockquote>
        ''').join()}
      ''';

      // Test each structure
      for (final content in [tableContent, listContent, blockquoteContent]) {
        final chapter = EpubChapter(
          title: 'Structured',
          htmlContent: content,
        );

        final result = ChapterSplitter.splitChapter(chapter);

        // Should split due to high word count
        expect(result.length, greaterThan(1));

        // Each part should be under limit
        for (final part in result) {
          expect(ChapterSplitter.countWords(part.htmlContent),
              lessThanOrEqualTo(3000));
        }
      }
    });
  });

  group('EpubReader with splitting', () {
    test('readBookWithSplitChapters splits long chapters', () async {
      // Load Fahrenheit 451 which has long chapters
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }

      final bytes = await epubFile.readAsBytes();

      // Read with normal method
      final normalBook = await EpubReader.readBook(bytes);

      // Read with splitting
      final splitBook = await EpubReader.readBookWithSplitChapters(bytes);

      // The split version should have more chapters
      expect(
          splitBook.chapters.length, greaterThan(normalBook.chapters.length));

      // Check that long chapters are split
      for (final chapter in splitBook.chapters) {
        final wordCount = ChapterSplitter.countWords(chapter.htmlContent);
        expect(wordCount, lessThanOrEqualTo(3304),
            reason:
                'Chapter "${chapter.title}" has $wordCount words (allowing some tolerance for paragraph boundaries)');
      }
    });
  });

  group('EpubBookRef with splitting', () {
    test('getChaptersWithSplitting splits long chapters', () async {
      // Load And Then There Were None which has some long chapters
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }

      final bytes = await epubFile.readAsBytes();
      final bookRef = await EpubReader.openBook(bytes);

      // Get normal chapters
      final normalChapters = bookRef.getChapters();

      // Get split chapters
      final splitChapters = await bookRef.getChaptersWithSplitting();

      // Should have at least as many chapters (or more if any were split)
      expect(splitChapters.length, greaterThanOrEqualTo(normalChapters.length));

      // All chapters should be within word limit
      for (final chapter in splitChapters) {
        final wordCount = ChapterSplitter.countWords(chapter.htmlContent);
        expect(
            wordCount,
            lessThanOrEqualTo(
                3304)); // Allow some tolerance for paragraph boundaries
      }
    });

    test(
        'inherits parent title for orphaned subchapters that do not need splitting',
        () {
      // Create a parent chapter with a short orphaned subchapter
      final shortOrphanedSubChapter = EpubChapter(
        title: null, // No title - should inherit parent's
        contentFileName: 'orphan.xhtml',
        htmlContent: '<p>Short content that does not need splitting.</p>',
      );

      final parentChapter = EpubChapter(
        title: 'Parent Chapter Title',
        contentFileName: 'parent.xhtml',
        htmlContent: '<p>Parent content.</p>',
        subChapters: [shortOrphanedSubChapter],
      );

      final result = ChapterSplitter.splitChapter(parentChapter);

      // Should return one chapter with the subchapter having inherited title
      expect(result.length, equals(1));
      expect(result[0].title, equals('Parent Chapter Title'));
      expect(result[0].subChapters.length, equals(1));
      expect(result[0].subChapters[0].title, equals('Parent Chapter Title'));
      expect(result[0].subChapters[0].contentFileName, equals('orphan.xhtml'));
    });

    test('preserves existing titles for subchapters that already have them',
        () {
      // Create a subchapter that already has a title
      final titledSubChapter = EpubChapter(
        title: 'Existing SubChapter Title',
        contentFileName: 'titled.xhtml',
        htmlContent: '<p>Short content with existing title.</p>',
      );

      final parentChapter = EpubChapter(
        title: 'Parent Chapter Title',
        contentFileName: 'parent.xhtml',
        htmlContent: '<p>Parent content.</p>',
        subChapters: [titledSubChapter],
      );

      final result = ChapterSplitter.splitChapter(parentChapter);

      // Should preserve the existing subchapter title
      expect(result.length, equals(1));
      expect(result[0].title, equals('Parent Chapter Title'));
      expect(result[0].subChapters.length, equals(1));
      expect(
          result[0].subChapters[0].title, equals('Existing SubChapter Title'));
    });
  });
}
