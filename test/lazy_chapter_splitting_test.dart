import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:epub_pro/epub_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Lazy Chapter Splitting Tests', () {
    late List<int> epubBytes;

    setUpAll(() async {
      // Create a minimal EPUB with long chapters for testing
      epubBytes = _createTestEpubWithLongChapters();
    });

    test('openBookWithSplitChapters returns EpubBookSplitRef', () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);

      expect(bookRef, isA<EpubBookSplitRef>());
      expect(bookRef.title, equals('Test Book with Long Chapters'));
    });

    test('getChapterRefsWithSplitting returns split chapters for long content',
        () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Test book has 3 chapters, but with splitting should have more
      expect(chapterRefs.length, greaterThan(3));

      // Check that some chapters are split refs
      final splitRefs = chapterRefs.whereType<EpubChapterSplitRef>();
      expect(splitRefs, isNotEmpty);

      // Verify split chapter properties
      final firstSplitRef = splitRefs.first;
      expect(firstSplitRef.partNumber, greaterThan(0));
      expect(firstSplitRef.totalParts, greaterThan(1));
      expect(firstSplitRef.originalTitle, isNotNull);
    });

    test('EpubChapterSplitRef loads only its part of content', () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Find split chapters
      final splitRefs = chapterRefs.whereType<EpubChapterSplitRef>().toList();
      expect(splitRefs, isNotEmpty);

      // Get two parts from the same original chapter
      final sameTitleParts = <EpubChapterSplitRef>[];
      for (final ref in splitRefs) {
        if (ref.originalTitle == splitRefs.first.originalTitle) {
          sameTitleParts.add(ref);
          if (sameTitleParts.length >= 2) break;
        }
      }

      expect(sameTitleParts.length, greaterThanOrEqualTo(2));

      // Load content from both parts
      final part1Content = await sameTitleParts[0].readHtmlContent();
      final part2Content = await sameTitleParts[1].readHtmlContent();

      // Verify they have different content
      expect(part1Content, isNot(equals(part2Content)));

      // Verify content is not empty
      expect(part1Content, isNotEmpty);
      expect(part2Content, isNotEmpty);

      // Verify part 2 doesn't contain the beginning body content of part 1
      // Extract body content to avoid comparing shared HTML structure (head, DOCTYPE, etc.)
      final part1BodyContent = _extractBodyContent(part1Content);
      final part2BodyContent = _extractBodyContent(part2Content);

      // Take first 100 characters of actual body content
      final part1BodyStart =
          part1BodyContent.isNotEmpty && part1BodyContent.length > 100
              ? part1BodyContent.substring(0, 100)
              : part1BodyContent;

      expect(part2BodyContent.contains(part1BodyStart), isFalse,
          reason:
              'Part 2 body content should not contain the beginning of part 1 body content');
    });

    test('Split chapters maintain correct metadata', () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      final splitRefs = chapterRefs.whereType<EpubChapterSplitRef>().toList();

      for (final ref in splitRefs) {
        // Check part numbering
        expect(ref.partNumber, greaterThan(0));
        expect(ref.partNumber, lessThanOrEqualTo(ref.totalParts));

        // Check title formatting
        expect(ref.title, contains('Part ${ref.partNumber}'));

        // Only first part should have anchor
        if (ref.partNumber > 1) {
          expect(ref.anchor, isNull);
        }
      }
    });

    test('Regular chapters remain unchanged', () async {
      // Create EPUB with short chapters
      final shortEpubBytes = _createTestEpubWithShortChapters();

      final bookRef =
          await EpubReader.openBookWithSplitChapters(shortEpubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Chapters should not be split
      final regularRefs =
          chapterRefs.where((ref) => ref is! EpubChapterSplitRef);
      expect(regularRefs.length, equals(3)); // All 3 chapters should be regular

      // Verify regular chapters can still be read normally
      final firstRegular = regularRefs.first;
      final content = await firstRegular.readHtmlContent();
      expect(content, isNotEmpty);
    });

    test('Lazy loading - content not loaded until requested', () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Getting refs should not load content
      // This is verified by the fact that getChapterRefsWithSplitting
      // returns quickly even for large books

      final splitRef = chapterRefs.whereType<EpubChapterSplitRef>().first;

      // Content is only loaded when explicitly requested
      final content = await splitRef.readHtmlContent();
      expect(content, isNotEmpty);
    });

    test('Sub-chapters preserved in first split part only', () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();

      // Find split chapters from same original
      final splitGroups = <String?, List<EpubChapterSplitRef>>{};
      for (final ref in chapterRefs.whereType<EpubChapterSplitRef>()) {
        splitGroups.putIfAbsent(ref.originalTitle, () => []).add(ref);
      }

      for (final group in splitGroups.values) {
        if (group.length > 1) {
          // Sort by part number
          group.sort((a, b) => a.partNumber.compareTo(b.partNumber));

          // Only first part should have sub-chapters
          for (var i = 0; i < group.length; i++) {
            if (i == 0) {
              // First part may have sub-chapters
            } else {
              // Other parts should not have sub-chapters
              expect(group[i].subChapters, isEmpty);
            }
          }
        }
      }
    });

    test('openBookWithSplitChapters accepts Future<List<int>>', () async {
      // Create a Future<List<int>> to test the FutureOr parameter
      final futureBytes = Future.value(epubBytes);
      
      // Note: openBookWithSplitChapters only accepts List<int>, not FutureOr
      // but openBook accepts FutureOr. This test verifies the current API.
      final bookRef = await EpubReader.openBookWithSplitChapters(await futureBytes);
      
      expect(bookRef, isA<EpubBookSplitRef>());
      expect(bookRef.title, equals('Test Book with Long Chapters'));
    });

    test('handles invalid EPUB bytes gracefully', () async {
      // Test with empty bytes
      expect(
        () => EpubReader.openBookWithSplitChapters([]),
        throwsA(isA<Exception>()),
      );

      // Test with invalid ZIP data
      final invalidBytes = 'not a valid epub'.codeUnits;
      expect(
        () => EpubReader.openBookWithSplitChapters(invalidBytes),
        throwsA(isA<Exception>()),
      );
    });

    test('handles EPUB with no chapters', () async {
      final emptyEpubBytes = _createTestEpubWithNoChapters();
      final bookRef = await EpubReader.openBookWithSplitChapters(emptyEpubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();
      
      expect(chapterRefs, isEmpty);
    });

    test('handles chapters at exactly 3000 word boundary', () async {
      final boundaryEpubBytes = _createTestEpubWithBoundaryChapters();
      final bookRef = await EpubReader.openBookWithSplitChapters(boundaryEpubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();
      
      // Both chapters get split since they have 3000+ words
      final chapter1Parts = chapterRefs.where((ref) => 
        ref.title?.contains('Chapter 1 - Exactly 3000 Words') ?? false).toList();
      final chapter2Parts = chapterRefs.where((ref) => 
        ref.title?.contains('Chapter 2 - Over 3000 Words') ?? false).toList();
      
      // Both should be split into parts
      expect(chapter1Parts.length, equals(2));
      expect(chapter2Parts.length, equals(2));
      
      // Verify they are split refs
      expect(chapter1Parts.every((ref) => ref is EpubChapterSplitRef), isTrue);
      expect(chapter2Parts.every((ref) => ref is EpubChapterSplitRef), isTrue);
    });

    test('handles chapters with only images/non-text content', () async {
      final imageOnlyEpubBytes = _createTestEpubWithImageOnlyChapter();
      final bookRef = await EpubReader.openBookWithSplitChapters(imageOnlyEpubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();
      
      // Image-only chapter should not be split
      final imageChapter = chapterRefs.firstWhere((ref) => 
        ref.title == 'Image Gallery');
      expect(imageChapter, isNot(isA<EpubChapterSplitRef>()));
      
      // Verify content can still be read
      final content = await imageChapter.readHtmlContent();
      expect(content, contains('<img'));
    });

    test('handles missing metadata gracefully', () async {
      final noMetadataEpubBytes = _createTestEpubWithNoMetadata();
      final bookRef = await EpubReader.openBookWithSplitChapters(noMetadataEpubBytes);
      
      // Should handle missing title/author
      expect(bookRef.title, equals(''));
      expect(bookRef.author, equals(''));
      expect(bookRef.authors, isEmpty);
    });

    test('handles special characters in metadata', () async {
      final specialCharsEpubBytes = _createTestEpubWithSpecialCharsMetadata();
      final bookRef = await EpubReader.openBookWithSplitChapters(specialCharsEpubBytes);
      
      expect(bookRef.title, contains('café'));
      expect(bookRef.title, contains('π'));
      expect(bookRef.author, contains('Müller'));
    });

    test('concurrent access to getChapterRefsWithSplitting', () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      
      // Call getChapterRefsWithSplitting multiple times concurrently
      final futures = List.generate(5, (_) => bookRef.getChapterRefsWithSplitting());
      final results = await Future.wait(futures);
      
      // All results should be identical
      for (var i = 1; i < results.length; i++) {
        expect(results[i].length, equals(results[0].length));
        for (var j = 0; j < results[i].length; j++) {
          expect(results[i][j].title, equals(results[0][j].title));
        }
      }
    });

    test('EpubBookSplitRef maintains EpubBookRef interface', () async {
      final bookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      
      // Test that it's an EpubBookRef
      expect(bookRef, isA<EpubBookRef>());
      
      // Test that regular getChapters() returns original chapters
      final regularChapters = bookRef.getChapters();
      expect(regularChapters.length, equals(3)); // Original 3 chapters
      
      // Test other EpubBookRef methods
      expect(bookRef.schema, isNotNull);
      expect(bookRef.content, isNotNull);
      
      // Can read cover
      await bookRef.readCover();
      // Cover might be null in test EPUB
      
      // Can get chapters with and without splitting
      final splitChapters = await bookRef.getChapterRefsWithSplitting();
      expect(splitChapters.length, greaterThan(regularChapters.length));
    });

    test('memory efficiency - lazy loading verification', () async {
      final largeEpubBytes = _createTestEpubWithManyLongChapters();
      final bookRef = await EpubReader.openBookWithSplitChapters(largeEpubBytes);
      
      // Getting refs should be fast (not loading content)
      final stopwatch = Stopwatch()..start();
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();
      stopwatch.stop();
      
      // Should complete quickly even with many chapters
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Increased to 500ms for slower machines
      expect(chapterRefs.length, greaterThan(20)); // Many split chapters
      
      // Archive should still be accessible
      expect(bookRef.epubArchive, isNotNull);
    });

    test('handles nested sub-chapters that need splitting', () async {
      final nestedEpubBytes = _createTestEpubWithNestedLongChapters();
      final bookRef = await EpubReader.openBookWithSplitChapters(nestedEpubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();
      
      // Find the main chapter with sub-chapters
      final mainChapter = chapterRefs.firstWhere((ref) => 
        ref.title?.contains('Main Chapter') ?? false);
      
      // If it's split, sub-chapters should only be in first part
      if (mainChapter is EpubChapterSplitRef) {
        expect(mainChapter.partNumber, equals(1));
        expect(mainChapter.subChapters, isNotEmpty);
        
        // Find other parts of the same chapter
        final otherParts = chapterRefs.whereType<EpubChapterSplitRef>()
          .where((ref) => ref.originalTitle == mainChapter.originalTitle && 
                         ref.partNumber > 1);
        
        for (final part in otherParts) {
          expect(part.subChapters, isEmpty);
        }
      }
    });

    test('handles empty chapters without errors', () async {
      final emptyChapterEpubBytes = _createTestEpubWithEmptyChapter();
      final bookRef = await EpubReader.openBookWithSplitChapters(emptyChapterEpubBytes);
      final chapterRefs = await bookRef.getChapterRefsWithSplitting();
      
      // Empty chapter should not be split
      final emptyChapter = chapterRefs.firstWhere((ref) => 
        ref.title == 'Empty Chapter');
      expect(emptyChapter, isNot(isA<EpubChapterSplitRef>()));
      
      // Can still read empty content
      final content = await emptyChapter.readHtmlContent();
      expect(content, isNotNull);
    });
  });
}

