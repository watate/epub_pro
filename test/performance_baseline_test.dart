import 'package:epub_pro/epub_pro.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Performance Baseline Tests', () {
    test('current reader performance measurement', () async {
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      print('EPUB file size: ${epubBytes.length} bytes');

      // Test lazy loading (openBook)
      final stopwatch1 = Stopwatch()..start();
      final bookRef = await EpubReader.openBook(epubBytes);
      stopwatch1.stop();
      final lazyLoadTime = stopwatch1.elapsedMilliseconds;

      // Test eager loading (readBook)
      final stopwatch2 = Stopwatch()..start();
      final book = await EpubReader.readBook(epubBytes);
      stopwatch2.stop();
      final eagerLoadTime = stopwatch2.elapsedMilliseconds;

      print('Lazy load (openBook) time: ${lazyLoadTime}ms');
      print('Eager load (readBook) time: ${eagerLoadTime}ms');
      print('Performance difference: ${eagerLoadTime - lazyLoadTime}ms');
      print(
          'Improvement ratio: ${(eagerLoadTime / lazyLoadTime).toStringAsFixed(2)}x');

      // Verify functionality
      expect(bookRef.title, isNotEmpty);
      expect(book.title, equals(bookRef.title));
      expect(bookRef.authors, isNotEmpty);
      expect(book.authors, equals(bookRef.authors));

      final chapters = bookRef.getChapters();
      expect(chapters, isNotEmpty);
      expect(book.chapters.length, equals(chapters.length));

      // Test content loading on demand
      if (chapters.isNotEmpty) {
        final stopwatch3 = Stopwatch()..start();
        final content = await chapters[0].readHtmlContent();
        stopwatch3.stop();

        print(
            'First chapter content load time: ${stopwatch3.elapsedMilliseconds}ms');
        expect(content, isNotEmpty);
        expect(content, equals(book.chapters[0].htmlContent));
      }
    });

    test('memory efficiency comparison', () async {
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      // Lazy loading approach
      final bookRef = await EpubReader.openBook(epubBytes);
      final chapters = bookRef.getChapters();

      print('Book: ${bookRef.title}');
      print('Total chapters: ${chapters.length}');

      // Simulate accessing only some chapters (common reading pattern)
      final accessedChapters = chapters.take(3).toList();
      final stopwatch = Stopwatch()..start();

      for (final chapter in accessedChapters) {
        await chapter.readHtmlContent();
      }

      stopwatch.stop();
      print(
          'Loaded ${accessedChapters.length} chapters in: ${stopwatch.elapsedMilliseconds}ms');

      // With lazy loading, unaccessed chapters don't consume memory
      print(
          'Memory efficient: Only ${accessedChapters.length}/${chapters.length} chapters loaded');
    });

    test('chapter splitting performance', () async {
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      // Test normal reading
      final stopwatch1 = Stopwatch()..start();
      final book = await EpubReader.readBook(epubBytes);
      stopwatch1.stop();

      // Test with chapter splitting
      final stopwatch2 = Stopwatch()..start();
      final splitBook = await EpubReader.readBookWithSplitChapters(epubBytes);
      stopwatch2.stop();

      print('Normal read time: ${stopwatch1.elapsedMilliseconds}ms');
      print('Split chapters read time: ${stopwatch2.elapsedMilliseconds}ms');
      print(
          'Split overhead: ${stopwatch2.elapsedMilliseconds - stopwatch1.elapsedMilliseconds}ms');

      print('Original chapters: ${book.chapters.length}');
      print('Split chapters: ${splitBook.chapters.length}');

      expect(splitBook.chapters.length,
          greaterThanOrEqualTo(book.chapters.length));
    });

    test('concurrent access performance', () async {
      final epubFile = File('assets/alicesAdventuresUnderGround.epub');
      if (!epubFile.existsSync()) {
        print('Skipping test - alicesAdventuresUnderGround.epub not found');
        return;
      }
      final epubBytes = await epubFile.readAsBytes();

      final bookRef = await EpubReader.openBook(epubBytes);
      final chapters = bookRef.getChapters();

      if (chapters.length < 3) {
        print('Skipping concurrent test - not enough chapters');
        return;
      }

      // Test concurrent chapter loading
      final stopwatch = Stopwatch()..start();
      final futures = <Future<String>>[];

      for (var i = 0; i < 3 && i < chapters.length; i++) {
        futures.add(chapters[i].readHtmlContent());
      }

      final results = await Future.wait(futures);
      stopwatch.stop();

      print(
          'Concurrent load of 3 chapters: ${stopwatch.elapsedMilliseconds}ms');
      expect(results.every((content) => content.isNotEmpty), isTrue);
    });
  });
}
