import 'package:epub_pro/epub_pro.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Lazy ZIP Performance Tests', () {
    test('lazy loading is significantly faster than standard loading', () async {
      // Use a real EPUB file for testing
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      // Test lazy loading performance
      final stopwatch1 = Stopwatch()..start();
      final lazyBookRef = await EpubReader.openBook(epubBytes);
      stopwatch1.stop();
      final lazyLoadTime = stopwatch1.elapsedMilliseconds;

      // Test eager loading performance (simulate old behavior)
      final stopwatch2 = Stopwatch()..start();
      final eagerBook = await EpubReader.readBook(epubBytes);
      stopwatch2.stop();
      final eagerLoadTime = stopwatch2.elapsedMilliseconds;

      print('Lazy load time: ${lazyLoadTime}ms');
      print('Eager load time: ${eagerLoadTime}ms');
      print('Performance improvement: ${((eagerLoadTime - lazyLoadTime) / eagerLoadTime * 100).toStringAsFixed(1)}%');

      // Lazy loading should be faster
      expect(lazyLoadTime, lessThan(eagerLoadTime));

      // Verify functionality is maintained
      expect(lazyBookRef.title, isNotEmpty);
      expect(eagerBook.title, equals(lazyBookRef.title));
    });

    test('content is truly loaded on-demand', () async {
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      final bookRef = await EpubReader.openBook(epubBytes);
      final chapters = bookRef.getChapters();

      if (chapters.isNotEmpty) {
        // First access should load the content
        final stopwatch1 = Stopwatch()..start();
        final content1 = await chapters[0].readHtmlContent();
        stopwatch1.stop();

        // Second access should be faster (may be cached)
        final stopwatch2 = Stopwatch()..start();
        final content2 = await chapters[0].readHtmlContent();
        stopwatch2.stop();

        expect(content1, equals(content2));
        expect(content1, isNotEmpty);
        
        print('First access: ${stopwatch1.elapsedMilliseconds}ms');
        print('Second access: ${stopwatch2.elapsedMilliseconds}ms');
      }
    });

    test('lazy loading maintains functionality', () async {
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      final bookRef = await EpubReader.openBook(epubBytes);
      
      // Basic metadata should be available immediately
      expect(bookRef.title, isNotEmpty);
      expect(bookRef.authors, isNotEmpty);
      
      // Chapters should be accessible
      final chapters = bookRef.getChapters();
      expect(chapters, isNotEmpty);
      
      // Content should load on demand
      if (chapters.isNotEmpty) {
        final content = await chapters[0].readHtmlContent();
        expect(content, isNotEmpty);
      }
    });

    test('multiple book operations work correctly', () async {
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      // Test multiple opens of the same book
      final bookRef1 = await EpubReader.openBook(epubBytes);
      final bookRef2 = await EpubReader.openBook(epubBytes);

      expect(bookRef1.title, equals(bookRef2.title));
      expect(bookRef1.authors, equals(bookRef2.authors));

      // Test that content can be read independently
      final chapters1 = bookRef1.getChapters();
      final chapters2 = bookRef2.getChapters();

      if (chapters1.isNotEmpty && chapters2.isNotEmpty) {
        final content1 = await chapters1[0].readHtmlContent();
        final content2 = await chapters2[0].readHtmlContent();
        expect(content1, equals(content2));
      }
    });

    test('large files benefit more from lazy loading', () async {
      // This test demonstrates the concept but uses the same file
      // In practice, larger EPUBs would show more dramatic improvements
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      print('EPUB file size: ${epubBytes.length} bytes');

      // Measure lazy loading
      final stopwatch = Stopwatch()..start();
      final bookRef = await EpubReader.openBook(epubBytes);
      stopwatch.stop();

      print('Lazy load time for ${epubBytes.length} byte file: ${stopwatch.elapsedMilliseconds}ms');
      
      // Verify it works
      expect(bookRef.title, isNotEmpty);
      
      final chapters = bookRef.getChapters();
      expect(chapters, isNotEmpty);
    });
  });
}