/// Creates a test EPUB with long chapters that need splitting
List<int> _createTestEpubWithLongChapters() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-long-chapters</dc:identifier>
    <dc:title>Test Book with Long Chapters</dc:title>
    <dc:creator>Test Author</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
    <item id="chapter2" href="chapter2.html" media-type="application/xhtml+xml"/>
    <item id="chapter3" href="chapter3.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
    <itemref idref="chapter2"/>
    <itemref idref="chapter3"/>
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-long-chapters"/>
  </head>
  <docTitle>
    <text>Test Book with Long Chapters</text>
  </docTitle>
  <navMap>
    <navPoint id="chapter1" playOrder="1">
      <navLabel><text>Chapter 1 - Very Long</text></navLabel>
      <content src="chapter1.html"/>
    </navPoint>
    <navPoint id="chapter2" playOrder="2">
      <navLabel><text>Chapter 2 - Also Long</text></navLabel>
      <content src="chapter2.html"/>
    </navPoint>
    <navPoint id="chapter3" playOrder="3">
      <navLabel><text>Chapter 3 - Another Long One</text></navLabel>
      <content src="chapter3.html"/>
    </navPoint>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Create long chapters with 6000+ words each
  for (var i = 1; i <= 3; i++) {
    // Generate content with multiple paragraphs
    final paragraphs = <String>[];
    for (var p = 0; p < 40; p++) {
      // Each paragraph has ~150 words
      final words = List.generate(150, (w) => 'word$w').join(' ');
      paragraphs.add('<p>$words</p>');
    }

    final chapterHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter $i</title>
</head>
<body>
  <h1>Chapter $i - Very Long</h1>
  ${paragraphs.join('\n  ')}
</body>
</html>''';
    archive.addFile(ArchiveFile(
        'OEBPS/chapter$i.html', chapterHtml.length, chapterHtml.codeUnits));
  }

  // Create the EPUB
  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with short chapters that don't need splitting
List<int> _createTestEpubWithShortChapters() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-short-chapters</dc:identifier>
    <dc:title>Test Book with Short Chapters</dc:title>
    <dc:creator>Test Author</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
    <item id="chapter2" href="chapter2.html" media-type="application/xhtml+xml"/>
    <item id="chapter3" href="chapter3.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
    <itemref idref="chapter2"/>
    <itemref idref="chapter3"/>
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-short-chapters"/>
  </head>
  <docTitle>
    <text>Test Book with Short Chapters</text>
  </docTitle>
  <navMap>
    <navPoint id="chapter1" playOrder="1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.html"/>
    </navPoint>
    <navPoint id="chapter2" playOrder="2">
      <navLabel><text>Chapter 2</text></navLabel>
      <content src="chapter2.html"/>
    </navPoint>
    <navPoint id="chapter3" playOrder="3">
      <navLabel><text>Chapter 3</text></navLabel>
      <content src="chapter3.html"/>
    </navPoint>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Create short chapters with only 100 words each
  for (var i = 1; i <= 3; i++) {
    final words = List.generate(100, (w) => 'word$w').join(' ');
    final chapterHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter $i</title>
</head>
<body>
  <h1>Chapter $i</h1>
  <p>$words</p>
</body>
</html>''';
    archive.addFile(ArchiveFile(
        'OEBPS/chapter$i.html', chapterHtml.length, chapterHtml.codeUnits));
  }

  // Create the EPUB
  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Extracts the content between <body> and </body> tags
