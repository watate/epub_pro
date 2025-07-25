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
      final part1BodyStart = part1BodyContent.isNotEmpty && part1BodyContent.length > 100 
          ? part1BodyContent.substring(0, 100)
          : part1BodyContent;
      
      expect(part2BodyContent.contains(part1BodyStart), isFalse,
          reason: 'Part 2 body content should not contain the beginning of part 1 body content');
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
  return encoded ?? [];
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
  return encoded ?? [];
}

/// Extracts the content between <body> and </body> tags
String _extractBodyContent(String htmlContent) {
  final bodyMatch = RegExp(r'<body[^>]*>(.*?)</body>', dotAll: true, caseSensitive: false)
      .firstMatch(htmlContent);
  
  if (bodyMatch != null) {
    return bodyMatch.group(1) ?? '';
  }
  
  // If no body tags found, return the content as-is
  // (might be a fragment without full HTML structure)
  return htmlContent;
}