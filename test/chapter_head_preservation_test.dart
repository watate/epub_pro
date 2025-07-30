import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:epub_pro/epub_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Chapter Head Preservation Tests', () {
    late List<String> epubFiles;

    setUpAll(() {
      final assetsDir =
          io.Directory(path.join(io.Directory.current.path, "assets"));
      epubFiles = assetsDir
          .listSync()
          .where((entity) => entity.path.endsWith('.epub'))
          .map((entity) => entity.path)
          .toList();

      if (epubFiles.isEmpty) {
        fail('No EPUB files found in assets directory');
      }
    });

    test('original chapters contain head elements', () async {
      var foundChaptersWithHeads = 0;
      var totalChaptersChecked = 0;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();
          final book = await EpubReader.readBook(bytes);

          for (final chapter in book.chapters) {
            if (chapter.htmlContent != null &&
                chapter.htmlContent!.isNotEmpty) {
              totalChaptersChecked++;

              // Check for head element
              final headPattern =
                  RegExp(r'<head[^>]*>.*?</head>', dotAll: true);
              if (headPattern.hasMatch(chapter.htmlContent!)) {
                foundChaptersWithHeads++;
              }
            }
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundChaptersWithHeads chapters with <head> out of $totalChaptersChecked total chapters');
      expect(foundChaptersWithHeads, greaterThan(0),
          reason:
              'Expected to find at least some chapters with <head> elements');
    });

    test('split chapters retain head elements', () async {
      var foundSplitChaptersWithHeads = 0;
      var totalSplitChaptersChecked = 0;
      var foundSplitChapters = false;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();

          // Read with splitting
          final splitBook = await EpubReader.readBookWithSplitChapters(bytes);

          for (final chapter in splitBook.chapters) {
            if (chapter.htmlContent != null &&
                chapter.htmlContent!.isNotEmpty) {
              // Check if this is a split chapter by looking for the (X/Y) pattern in title
              if (chapter.title != null &&
                  RegExp(r'\(\d+/\d+\)').hasMatch(chapter.title!)) {
                foundSplitChapters = true;
                totalSplitChaptersChecked++;

                // Check for head element
                final headPattern =
                    RegExp(r'<head[^>]*>.*?</head>', dotAll: true);
                if (headPattern.hasMatch(chapter.htmlContent!)) {
                  foundSplitChaptersWithHeads++;
                }
              }
            }
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundSplitChaptersWithHeads split chapters with <head> out of $totalSplitChaptersChecked total split chapters');

      if (!foundSplitChapters) {
        print(
            'No split chapters found - some EPUBs may not have chapters long enough to trigger splitting');
        return;
      }

      // This test is expected to fail, demonstrating the bug
      expect(foundSplitChaptersWithHeads, equals(totalSplitChaptersChecked),
          reason:
              'Split chapters should retain their <head> elements but currently do not');
    });

    test('split chapters preserve title elements within head', () async {
      var foundSplitChaptersWithTitles = 0;
      var totalSplitChaptersChecked = 0;
      var foundSplitChapters = false;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();

          // Read with splitting
          final splitBook = await EpubReader.readBookWithSplitChapters(bytes);

          for (final chapter in splitBook.chapters) {
            if (chapter.htmlContent != null &&
                chapter.htmlContent!.isNotEmpty) {
              // Check if this is a split chapter
              if (chapter.title != null &&
                  RegExp(r'\(\d+/\d+\)').hasMatch(chapter.title!)) {
                foundSplitChapters = true;
                totalSplitChaptersChecked++;

                // Check for title element within head
                final titlePattern = RegExp(
                    r'<head[^>]*>.*?<title[^>]*>.*?</title>.*?</head>',
                    dotAll: true);
                if (titlePattern.hasMatch(chapter.htmlContent!)) {
                  foundSplitChaptersWithTitles++;
                }
              }
            }
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundSplitChaptersWithTitles split chapters with <title> in <head> out of $totalSplitChaptersChecked total split chapters');

      if (!foundSplitChapters) {
        print(
            'No split chapters found - some EPUBs may not have chapters long enough to trigger splitting');
        return;
      }

      // This test is expected to fail, demonstrating the bug
      expect(foundSplitChaptersWithTitles, greaterThan(0),
          reason:
              'Split chapters should preserve <title> elements within <head> but currently do not');
    });

    test('split chapters preserve CSS links in head', () async {
      var foundSplitChaptersWithCSS = 0;
      var totalSplitChaptersChecked = 0;
      var foundSplitChapters = false;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();

          // Read with splitting
          final splitBook = await EpubReader.readBookWithSplitChapters(bytes);

          for (final chapter in splitBook.chapters) {
            if (chapter.htmlContent != null &&
                chapter.htmlContent!.isNotEmpty) {
              // Check if this is a split chapter
              if (chapter.title != null &&
                  RegExp(r'\(\d+/\d+\)').hasMatch(chapter.title!)) {
                foundSplitChapters = true;
                totalSplitChaptersChecked++;

                // Check for CSS link elements within head
                final cssPattern = RegExp(
                    r'<head[^>]*>.*?<link[^>]*rel=["\x27]stylesheet["\x27][^>]*>.*?</head>',
                    dotAll: true);
                if (cssPattern.hasMatch(chapter.htmlContent!)) {
                  foundSplitChaptersWithCSS++;
                }
              }
            }
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundSplitChaptersWithCSS split chapters with CSS links in <head> out of $totalSplitChaptersChecked total split chapters');

      if (!foundSplitChapters) {
        print(
            'No split chapters found - some EPUBs may not have chapters long enough to trigger splitting');
        return;
      }

      // This test is expected to fail, demonstrating the bug
      expect(foundSplitChaptersWithCSS, greaterThan(0),
          reason:
              'Split chapters should preserve CSS link elements within <head> but currently do not');
    });
  });
}