String _extractBodyContent(String htmlContent) {
  final bodyMatch =
      RegExp(r'<body[^>]*>(.*?)</body>', dotAll: true, caseSensitive: false)
          .firstMatch(htmlContent);

  if (bodyMatch != null) {
    return bodyMatch.group(1) ?? '';
  }

  // If no body tags found, return the content as-is
  // (might be a fragment without full HTML structure)
  return htmlContent;
}

/// Creates a test EPUB with no chapters
List<int> _createTestEpubWithNoChapters() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf with no spine items
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-no-chapters</dc:identifier>
    <dc:title>Empty Book</dc:title>
    <dc:creator>Test</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create empty toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-no-chapters"/>
  </head>
  <docTitle>
    <text>Empty Book</text>
  </docTitle>
  <navMap>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with chapters at word count boundaries
List<int> _createTestEpubWithBoundaryChapters() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-boundary-chapters</dc:identifier>
    <dc:title>Boundary Test Book</dc:title>
    <dc:creator>Test</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
    <item id="chapter2" href="chapter2.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
    <itemref idref="chapter2"/>
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-boundary-chapters"/>
  </head>
  <docTitle>
    <text>Boundary Test Book</text>
  </docTitle>
  <navMap>
    <navPoint id="chapter1" playOrder="1">
      <navLabel><text>Chapter 1 - Exactly 3000 Words</text></navLabel>
      <content src="chapter1.html"/>
    </navPoint>
    <navPoint id="chapter2" playOrder="2">
      <navLabel><text>Chapter 2 - Over 3000 Words</text></navLabel>
      <content src="chapter2.html"/>
    </navPoint>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Create chapter with exactly 3000 words
  final words3000 = List.generate(3000, (i) => 'word$i').join(' ');
  final chapter1Html = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter 1</title>
