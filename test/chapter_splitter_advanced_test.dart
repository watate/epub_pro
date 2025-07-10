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
          ChapterSplitter.countWords('<h1>Title</h1><h2>Subtitle</h2><p>Content</p>'),
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
        expect(ChapterSplitter.countWords(nestedHtml), equals(10)); // "Outer", "paragraph", "with", "bold", "and", "italic", "text.", "Quoted", "text", "here"
      });

      test('handles empty and whitespace content', () {
        expect(ChapterSplitter.countWords(''), equals(0));
        expect(ChapterSplitter.countWords('   '), equals(0));
        expect(ChapterSplitter.countWords('<p></p>'), equals(0));
        expect(ChapterSplitter.countWords('<p>   </p>'), equals(0));
      });
    });

    group('HTML Content Splitting', () {
      test('splits content with no paragraphs using character count', () {
        final noParagraphContent = '<div>${'word ' * 1000}</div>';
        final parts = ChapterSplitter.splitHtmlContent(noParagraphContent, 500);
        
        expect(parts.length, equals(2));
        // Check that content was split approximately evenly
        expect(parts[0].length, closeTo(parts[1].length, 100));
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
    });

    group('Chapter Splitting Edge Cases', () {
      test('handles chapters with exactly 5000 words', () {
        // Create content with exactly 5000 words
        final exactContent = List.generate(50, (i) => '<p>${'word ' * 100}</p>').join();
        final chapter = EpubChapter(
          title: 'Exact Chapter',
          htmlContent: exactContent,
        );
        
        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(1));
        expect(result[0].title, equals('Exact Chapter'));
      });

      test('splits very large chapters into multiple parts', () {
        // Create content with ~15000 words
        final veryLongContent = List.generate(75, (i) => '<p>${'word ' * 200}</p>').join();
        final chapter = EpubChapter(
          title: 'Very Long Chapter',
          htmlContent: veryLongContent,
        );
        
        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(3));
        expect(result[0].title, equals('Very Long Chapter - Part 1'));
        expect(result[1].title, equals('Very Long Chapter - Part 2'));
        expect(result[2].title, equals('Very Long Chapter - Part 3'));
        
        // Verify each part is under the word limit
        for (final part in result) {
          final wordCount = ChapterSplitter.countWords(part.htmlContent);
          expect(wordCount, lessThanOrEqualTo(5000));
        }
      });

      test('handles chapters with no title', () {
        final content = List.generate(30, (i) => '<p>${'word ' * 200}</p>').join();
        final chapter = EpubChapter(
          title: null,
          htmlContent: content,
        );
        
        final result = ChapterSplitter.splitChapter(chapter);
        expect(result.length, equals(2));
        expect(result[0].title, equals('Part 1'));
        expect(result[1].title, equals('Part 2'));
      });

      test('preserves chapter metadata in split parts', () {
        final content = List.generate(30, (i) => '<p>${'word ' * 200}</p>').join();
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
          htmlContent: List.generate(30, (i) => '<p>${'word ' * 200}</p>').join(),
          subChapters: [subSubChapter],
        );
        
        final mainChapter = EpubChapter(
          title: 'Main Chapter',
          htmlContent: List.generate(30, (i) => '<p>${'word ' * 200}</p>').join(),
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
        expect(splitSubChapters[0].title, equals('Sub Chapter - Part 1'));
        
        // The sub-sub-chapter should be preserved in the first part of the sub-chapter
        expect(splitSubChapters[0].subChapters.length, equals(1));
        expect(splitSubChapters[0].subChapters[0].title, equals('Sub-Sub Chapter'));
      });
    });

    group('Performance and Special Cases', () {
      test('handles chapters with many small paragraphs efficiently', () {
        // Create 1000 small paragraphs
        final manyParagraphs = List.generate(1000, (i) => '<p>Word $i</p>').join();
        final chapter = EpubChapter(
          title: 'Many Paragraphs',
          htmlContent: manyParagraphs,
        );
        
        final stopwatch = Stopwatch()..start();
        final result = ChapterSplitter.splitChapter(chapter);
        stopwatch.stop();
        
        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(result.length, equals(1)); // 1000 words is less than 5000
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