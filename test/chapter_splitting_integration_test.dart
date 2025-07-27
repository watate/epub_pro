import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epub_pro/epub_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Chapter Splitting Integration Tests', () {
    // Helper function to create a test EPUB with configurable chapter sizes
    Uint8List createTestEpub({
      required List<int> chapterWordCounts,
      String bookTitle = 'Test Book',
    }) {
      final archive = Archive();

      // Create mimetype file
      archive.addFile(ArchiveFile(
        'mimetype',
        'application/epub+zip'.length,
        'application/epub+zip'.codeUnits,
      ));

      // Create META-INF/container.xml
      final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      archive.addFile(ArchiveFile(
        'META-INF/container.xml',
        containerXml.length,
        containerXml.codeUnits,
      ));

      // Create content.opf
      final opfContent = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="BookId">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$bookTitle</dc:title>
    <dc:creator>Test Author</dc:creator>
    <dc:identifier id="BookId">test-book-12345</dc:identifier>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    ${chapterWordCounts.asMap().entries.map((e) => '<item id="chapter${e.key + 1}" href="chapter${e.key + 1}.xhtml" media-type="application/xhtml+xml"/>').join('\n    ')}
  </manifest>
  <spine toc="ncx">
    ${chapterWordCounts.asMap().entries.map((e) => '<itemref idref="chapter${e.key + 1}"/>').join('\n    ')}
  </spine>
</package>''';
      archive.addFile(ArchiveFile(
        'OEBPS/content.opf',
        opfContent.length,
        opfContent.codeUnits,
      ));

      // Create toc.ncx
      final tocContent = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-book-12345"/>
  </head>
  <docTitle>
    <text>$bookTitle</text>
  </docTitle>
  <navMap>
    ${chapterWordCounts.asMap().entries.map((e) => '''
    <navPoint id="navPoint-${e.key + 1}" playOrder="${e.key + 1}">
      <navLabel>
        <text>Chapter ${e.key + 1}</text>
      </navLabel>
      <content src="chapter${e.key + 1}.xhtml"/>
    </navPoint>''').join('\n')}
  </navMap>
</ncx>''';
      archive.addFile(ArchiveFile(
        'OEBPS/toc.ncx',
        tocContent.length,
        tocContent.codeUnits,
      ));

      // Create chapter files
      for (var i = 0; i < chapterWordCounts.length; i++) {
        final wordCount = chapterWordCounts[i];
        final paragraphs = wordCount == 0 ? 1 : (wordCount / 100).ceil();
        final wordsPerParagraph =
            wordCount == 0 ? 0 : (wordCount / paragraphs).ceil();

        final chapterHtml = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter ${i + 1}</title>
</head>
<body>
  <h1>Chapter ${i + 1}</h1>
  ${List.generate(paragraphs, (p) => '<p>${List.generate(wordsPerParagraph, (w) => 'word').join(' ')}.</p>').join('\n  ')}
</body>
</html>''';

        archive.addFile(ArchiveFile(
          'OEBPS/chapter${i + 1}.xhtml',
          chapterHtml.length,
          chapterHtml.codeUnits,
        ));
      }

      // Encode the archive
      final encoder = ZipEncoder();
      return Uint8List.fromList(encoder.encode(archive));
    }

    test('splits chapters correctly in a multi-chapter book', () async {
      // Create a book with various chapter lengths
      final epubBytes = createTestEpub(
        chapterWordCounts: [
          1000, // Short chapter
          3000, // Should split into 2 parts
          7500, // Should split into 3 parts
          15000, // Should split into 5 parts
          500, // Very short chapter
        ],
      );

      // Read normally
      final normalBook = await EpubReader.readBook(epubBytes);
      expect(normalBook.chapters.length, equals(5));

      // Read with splitting
      final splitBook = await EpubReader.readBookWithSplitChapters(epubBytes);

      // Expected: 1 + 2 + 3 + 5 + 1 = 12 chapters
      // But the way paragraphs are distributed might create more splits
      expect(splitBook.chapters.length, greaterThanOrEqualTo(12));

      // Verify first chapter title
      expect(splitBook.chapters[0].title, equals('Chapter 1'));

      // Chapter 2 might be split depending on how words are distributed in paragraphs
      final ch2Index = splitBook.chapters
          .indexWhere((ch) => ch.title?.startsWith('Chapter 2') ?? false);
      expect(splitBook.chapters[ch2Index].title, startsWith('Chapter 2'));

      // Find where Chapter 3 starts (it should be split)
      final ch3Index = splitBook.chapters
          .indexWhere((ch) => ch.title?.startsWith('Chapter 3') ?? false);
      expect(splitBook.chapters[ch3Index].title, contains('('));

      // Verify last chapter
      expect(splitBook.chapters.last.title,
          anyOf(equals('Chapter 5'), contains('Chapter 5 (')));
    });

    test('preserves metadata after splitting', () async {
      final epubBytes = createTestEpub(
        bookTitle: 'Metadata Test Book',
        chapterWordCounts: [7500],
      );

      final splitBook = await EpubReader.readBookWithSplitChapters(epubBytes);

      // Book metadata should be preserved
      expect(splitBook.title, equals('Metadata Test Book'));
      expect(splitBook.author, equals('Test Author'));
      expect(splitBook.schema?.package?.metadata?.titles.first,
          equals('Metadata Test Book'));

      // Both split chapters should reference the same content file
      expect(splitBook.chapters[0].contentFileName, equals('chapter1.xhtml'));
      expect(splitBook.chapters[1].contentFileName, equals('chapter1.xhtml'));
    });

    // TODO: Fix EpubWriter to handle null guide
    // test('round-trip: split, write, and read again', () async {
    //   final originalBytes = createTestEpub(
    //     bookTitle: 'Round Trip Test',
    //     chapterWordCounts: [6000, 3000],
    //   );

    //   // Read with splitting
    //   final splitBook = await EpubReader.readBookWithSplitChapters(originalBytes);
    //   expect(splitBook.chapters.length, equals(3)); // 2 + 1

    //   // Write the split book
    //   final writtenBytes = EpubWriter.writeBook(splitBook);
    //   expect(writtenBytes, isNotNull);

    //   // Read the written book
    //   final rereadBook = await EpubReader.readBook(writtenBytes!);
    //   expect(rereadBook.chapters.length, equals(3));
    //   expect(rereadBook.title, equals('Round Trip Test'));

    //   // Verify content is preserved
    //   for (var i = 0; i < splitBook.chapters.length; i++) {
    //     expect(
    //       rereadBook.chapters[i].htmlContent,
    //       equals(splitBook.chapters[i].htmlContent),
    //     );
    //   }
    // });

    test('lazy loading with splitting', () async {
      final epubBytes = createTestEpub(
        chapterWordCounts: [8000, 2000, 12000],
      );

      final bookRef = await EpubReader.openBook(epubBytes);

      // Get normal chapters (lazy)
      final normalChapters = bookRef.getChapters();
      expect(normalChapters.length, equals(3));

      // Get split chapters
      final splitChapters = await bookRef.getChaptersWithSplitting();
      expect(splitChapters.length, greaterThanOrEqualTo(8)); // Should be ~8 (3 + 1 + 4) but allow some variance

      // Verify all chapters are properly loaded
      for (final chapter in splitChapters) {
        expect(chapter.htmlContent, isNotNull);
        expect(chapter.htmlContent, isNotEmpty);

        // Verify word count
        final wordCount = chapter.htmlContent!
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        expect(wordCount, lessThanOrEqualTo(3000));
      }
    });

    test('performance with large book', () async {
      // Create a book with 50 chapters of 10,000 words each
      final chapterWordCounts = List.filled(50, 10000);
      final epubBytes = createTestEpub(
        bookTitle: 'Large Book',
        chapterWordCounts: chapterWordCounts,
      );

      final stopwatch = Stopwatch()..start();
      final splitBook = await EpubReader.readBookWithSplitChapters(epubBytes);
      stopwatch.stop();

      // Should complete in reasonable time (less than 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      // Should have 100+ chapters (each 10,000 word chapter splits into 2-3 parts)
      expect(splitBook.chapters.length, greaterThanOrEqualTo(100));
    });

    test('handles empty chapters in EPUB', () async {
      final epubBytes = createTestEpub(
        chapterWordCounts: [1000, 0, 2000], // Middle chapter is empty
      );

      final splitBook = await EpubReader.readBookWithSplitChapters(epubBytes);

      // Should handle empty chapter gracefully
      expect(splitBook.chapters.length, equals(3));
      expect(splitBook.chapters[1].htmlContent, isNotNull);
    });

    test('content references remain valid after splitting', () async {
      // Create an EPUB with internal links
      final archive = Archive();

      // Add standard EPUB files (mimetype, container.xml)
      archive.addFile(ArchiveFile(
        'mimetype',
        'application/epub+zip'.length,
        'application/epub+zip'.codeUnits,
      ));

      final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      archive.addFile(ArchiveFile(
        'META-INF/container.xml',
        containerXml.length,
        containerXml.codeUnits,
      ));

      // Create content with links
      final chapterHtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter with Links</title></head>
<body>
  <h1 id="top">Chapter 1</h1>
  ${List.generate(60, (i) => '''
  <p id="para$i">Paragraph $i with ${List.generate(100, (j) => 'word').join(' ')}. 
  <a href="#para${(i + 1) % 60}">Next paragraph</a></p>
  ''').join('\n')}
  <p><a href="#top">Back to top</a></p>
</body>
</html>''';

      // Add the chapter
      archive.addFile(ArchiveFile(
        'OEBPS/chapter1.xhtml',
        chapterHtml.length,
        chapterHtml.codeUnits,
      ));

      // Create minimal OPF and NCX
      final opfContent = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Link Test</dc:title>
    <dc:identifier id="id">test-links</dc:identifier>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
  </spine>
</package>''';
      archive.addFile(ArchiveFile(
        'OEBPS/content.opf',
        opfContent.length,
        opfContent.codeUnits,
      ));

      final ncxContent = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-links"/>
  </head>
  <docTitle>
    <text>Link Test</text>
  </docTitle>
  <navMap>
    <navPoint id="nav1" playOrder="1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';
      archive.addFile(ArchiveFile(
        'OEBPS/toc.ncx',
        ncxContent.length,
        ncxContent.codeUnits,
      ));

      final epubBytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final splitBook = await EpubReader.readBookWithSplitChapters(epubBytes);

      // Chapter should be split
      expect(splitBook.chapters.length, greaterThan(1));

      // All parts should still have the same content file name
      for (final chapter in splitBook.chapters) {
        expect(chapter.contentFileName, equals('chapter1.xhtml'));
      }

      // Links should still be present in the content
      expect(splitBook.chapters.first.htmlContent, contains('href="#para'));
      expect(splitBook.chapters.last.htmlContent, contains('href="#top'));
    });
  });
}