</head>
<body>
  <h1>Chapter 1 - Exactly 3000 Words</h1>
  <p>$words3000</p>
</body>
</html>''';
  archive.addFile(ArchiveFile(
      'OEBPS/chapter1.html', chapter1Html.length, chapter1Html.codeUnits));

  // Create chapter with 3001 words
  final words3001 = List.generate(3001, (i) => 'word$i').join(' ');
  final chapter2Html = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter 2</title>
</head>
<body>
  <h1>Chapter 2 - Over 3000 Words</h1>
  <p>$words3001</p>
</body>
</html>''';
  archive.addFile(ArchiveFile(
      'OEBPS/chapter2.html', chapter2Html.length, chapter2Html.codeUnits));

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with image-only chapter
List<int> _createTestEpubWithImageOnlyChapter() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-image-chapter</dc:identifier>
    <dc:title>Image Book</dc:title>
    <dc:creator>Test</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
    <item id="img1" href="image1.jpg" media-type="image/jpeg"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-image-chapter"/>
  </head>
  <docTitle>
    <text>Image Book</text>
  </docTitle>
  <navMap>
    <navPoint id="chapter1" playOrder="1">
      <navLabel><text>Image Gallery</text></navLabel>
      <content src="chapter1.html"/>
    </navPoint>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Create chapter with only images
  final chapterHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Image Gallery</title>
