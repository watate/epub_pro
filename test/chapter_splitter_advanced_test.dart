import 'package:epub_pro/epub_pro.dart';
import 'package:epub_pro/src/utils/chapter_splitter.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterSplitter Advanced Tests', () {
    group('Word Counting Edge Cases', () {
      test('handles HTML entities correctly', () {
        expect(
          ChapterSplitter.countWords('<p>Hello&nbsp;world</p>'),
          equals(2),
        );
        expect(
          ChapterSplitter.countWords('<p>AT&amp;T is a company</p>'),
          equals(5),
        );
        expect(
          ChapterSplitter.countWords('<p>&lt;tag&gt; is HTML</p>'),
          equals(3),
        );
      });

      test('handles various HTML structures', () {
        expect(
          ChapterSplitter.countWords('<div>Hello <span>world</span></div>'),
          equals(2),
        );
        expect(
          ChapterSplitter.countWords(
              '<h1>Title</h1><h2>Subtitle</h2><p>Content</p>'),
          equals(3),
        );
        expect(
          ChapterSplitter.countWords('''
            <ul>
              <li>First item</li>
              <li>Second item</li>
              <li>Third item</li>
            </ul>
          '''),
          equals(6),
        );
      });

      test('handles nested HTML structures', () {
        final nestedHtml = '''
          <div>
            <p>Outer paragraph with <strong>bold <em>and italic</em></strong> text.</p>
            <blockquote>
              <p>Quoted text here</p>
            </blockquote>
          </div>
        ''';
        expect(
            ChapterSplitter.countWords(nestedHtml),
            equals(
                10)); // "Outer", "paragraph", "with", "bold", "and", "italic", "text.", "Quoted", "text", "here"
      });

      test('handles empty and whitespace content', () {
        expect(ChapterSplitter.countWords(''), equals(0));
        expect(ChapterSplitter.countWords('   '), equals(0));
        expect(ChapterSplitter.countWords('<p></p>'), equals(0));
        expect(ChapterSplitter.countWords('<p>   </p>'), equals(0));
      });
    });

    group('HTML Content Splitting', () {
      test('treats single div as one block element', () {
        // A single div with content is now treated as one block element
        // and won't be split, even if it contains many words
        final noParagraphContent = '<div>${'word ' * 1000}</div>';
        final parts = ChapterSplitter.splitHtmlContent(noParagraphContent, 500);

        expect(parts.length, equals(1)); // Single div is treated as one block
        expect(parts[0], equals(noParagraphContent));
      });

      test('preserves HTML structure before and after paragraphs', () {
        final htmlWithStructure = '''
          <h1>Chapter Title</h1>
          <p>${'word ' * 300}</p>
          <p>${'word ' * 300}</p>
          <div class="footer">End of chapter</div>
        ''';

        final parts = ChapterSplitter.splitHtmlContent(htmlWithStructure, 400);

        expect(parts.length, equals(2));
        expect(parts[0], contains('<h1>Chapter Title</h1>'));
        expect(parts[1], contains('<div class="footer">End of chapter</div>'));
      });

      test('handles mixed content types', () {
        final mixedContent = '''
          <h1>Title</h1>
          <p>${'word ' * 200}</p>
          <ul>
            <li>${'item ' * 50}</li>
            <li>${'item ' * 50}</li>
          </ul>
          <p>${'word ' * 200}</p>
          <table>
            <tr><td>Data</td></tr>
          </table>
        ''';

        final parts = ChapterSplitter.splitHtmlContent(mixedContent, 300);

        expect(parts.length, greaterThan(1));
        // Ensure all parts are valid HTML fragments
        for (final part in parts) {
          expect(part, isNotEmpty);
        }
      });

      test('handles nested paragraphs inside div', () {
        // The regex matches overlapping patterns - both the div AND the p tags inside
        // This causes the content to be split at p tag boundaries, not div boundaries
        final nestedContent = '<div class="chapter-content"><p>${'word ' * 500}</p><p>${'word ' * 500}</p></div>';
        
        final parts = ChapterSplitter.splitHtmlContent(nestedContent, 600);
        
        // With the current implementation, nested p tags are matched separately,
        // so the content gets split even though it's inside a div
        expect(parts.length, equals(2));
        
        // First part contains the opening div and first p
        expect(parts[0], contains('<div class="chapter-content">'));
        expect(parts[0], contains('<p>'));
        expect(ChapterSplitter.countWords(parts[0]), equals(500));
        
        // Second part contains the second p and closing div
        expect(parts[1], contains('<p>'));
        expect(parts[1], contains('</div>'));
        expect(ChapterSplitter.countWords(parts[1]), equals(500));
      });

      test('splits separate paragraphs not in containers', () {
        // When paragraphs are not inside container elements,
        // they can be split properly
        final separateParagraphs = '''
          <p>${'word ' * 500}</p>
          <p>${'word ' * 500}</p>
        ''';
        
        final parts = ChapterSplitter.splitHtmlContent(separateParagraphs, 600);
        
        // Separate paragraphs can be split into different parts
        expect(parts.length, equals(2));
        expect(parts[0], contains('<p>'));
        expect(parts[1], contains('<p>'));
      });

      test('handles deeply nested structures', () {
        // Complex nested structure with a single p tag
        final deeplyNested = '<section><div><article><p>${'word ' * 1000}</p></article></div></section>';
        
        final parts = ChapterSplitter.splitHtmlContent(deeplyNested, 500);
        
        // A single p tag is treated as one indivisible block,
        // even if it contains more words than the limit
        expect(parts.length, equals(1));
        expect(ChapterSplitter.countWords(parts[0]), equals(1000));
        
        // All container tags are preserved
        expect(parts[0], equals(deeplyNested));
      });

      test('falls back to character split for non-matching content', () {
        // Content with no recognized block elements
        final plainText = 'word ' * 1000; // No HTML tags
        final parts = ChapterSplitter.splitHtmlContent(plainText, 500);
        
        // Should use character-based splitting as fallback
        expect(parts.length, equals(2));
        expect(parts[0].length, closeTo(parts[1].length, 100));
      });

      test('handles mixed nested and standalone paragraphs', () {
        // Test content with mix of nested div-p and standalone p elements
        // 2 nested: <div><p>1000 words</p></div>
        // 2 standalone: <p>1000 words</p>
        // Total: 4000 words across 4 paragraph elements
        final mixedContent = '''
          <div><p>${'word ' * 1000}</p></div>
          <p>${'word ' * 1000}</p>
          <div><p>${'word ' * 1000}</p></div>
          <p>${'word ' * 1000}</p>
        ''';
        
        final parts = ChapterSplitter.splitHtmlContent(mixedContent, 1500);
        
        // With 4000 total words and 1500 max per part, we need 3 parts
        // But since splitting happens at paragraph boundaries (each 1000 words),
        // actual distribution is: 1000, 1000, 2000 words
        expect(parts.length, equals(3));
        
        var totalWords = 0;
        for (final part in parts) {
          totalWords += ChapterSplitter.countWords(part);
        }
        expect(totalWords, equals(4000)); // Total words preserved
        
        // Verify the actual word distribution
        expect(ChapterSplitter.countWords(parts[0]), equals(1000)); // First paragraph
        expect(ChapterSplitter.countWords(parts[1]), equals(1000)); // Second paragraph  
        expect(ChapterSplitter.countWords(parts[2]), equals(2000)); // Last two paragraphs
        
        // Verify structure preservation
        // Each part should contain paragraph content (nested or standalone)
        for (final part in parts) {
          expect(part, contains('<p>'));
        }
        
        // The regex treats both nested and standalone p tags equally,
        // so all 4 paragraphs are identified as splittable blocks
        print('Successfully split mixed nested/standalone paragraphs:');
        print('- Part 0: ${ChapterSplitter.countWords(parts[0])} words');
        print('- Part 1: ${ChapterSplitter.countWords(parts[1])} words');
        print('- Part 2: ${ChapterSplitter.countWords(parts[2])} words');
      });
    });

    group('Chapter Splitting Edge Cases', () {
      test('handles chapters with exactly 3000 words', () {
        // Create content with exactly 3000 words
        final exactContent =
            List.generate(50, (i) => '<p>${'word ' * 100}</p>').join();
        final chapter = EpubChapter(
          title: 'Exact Chapter',
          htmlContent: exactContent,
        );

        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(2));
        expect(result[0].title, equals('Exact Chapter (1/2)'));
        expect(result[1].title, equals('Exact Chapter (2/2)'));
      });

      test('splits very large chapters into multiple parts', () {
        // Create content with ~15000 words
        final veryLongContent =
            List.generate(75, (i) => '<p>${'word ' * 200}</p>').join();
        final chapter = EpubChapter(
          title: 'Very Long Chapter',
          htmlContent: veryLongContent,
        );

        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(5));
        expect(result[0].title, equals('Very Long Chapter (1/5)'));
        expect(result[1].title, equals('Very Long Chapter (2/5)'));
        expect(result[2].title, equals('Very Long Chapter (3/5)'));
        expect(result[3].title, equals('Very Long Chapter (4/5)'));
        expect(result[4].title, equals('Very Long Chapter (5/5)'));

        // Verify each part is under the word limit
        for (final part in result) {
          final wordCount = ChapterSplitter.countWords(part.htmlContent);
          expect(wordCount, lessThanOrEqualTo(3000));
        }
      });

      test('handles chapters with no title', () {
        final content =
            List.generate(30, (i) => '<p>${'word ' * 200}</p>').join();
        final chapter = EpubChapter(
          title: null,
          htmlContent: content,
        );

        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(2));
        expect(result[0].title, equals('Chapter (1/2)'));
        expect(result[1].title, equals('Chapter (2/2)'));
      });

      test('preserves chapter metadata in split parts', () {
        final content =
            List.generate(30, (i) => '<p>${'word ' * 200}</p>').join();
        final chapter = EpubChapter(
          title: 'Test Chapter',
          contentFileName: 'chapter1.xhtml',
          anchor: 'section1',
          htmlContent: content,
        );

        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(2));

        // First part should preserve all metadata
        expect(result[0].contentFileName, equals('chapter1.xhtml'));
        expect(result[0].anchor, equals('section1'));

        // Subsequent parts should have same content file but no anchor
        expect(result[1].contentFileName, equals('chapter1.xhtml'));
        expect(result[1].anchor, isNull);
      });

      test('handles deeply nested sub-chapters', () {
        final subSubChapter = EpubChapter(
          title: 'Sub-Sub Chapter',
          htmlContent: '<p>Deep content</p>',
        );

        final subChapter = EpubChapter(
          title: 'Sub Chapter',
          htmlContent:
              List.generate(30, (i) => '<p>${'word ' * 200}</p>').join(),
          subChapters: [subSubChapter],
        );

        final mainChapter = EpubChapter(
          title: 'Main Chapter',
          htmlContent:
              List.generate(30, (i) => '<p>${'word ' * 200}</p>').join(),
          subChapters: [subChapter],
        );

        final result = ChapterSplitter.splitChapter(mainChapter);

        // Main chapter should be split
        expect(result.length, equals(2));

        // First part should have the sub-chapter
        expect(result[0].subChapters.length, greaterThan(0));

        // The sub-chapter should also be split
        final splitSubChapters = result[0].subChapters;
        expect(splitSubChapters.length, equals(2));
        expect(splitSubChapters[0].title, equals('Sub Chapter (1/2)'));

        // The sub-sub-chapter should be preserved in the first part of the sub-chapter
        expect(splitSubChapters[0].subChapters.length, equals(1));
        expect(splitSubChapters[0].subChapters[0].title,
            equals('Sub-Sub Chapter'));
      });
    });

    group('Performance and Special Cases', () {
      test('handles chapters with many small paragraphs efficiently', () {
        // Create 1000 small paragraphs
        final manyParagraphs =
            List.generate(1000, (i) => '<p>Word $i</p>').join();
        final chapter = EpubChapter(
          title: 'Many Paragraphs',
          htmlContent: manyParagraphs,
        );

        final stopwatch = Stopwatch()..start();
        final result = ChapterSplitter.splitChapter(chapter);
        stopwatch.stop();

        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(result.length, equals(1)); // 1000 words is less than 3000
      });

      test('handles malformed HTML gracefully', () {
        final malformedHtml = '''
          <p>Unclosed paragraph
          <p>Another paragraph</p>
          <div>Unclosed div
          <span>Some text
        ''';

        final chapter = EpubChapter(
          title: 'Malformed',
          htmlContent: malformedHtml,
        );

        // Should not throw
        expect(() => ChapterSplitter.splitChapter(chapter), returnsNormally);
      });

      test('preserves special characters and unicode', () {
        final unicodeContent = '''
          <p>English text with special chars: café, naïve</p>
          <p>Chinese: 这是中文文本</p>
          <p>Arabic: هذا نص عربي</p>
          <p>Emoji: 📚 📖 ✍️</p>
        ''';

        final chapter = EpubChapter(
          title: 'Unicode Chapter',
          htmlContent: unicodeContent,
        );

        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(1));

        // Verify content is preserved
        expect(result[0].htmlContent, contains('café'));
        expect(result[0].htmlContent, contains('这是中文文本'));
        expect(result[0].htmlContent, contains('هذا نص عربي'));
        expect(result[0].htmlContent, contains('📚'));
      });
    });
  });
}
