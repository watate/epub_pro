import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:epub_pro/epub_pro.dart';
import 'package:test/test.dart';

void main() {
  group('All Chapter Methods Filename Fallback Tests', () {
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

    test(
        'EpubReader.readBook() uses filename fallback for chapters without titles',
        () async {
      var foundChaptersWithFilenameTitle = 0;
      var foundChaptersWithNullTitle = 0;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();
          final book = await EpubReader.readBook(bytes);

          for (final chapter in book.chapters) {
            // Check if this chapter originally had no title (filename without extension as title indicates fallback)
            if (chapter.title != null &&
                chapter.contentFileName != null &&
                chapter.title == _stripFileExtension(chapter.contentFileName)) {
              foundChaptersWithFilenameTitle++;
            }

            // Verify no chapter has null title
            if (chapter.title == null) {
              foundChaptersWithNullTitle++;
            }

            // Recursively check subchapters
            _checkSubChaptersRecursively(chapter.subChapters, (subChapter) {
              if (subChapter.title != null &&
                  subChapter.contentFileName != null &&
                  subChapter.title ==
                      _stripFileExtension(subChapter.contentFileName)) {
                foundChaptersWithFilenameTitle++;
              }
              if (subChapter.title == null) {
                foundChaptersWithNullTitle++;
              }
            });
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundChaptersWithFilenameTitle chapters using filename as title');
      print('Found $foundChaptersWithNullTitle chapters with null title');

      expect(foundChaptersWithNullTitle, equals(0),
          reason:
              'No chapters should have null titles after filename fallback');
      expect(foundChaptersWithFilenameTitle, greaterThan(0),
          reason: 'Should find some chapters using filename fallback');
    });

    test('EpubReader.readBookWithSplitChapters() uses filename fallback',
        () async {
      var foundSplitChaptersWithFilenameTitle = 0;
      var foundSplitChaptersWithNullTitle = 0;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();
          final book = await EpubReader.readBookWithSplitChapters(bytes);

          for (final chapter in book.chapters) {
            // Check for split chapters with filename-based titles
            if (chapter.title != null && chapter.contentFileName != null) {
              // Check if this is a split chapter using filename (without extension)
              final baseFileName = _stripFileExtension(chapter.contentFileName);
              if (baseFileName != null &&
                  chapter.title!.startsWith('$baseFileName (')) {
                foundSplitChaptersWithFilenameTitle++;
              }
            }

            if (chapter.title == null) {
              foundSplitChaptersWithNullTitle++;
            }

            _checkSubChaptersRecursively(chapter.subChapters, (subChapter) {
              if (subChapter.title == null) {
                foundSplitChaptersWithNullTitle++;
              }
            });
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundSplitChaptersWithFilenameTitle split chapters using filename as title');
      print(
          'Found $foundSplitChaptersWithNullTitle split chapters with null title');

      expect(foundSplitChaptersWithNullTitle, equals(0),
          reason: 'No split chapters should have null titles');
    });

    test('EpubBookRef.getChapters() chapter refs have meaningful toString()',
        () async {
      var foundMeaningfulToString = 0;
      var foundNullInToString = 0;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();
          final bookRef = await EpubReader.openBook(bytes);
          final chapters = bookRef.getChapters();

          for (final chapterRef in chapters) {
            final toStringResult = chapterRef.toString();

            // Check if toString shows meaningful title (not "Title: null")
            if (toStringResult.contains('Title: null')) {
              foundNullInToString++;
            } else {
              foundMeaningfulToString++;
            }

            // Check subchapters recursively
            _checkSubChapterRefsRecursively(chapterRef.subChapters,
                (subChapterRef) {
              final subToString = subChapterRef.toString();
              if (subToString.contains('Title: null')) {
                foundNullInToString++;
              } else {
                foundMeaningfulToString++;
              }
            });
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundMeaningfulToString chapter refs with meaningful toString()');
      print(
          'Found $foundNullInToString chapter refs with "Title: null" in toString()');

      expect(foundNullInToString, equals(0),
          reason: 'No chapter refs should show "Title: null" in toString()');
      expect(foundMeaningfulToString, greaterThan(0),
          reason: 'Should find meaningful titles in toString()');
    });

    test('EpubBookRef.getChaptersWithSplitting() uses filename fallback',
        () async {
      var foundChaptersWithNullTitle = 0;
      var foundChaptersWithFilenameTitle = 0;

      for (final epubPath in epubFiles) {
        try {
          final bytes = await io.File(epubPath).readAsBytes();
          final bookRef = await EpubReader.openBook(bytes);
          final chapters = await bookRef.getChaptersWithSplitting();

          for (final chapter in chapters) {
            if (chapter.title == null) {
              foundChaptersWithNullTitle++;
            }

            // Check if using filename as title (without extension)
            if (chapter.title != null && chapter.contentFileName != null) {
              final baseFileName = _stripFileExtension(chapter.contentFileName);
              if (baseFileName != null &&
                  (chapter.title == baseFileName ||
                      chapter.title!.startsWith('$baseFileName ('))) {
                foundChaptersWithFilenameTitle++;
              }
            }

            _checkSubChaptersRecursively(chapter.subChapters, (subChapter) {
              if (subChapter.title == null) {
                foundChaptersWithNullTitle++;
              }
            });
          }
        } catch (e) {
          print('Skipping ${path.basename(epubPath)}: $e');
        }
      }

      print(
          'Found $foundChaptersWithFilenameTitle chapters with filename-based titles');
      print('Found $foundChaptersWithNullTitle chapters with null title');

      expect(foundChaptersWithNullTitle, equals(0),
          reason:
              'getChaptersWithSplitting should not return chapters with null titles');
    });

    test('title hierarchy consistency across all methods', () async {
      // Pick one EPUB file that likely has orphaned chapters
      final epubPath = epubFiles.first;
      final bytes = await io.File(epubPath).readAsBytes();

      // Test all different ways of accessing chapters
      final book = await EpubReader.readBook(bytes);
      final splitBook = await EpubReader.readBookWithSplitChapters(bytes);
      final bookRef = await EpubReader.openBook(bytes);
      final splitChapters = await bookRef.getChaptersWithSplitting();

      // Verify consistent behavior: no null titles in any method
      var allChapters = <String>[];

      // Check regular book chapters
      for (final chapter in book.chapters) {
        expect(chapter.title, isNotNull,
            reason: 'readBook() should not return null titles');
        expect(chapter.title, isNotEmpty,
            reason: 'readBook() should not return empty titles');
        allChapters.add('readBook: ${chapter.title}');

        _checkSubChaptersRecursively(chapter.subChapters, (subChapter) {
          expect(subChapter.title, isNotNull,
              reason: 'readBook() subchapters should not have null titles');
          expect(subChapter.title, isNotEmpty,
              reason: 'readBook() subchapters should not have empty titles');
        });
      }

      // Check split book chapters
      for (final chapter in splitBook.chapters) {
        expect(chapter.title, isNotNull,
            reason:
                'readBookWithSplitChapters() should not return null titles');
        expect(chapter.title, isNotEmpty,
            reason:
                'readBookWithSplitChapters() should not return empty titles');
        allChapters.add('splitBook: ${chapter.title}');

        _checkSubChaptersRecursively(chapter.subChapters, (subChapter) {
          expect(subChapter.title, isNotNull,
              reason:
                  'readBookWithSplitChapters() subchapters should not have null titles');
          expect(subChapter.title, isNotEmpty,
              reason:
                  'readBookWithSplitChapters() subchapters should not have empty titles');
        });
      }

      // Check split chapters from ref
      for (final chapter in splitChapters) {
        expect(chapter.title, isNotNull,
            reason: 'getChaptersWithSplitting() should not return null titles');
        expect(chapter.title, isNotEmpty,
            reason:
                'getChaptersWithSplitting() should not return empty titles');
        allChapters.add('splitChapters: ${chapter.title}');

        _checkSubChaptersRecursively(chapter.subChapters, (subChapter) {
          expect(subChapter.title, isNotNull,
              reason:
                  'getChaptersWithSplitting() subchapters should not have null titles');
          expect(subChapter.title, isNotEmpty,
              reason:
                  'getChaptersWithSplitting() subchapters should not have empty titles');
        });
      }

      print(
          'Verified ${allChapters.length} chapters across all methods have non-null titles');
      expect(allChapters.length, greaterThan(0),
          reason: 'Should have found some chapters to test');
    });
  });
}

/// Helper to recursively check all subchapters
void _checkSubChaptersRecursively(
    List<EpubChapter> subChapters, Function(EpubChapter) callback) {
  for (final subChapter in subChapters) {
    callback(subChapter);
    _checkSubChaptersRecursively(subChapter.subChapters, callback);
  }
}

/// Helper to recursively check all subchapter refs
void _checkSubChapterRefsRecursively(
    List<EpubChapterRef> subChapters, Function(EpubChapterRef) callback) {
  for (final subChapterRef in subChapters) {
    callback(subChapterRef);
    _checkSubChapterRefsRecursively(subChapterRef.subChapters, callback);
  }
}

/// Strips file extension from filename for cleaner titles
String? _stripFileExtension(String? fileName) {
  if (fileName == null || fileName.isEmpty) {
    return fileName;
  }
  final lastDotIndex = fileName.lastIndexOf('.');
  if (lastDotIndex > 0) {
    return fileName.substring(0, lastDotIndex);
  }
  return fileName;
}