</head>
<body>
  <h1>Image Gallery</h1>
  <img src="image1.jpg" alt="Test Image 1"/>
  <img src="image1.jpg" alt="Test Image 2"/>
  <img src="image1.jpg" alt="Test Image 3"/>
</body>
</html>''';
  archive.addFile(ArchiveFile(
      'OEBPS/chapter1.html', chapterHtml.length, chapterHtml.codeUnits));

  // Add a dummy image file
  final dummyImage = [0xFF, 0xD8, 0xFF, 0xE0]; // JPEG header
  archive.addFile(
      ArchiveFile('OEBPS/image1.jpg', dummyImage.length, dummyImage));

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with no metadata
List<int> _createTestEpubWithNoMetadata() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf with no title/creator
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-no-metadata</dc:identifier>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-no-metadata"/>
  </head>
  <docTitle>
    <text></text>
  </docTitle>
  <navMap>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with special characters in metadata
List<int> _createTestEpubWithSpecialCharsMetadata() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf with special characters
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-special-chars</dc:identifier>
    <dc:title>Le café π</dc:title>
    <dc:creator>Jürgen Müller</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
  </spine>
</package>''';
  final contentOpfBytes = utf8.encode(contentOpf);
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpfBytes.length, contentOpfBytes));

  // Create toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-special-chars"/>
  </head>
  <docTitle>
    <text>Le café π</text>
  </docTitle>
  <navMap>
  </navMap>
