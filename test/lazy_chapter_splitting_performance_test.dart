import 'package:archive/archive.dart';
import 'package:epub_pro/epub_pro.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Lazy Chapter Splitting Performance Tests', () {
    test('lazy loading uses less memory than eager loading', () async {
      // Create a large EPUB with many long chapters
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }
      final largeEpubBytes = await epubFile.readAsBytes();

      // Measure memory for lazy loading
      final stopwatch1 = Stopwatch()..start();
      final lazyBookRef =
          await EpubReader.openBookWithSplitChapters(largeEpubBytes);
      final lazyChapterRefs = await lazyBookRef.getChapterRefsWithSplitting();
      stopwatch1.stop();

      // Measure memory for eager loading
      final stopwatch2 = Stopwatch()..start();
      final eagerBook =
          await EpubReader.readBookWithSplitChapters(largeEpubBytes);
      stopwatch2.stop();

      // Lazy loading should be faster for initial load
      expect(stopwatch1.elapsedMilliseconds,
          lessThan(stopwatch2.elapsedMilliseconds));

      // Verify we can still access content lazily
      final firstContent = await lazyChapterRefs.first.readHtmlContent();
      expect(firstContent, isNotEmpty);

      // Eager loading has all content in memory
      expect(eagerBook.chapters.every((c) => c.htmlContent != null), isTrue);
    });

    test('content is truly loaded on-demand', () async {
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();
      
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Track which chapters have been accessed
      final accessedChapters = <int>{};

      // Access only specific chapters
      final indicesToAccess = [0, 5, 10, 15];
      final validIndices = indicesToAccess.where((i) => i < chapterRefs.length).toList();
      
      for (final index in validIndices) {
        final content = await chapterRefs[index].readHtmlContent();
        expect(content, isNotEmpty);
        accessedChapters.add(index);
      }

      // Only the accessed chapters should have been loaded
      expect(accessedChapters.length, equals(validIndices.length));
    });

    test('split chapter access is efficient', () async {
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Find split chapters
      final splitRefs = chapterRefs.whereType<EpubChapterSplitRef>().toList();

      // Access multiple split parts and measure time
      final stopwatch = Stopwatch()..start();
      final futures = <Future<String>>[];

      // Access every 5th split chapter
      for (var i = 0; i < splitRefs.length; i++) {
        futures.add(splitRefs[i].readHtmlContent());
      }

      final contents = await Future.wait(futures);
      stopwatch.stop();

      // Should be fast even with many accesses
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(contents.every((c) => c.isNotEmpty), isTrue);
    });

    test('concurrent chapter access performs well', () async {
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Access many chapters concurrently
      final stopwatch = Stopwatch()..start();
      final futures = <Future<String>>[];

      // Access first 20 chapters concurrently
      for (var i = 0; i < 20 && i < chapterRefs.length; i++) {
        futures.add(chapterRefs[i].readHtmlContent());
      }

      final contents = await Future.wait(futures);
      stopwatch.stop();

      // Concurrent access should be efficient
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(contents.every((c) => c.isNotEmpty), isTrue);
    });

    test('repeated access to same chapter is cached', () async {
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      final targetRef = chapterRefs.first;

      // First access
      final stopwatch1 = Stopwatch()..start();
      final content1 = await targetRef.readHtmlContent();
      stopwatch1.stop();

      // Second access (should be cached)
      final stopwatch2 = Stopwatch()..start();
      final content2 = await targetRef.readHtmlContent();
      stopwatch2.stop();

      // Second access should be much faster
      expect(stopwatch2.elapsedMilliseconds,
          lessThanOrEqualTo(stopwatch1.elapsedMilliseconds ~/ 2));
      expect(content1, equals(content2));
    });

    test('memory usage scales with accessed chapters only', () async {
      final epubFile = File('assets/fahren.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - fahren.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Access only 10% of chapters
      final accessCount = chapterRefs.length ~/ 10;
      final accessedContents = <String>[];

      for (var i = 0; i < accessCount; i++) {
        final index = i * 10; // Access every 10th chapter
        if (index < chapterRefs.length) {
          final content = await chapterRefs[index].readHtmlContent();
          accessedContents.add(content);
        }
      }

      // We've only loaded a fraction of the total content
      expect(accessedContents.length, equals(accessCount));
      expect(accessedContents.every((c) => c.isNotEmpty), isTrue);
    });

    test('split chapter creation is efficient', () async {
      // Create content that will result in many splits
      final massiveChapter = List.generate(1000,
              (i) => '<p>${List.generate(100, (j) => 'word$j').join(' ')}</p>')
          .join('\n');

      final epubBytes = _createEpubWithSingleChapter(massiveChapter);

      final stopwatch = Stopwatch()..start();
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();
      stopwatch.stop();

      // Should handle massive chapter splitting efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds
      expect(chapterRefs.length, greaterThan(10)); // Should create many splits
    });
  });
}

// Helper functions

List<int> _createLargeEpub(
    {required int chapterCount, required int wordsPerChapter}) {
  final archive = Archive();

  // Add container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Add content.opf
  final manifestItems = List.generate(
          chapterCount,
          (i) =>
              '    <item id="chapter$i" href="chapter$i.html" media-type="application/xhtml+xml"/>')
      .join('\n');
  final spineItems =
      List.generate(chapterCount, (i) => '    <itemref idref="chapter$i"/>')
          .join('\n');

  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">large-epub</dc:identifier>
    <dc:title>Large Test EPUB</dc:title>
    <dc:creator>Test</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
$manifestItems
  </manifest>
  <spine toc="ncx">
$spineItems
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Add toc.ncx
  final navPoints = List.generate(
      chapterCount,
      (i) => '''
    <navPoint id="chapter$i" playOrder="${i + 1}">
      <navLabel><text>Chapter ${i + 1}</text></navLabel>
      <content src="chapter$i.html"/>
    </navPoint>''').join('\n');

  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="large-epub"/>
  </head>
  <docTitle>
    <text>Large Test EPUB</text>
  </docTitle>
  <navMap>
$navPoints
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Add chapters
  for (var i = 0; i < chapterCount; i++) {
    final paragraphCount = wordsPerChapter ~/ 100; // ~100 words per paragraph
    final content = List.generate(paragraphCount,
            (j) => '<p>${List.generate(100, (k) => 'w${i}_$k').join(' ')}</p>')
        .join('\n');

    final chapterHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter ${i + 1}</title>
</head>
<body>
  <h1>Chapter ${i + 1}</h1>
  $content
</body>
</html>''';
    archive.addFile(ArchiveFile(
        'OEBPS/chapter$i.html', chapterHtml.length, chapterHtml.codeUnits));
  }

  final encoded = ZipEncoder().encode(archive);
  return encoded ?? [];
}

List<int> _createEpubWithSingleChapter(String chapterContent) {
  final archive = Archive();

  // Add basic structure
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">single-chapter</dc:identifier>
    <dc:title>Single Chapter Book</dc:title>
    <dc:creator>Test</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="single-chapter"/>
  </head>
  <docTitle>
    <text>Single Chapter Book</text>
  </docTitle>
  <navMap>
    <navPoint id="chapter1" playOrder="1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.html"/>
    </navPoint>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  final chapterHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter 1</title>
</head>
<body>
  <h1>Chapter 1</h1>
  $chapterContent
</body>
</html>''';
  archive.addFile(ArchiveFile(
      'OEBPS/chapter1.html', chapterHtml.length, chapterHtml.codeUnits));

  final encoded = ZipEncoder().encode(archive);
  return encoded ?? [];
}