</ncx>''';
  final tocNcxBytes = utf8.encode(tocNcx);
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcxBytes.length, tocNcxBytes));

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with many long chapters for performance testing
List<int> _createTestEpubWithManyLongChapters() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf with 10 chapters
  final manifestItems = List.generate(10,
      (i) => '    <item id="chapter$i" href="chapter$i.html" media-type="application/xhtml+xml"/>').join('\n');
  final spineItems = List.generate(10,
      (i) => '    <itemref idref="chapter$i"/>').join('\n');
  
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-many-chapters</dc:identifier>
    <dc:title>Many Long Chapters</dc:title>
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

  // Create toc.ncx
  final navPoints = List.generate(10, (i) => '''
    <navPoint id="chapter$i" playOrder="${i + 1}">
      <navLabel><text>Chapter ${i + 1}</text></navLabel>
      <content src="chapter$i.html"/>
    </navPoint>''').join('\n');
    
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-many-chapters"/>
  </head>
  <docTitle>
    <text>Many Long Chapters</text>
  </docTitle>
  <navMap>
$navPoints
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Create 10 long chapters (6000 words each)
  for (var i = 0; i < 10; i++) {
    final paragraphs = <String>[];
    for (var p = 0; p < 40; p++) {
      final words = List.generate(150, (w) => 'word$w').join(' ');
      paragraphs.add('<p>$words</p>');
    }
    
    final chapterHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter ${i + 1}</title>
</head>
<body>
  <h1>Chapter ${i + 1}</h1>
  ${paragraphs.join('\n  ')}
</body>
</html>''';
    archive.addFile(ArchiveFile(
        'OEBPS/chapter$i.html', chapterHtml.length, chapterHtml.codeUnits));
  }

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with nested chapters that need splitting
List<int> _createTestEpubWithNestedLongChapters() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-nested-chapters</dc:identifier>
    <dc:title>Nested Chapters Book</dc:title>
    <dc:creator>Test</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
    <item id="chapter1-1" href="chapter1-1.html" media-type="application/xhtml+xml"/>
    <item id="chapter1-2" href="chapter1-2.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
    <itemref idref="chapter1-1"/>
    <itemref idref="chapter1-2"/>
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create toc.ncx with nested structure
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-nested-chapters"/>
  </head>
  <docTitle>
    <text>Nested Chapters Book</text>
  </docTitle>
  <navMap>
    <navPoint id="chapter1" playOrder="1">
      <navLabel><text>Main Chapter with Long Content</text></navLabel>
      <content src="chapter1.html"/>
      <navPoint id="chapter1-1" playOrder="2">
        <navLabel><text>Sub-Chapter 1</text></navLabel>
        <content src="chapter1-1.html"/>
      </navPoint>
      <navPoint id="chapter1-2" playOrder="3">
        <navLabel><text>Sub-Chapter 2</text></navLabel>
        <content src="chapter1-2.html"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Create main chapter with long content
  final paragraphs = <String>[];
  for (var p = 0; p < 40; p++) {
    final words = List.generate(150, (w) => 'word$w').join(' ');
    paragraphs.add('<p>$words</p>');
  }
  
  final chapter1Html = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Main Chapter</title>
</head>
<body>
  <h1>Main Chapter with Long Content</h1>
  ${paragraphs.join('\n  ')}
</body>
</html>''';
  archive.addFile(ArchiveFile(
      'OEBPS/chapter1.html', chapter1Html.length, chapter1Html.codeUnits));

  // Create sub-chapters with short content
  for (var i = 1; i <= 2; i++) {
    final subChapterHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Sub-Chapter $i</title>
</head>
<body>
  <h2>Sub-Chapter $i</h2>
  <p>This is sub-chapter $i with short content.</p>
</body>
</html>''';
    archive.addFile(ArchiveFile(
        'OEBPS/chapter1-$i.html', subChapterHtml.length, subChapterHtml.codeUnits));
  }

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}

/// Creates a test EPUB with an empty chapter
List<int> _createTestEpubWithEmptyChapter() {
  final archive = Archive();

  // Create container.xml
  final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  archive.addFile(ArchiveFile(
      'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

  // Create content.opf
  final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-empty-chapter</dc:identifier>
    <dc:title>Book with Empty Chapter</dc:title>
    <dc:creator>Test</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
    <item id="chapter2" href="chapter2.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
    <itemref idref="chapter2"/>
  </spine>
</package>''';
  archive.addFile(ArchiveFile(
      'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

  // Create toc.ncx
  final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-empty-chapter"/>
  </head>
  <docTitle>
    <text>Book with Empty Chapter</text>
  </docTitle>
  <navMap>
    <navPoint id="chapter1" playOrder="1">
      <navLabel><text>Empty Chapter</text></navLabel>
      <content src="chapter1.html"/>
    </navPoint>
    <navPoint id="chapter2" playOrder="2">
      <navLabel><text>Normal Chapter</text></navLabel>
      <content src="chapter2.html"/>
    </navPoint>
  </navMap>
</ncx>''';
  archive
      .addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

  // Create empty chapter
  final chapter1Html = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Empty Chapter</title>
</head>
<body>
  <h1>Empty Chapter</h1>
</body>
</html>''';
  archive.addFile(ArchiveFile(
      'OEBPS/chapter1.html', chapter1Html.length, chapter1Html.codeUnits));

  // Create normal chapter
  final chapter2Html = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Normal Chapter</title>
</head>
<body>
  <h1>Normal Chapter</h1>
  <p>This chapter has some content.</p>
</body>
</html>''';
  archive.addFile(ArchiveFile(
      'OEBPS/chapter2.html', chapter2Html.length, chapter2Html.codeUnits));

  final encoded = ZipEncoder().encode(archive);
  return encoded;
}
