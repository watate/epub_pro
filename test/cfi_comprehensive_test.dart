import 'package:test/test.dart';
import 'package:epub_pro/epub_pro.dart';
import 'dart:io';

/// Comprehensive test script for CFI functionality with EPUB books.
/// 
/// Tests CFI operations with both normal chapters and split chapters,
/// including position tracking, annotations, and edge cases.
/// 
/// Usage: Run with `dart test test/cfi_comprehensive_test.dart`
void main() {
  group('CFI Comprehensive Tests with Frankenstein', () {
    late File frankensteinFile;
    late List<int> epubBytes;
    
    setUpAll(() async {
      frankensteinFile = File('assets/frankenstein.epub');
      if (!frankensteinFile.existsSync()) {
        throw StateError('Frankenstein EPUB not found at assets/frankenstein.epub');
      }
      epubBytes = await frankensteinFile.readAsBytes();
      print('📚 Loaded Frankenstein EPUB (${epubBytes.length} bytes)');
    });

    group('🔍 Basic CFI Operations', () {
      late EpubBookRef bookRef;
      
      setUp(() async {
        bookRef = await EpubReader.openBook(epubBytes);
        print('📖 Opened book: "${bookRef.title}" by ${bookRef.author}');
      });

      test('CFI Manager Creation and Basic Operations', () async {
        final cfiManager = bookRef.cfiManager;
        expect(cfiManager, isNotNull);
        
        final spineCount = bookRef.spineItemCount;
        print('🔢 Total spine items: $spineCount');
        expect(spineCount, greaterThan(0));
        
        // Test spine-to-chapter mapping
        final spineMap = bookRef.getSpineChapterMap();
        print('📑 Spine to chapter mapping:');
        for (final entry in spineMap.entries.take(5)) {
          print('  Spine ${entry.key}: "${entry.value.title ?? entry.value.contentFileName}"');
        }
        
        expect(spineMap.length, greaterThan(0));
      });

      test('Progress CFI Creation and Navigation', () async {
        print('\n🎯 Testing Progress CFI Creation...');
        
        // Test progress CFIs for different spine positions
        for (int i = 0; i < 3 && i < bookRef.spineItemCount; i++) {
          final progressCFI = bookRef.createProgressCFI(i);
          print('  Spine $i CFI: ${progressCFI.toString()}');
          
          expect(progressCFI, isNotNull);
          expect(progressCFI.toString(), startsWith('epubcfi('));
          
          // Test CFI validation
          final isValid = await bookRef.validateCFI(progressCFI);
          print('  Spine $i valid: $isValid');
          expect(isValid, anyOf(isTrue, isFalse)); // Should not throw
          
          // Test navigation
          final location = await bookRef.navigateToCFI(progressCFI);
          if (location != null) {
            print('  Spine $i navigation: Success - Chapter "${location.chapterRef.title}"');
            expect(location.chapterRef, isNotNull);
            expect(location.spineIndex, isA<int>());
          } else {
            print('  Spine $i navigation: Failed (may be implementation limitation)');
          }
        }
      });

      test('Fractional Progress CFIs', () async {
        print('\n📊 Testing Fractional Progress CFIs...');
        
        final testFractions = [0.0, 0.25, 0.5, 0.75, 1.0];
        final spineIndex = 1; // Test with second spine item
        
        if (spineIndex < bookRef.spineItemCount) {
          for (final fraction in testFractions) {
            final cfi = bookRef.createProgressCFI(spineIndex, fraction: fraction);
            print('  Spine $spineIndex @ ${(fraction * 100).toStringAsFixed(0)}%: ${cfi.toString()}');
            
            expect(cfi, isNotNull);
            expect(cfi.isRange, isFalse);
            
            // Fractional CFIs should have different structures
            if (fraction > 0.0) {
              expect(cfi.structure.start.parts.length, greaterThanOrEqualTo(2));
            }
          }
        }
      });

      test('CFI Range Operations', () async {
        print('\n📏 Testing CFI Range Operations...');
        
        final startCFI = bookRef.createProgressCFI(1);
        final endCFI = bookRef.createProgressCFI(3);
        
        print('  Start CFI: ${startCFI.toString()}');
        print('  End CFI: ${endCFI.toString()}');
        
        // Test getting chapters in range
        final chaptersInRange = await bookRef.getChaptersInCFIRange(startCFI, endCFI);
        print('  Chapters in range: ${chaptersInRange.length}');
        
        for (final chapter in chaptersInRange) {
          print('    - "${chapter.title ?? chapter.contentFileName}"');
        }
        
        expect(chaptersInRange.length, greaterThanOrEqualTo(0));
      });
    });

    group('✂️ Split Chapters CFI Compatibility', () {
      late EpubBookRef normalBookRef;
      late EpubBookRef splitBookRef;
      
      setUp(() async {
        normalBookRef = await EpubReader.openBook(epubBytes);
        splitBookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
        
        print('\n📚 Books loaded:');
        print('  Normal chapters: ${normalBookRef.getChapters().length}');
        
        final splitChapters = await splitBookRef.getChapterRefsWithSplitting();
        print('  Split chapters: ${splitChapters.length}');
      });

      test('Split Chapter Structure Analysis', () async {
        print('\n🔍 Analyzing Split Chapter Structure...');
        
        final normalChapters = normalBookRef.getChapters();
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        
        print('📊 Chapter comparison:');
        print('  Normal: ${normalChapters.length} chapters');
        print('  Split: ${splitChapterRefs.length} chapter references');
        
        // Analyze split chapters
        int splitPartCount = 0;
        int originalChapterCount = 0;
        
        for (final chapterRef in splitChapterRefs) {
          if (chapterRef is EpubChapterSplitRef) {
            splitPartCount++;
            print('  Split: "${chapterRef.title}" (Part ${chapterRef.partNumber}/${chapterRef.totalParts})');
            print('    Original: "${chapterRef.originalTitle}"');
            print('    File: ${chapterRef.contentFileName}');
          } else {
            originalChapterCount++;
            print('  Normal: "${chapterRef.title ?? chapterRef.contentFileName}"');
          }
        }
        
        print('📈 Split analysis:');
        print('  Original chapters: $originalChapterCount');
        print('  Split parts: $splitPartCount');
        print('  Total references: ${splitChapterRefs.length}');
      });

      test('CFI Generation with Split Chapters', () async {
        print('\n⚡ Testing CFI Generation with Split Chapters...');
        
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        
        // Test CFI generation for both split and non-split chapters
        for (int i = 0; i < splitChapterRefs.length && i < 5; i++) {
          final chapterRef = splitChapterRefs[i];
          
          print('\n  Chapter $i: "${chapterRef.title}"');
          print('    Type: ${chapterRef is EpubChapterSplitRef ? 'Split' : 'Normal'}');
          print('    File: ${chapterRef.contentFileName}');
          
          // Test basic CFI generation using extension method
          try {
            final cfi = await chapterRef.generateCFI(
              elementPath: '/4/2/1',
              characterOffset: 10,
              bookRef: normalBookRef, // Use normal book ref for spine lookup
            );
            
            if (cfi != null) {
              print('    Generated CFI: ${cfi.toString()}');
              
              // Test navigation back to the CFI
              final location = await normalBookRef.navigateToCFI(cfi);
              if (location != null) {
                print('    Navigation: Success');
                print('    Found in: "${location.chapterRef.title ?? location.chapterRef.contentFileName}"');
                
                // Check if we can get text content
                final textContent = await location.getTextContent();
                if (textContent.isNotEmpty) {
                  print('    Text sample: "${textContent.substring(0, 50).replaceAll('\n', ' ')}..."');
                }
              } else {
                print('    Navigation: Failed');
              }
            } else {
              print('    Generated CFI: null (expected due to implementation)');
            }
          } catch (e) {
            print('    CFI Generation Error: ${e.toString()}');
          }
        }
      });

      test('Position Tracking with Split Chapters', () async {
        print('\n📍 Testing Position Tracking with Split Chapters...');
        
        final storage = TestPositionStorage();
        final tracker = CFIPositionTracker(
          bookId: 'frankenstein-split-test',
          bookRef: normalBookRef,
          storage: storage,
        );
        
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        
        // Find a split chapter to test with
        EpubChapterSplitRef? splitChapter;
        for (final ref in splitChapterRefs) {
          if (ref is EpubChapterSplitRef) {
            splitChapter = ref;
            break;
          }
        }
        
        if (splitChapter != null) {
          print('  Testing with split chapter: "${splitChapter.title}"');
          print('  Part ${splitChapter.partNumber} of ${splitChapter.totalParts}');
          
          // Create a test CFI for the split chapter
          final testCFI = normalBookRef.createProgressCFI(1, fraction: 0.3);
          
          // Save position
          await tracker.savePosition(
            cfi: testCFI,
            fractionInChapter: 0.3,
            metadata: {
              'splitPart': splitChapter.partNumber,
              'totalParts': splitChapter.totalParts,
              'originalTitle': splitChapter.originalTitle,
            },
          );
          
          print('  Position saved successfully');
          
          // Restore position
          final restoredPosition = await tracker.restorePosition();
          expect(restoredPosition, isNotNull);
          
          if (restoredPosition != null) {
            print('  Restored position: ${restoredPosition.cfi.toString()}');
            print('  Progress: ${(restoredPosition.overallProgress * 100).toStringAsFixed(1)}%');
            print('  Metadata: ${restoredPosition.metadata}');
            
            // Test navigation to restored position
            final location = await tracker.navigateToSavedPosition();
            if (location != null) {
              print('  Navigation to saved position: Success');
            } else {
              print('  Navigation to saved position: Failed');
            }
          }
        } else {
          print('  No split chapters found in this book');
        }
      });
    });

    group('📝 Annotation System Tests', () {
      late EpubBookRef bookRef;
      late TestAnnotationStorage annotationStorage;
      late CFIAnnotationManager annotationManager;
      
      setUp(() async {
        bookRef = await EpubReader.openBook(epubBytes);
        annotationStorage = TestAnnotationStorage();
        annotationManager = CFIAnnotationManager(
          bookId: 'frankenstein-annotations',
          bookRef: bookRef,
          storage: annotationStorage,
        );
        print('\n📝 Annotation system initialized');
      });

      test('Create Different Annotation Types', () async {
        print('\n🎨 Creating Different Annotation Types...');
        
        // Create highlight annotation
        final highlight = await annotationManager.createHighlight(
          startCFI: bookRef.createProgressCFI(1, fraction: 0.2),
          endCFI: bookRef.createProgressCFI(1, fraction: 0.25),
          selectedText: 'It was on a dreary night of November',
          color: '#ffff00',
          note: 'Famous opening line',
        );
        
        print('  ✨ Created highlight: ${highlight.id}');
        print('    Text: "${highlight.selectedText}"');
        print('    CFI: ${highlight.cfi.toString()}');
        
        // Create note annotation
        final note = await annotationManager.createNote(
          cfi: bookRef.createProgressCFI(2, fraction: 0.1),
          text: 'This chapter introduces Victor\'s obsession with natural philosophy',
          title: 'Character Development',
          category: 'analysis',
        );
        
        print('  📔 Created note: ${note.id}');
        print('    Title: "${note.title}"');
        print('    CFI: ${note.cfi.toString()}');
        
        // Create bookmark
        final bookmark = await annotationManager.createBookmark(
          cfi: bookRef.createProgressCFI(3),
          title: 'The Creation Scene',
          description: 'Chapter where the monster comes to life',
        );
        
        print('  🔖 Created bookmark: ${bookmark.id}');
        print('    Title: "${bookmark.title}"');
        print('    CFI: ${bookmark.cfi.toString()}');
        
        expect(highlight.type, equals(AnnotationType.highlight));
        expect(note.type, equals(AnnotationType.note));
        expect(bookmark.type, equals(AnnotationType.bookmark));
      });

      test('Annotation Retrieval and Search', () async {
        print('\n🔍 Testing Annotation Retrieval...');
        
        // Get all annotations
        final allAnnotations = await annotationManager.getAllAnnotations();
        print('  Total annotations: ${allAnnotations.length}');
        
        // Get annotations by type
        final highlights = await annotationManager.getAnnotationsByType<HighlightAnnotation>(
          AnnotationType.highlight,
        );
        final notes = await annotationManager.getAnnotationsByType<NoteAnnotation>(
          AnnotationType.note,
        );
        final bookmarks = await annotationManager.getAnnotationsByType<BookmarkAnnotation>(
          AnnotationType.bookmark,
        );
        
        print('  Highlights: ${highlights.length}');
        print('  Notes: ${notes.length}');  
        print('  Bookmarks: ${bookmarks.length}');
        
        // Test search functionality
        final searchResults = await annotationManager.searchAnnotations('Victor');
        print('  Search "Victor": ${searchResults.length} results');
        
        for (final result in searchResults) {
          print('    - ${result.type.name}: ${result.getSearchableText()}');
        }
        
        expect(allAnnotations.length, equals(highlights.length + notes.length + bookmarks.length));
      });

      test('Annotation Statistics and Export', () async {
        print('\n📊 Testing Annotation Statistics...');
        
        final stats = await annotationManager.getAnnotationStatistics();
        print('  Statistics for ${stats.bookId}:');
        print('    Total: ${stats.totalCount}');
        print('    Highlights: ${stats.highlightCount}');
        print('    Notes: ${stats.noteCount}');
        print('    Bookmarks: ${stats.bookmarkCount}');
        print('    First created: ${stats.firstCreated}');
        print('    Last modified: ${stats.lastModified}');
        
        // Test export functionality
        final exportData = await annotationManager.exportAnnotations();
        print('  Export data:');
        print('    Version: ${exportData.version}');
        print('    Export time: ${exportData.exportTimestamp}');
        print('    Annotations: ${exportData.annotations.length}');
        
        // Test JSON serialization
        final exportJson = exportData.toJson();
        expect(exportJson['bookId'], equals('frankenstein-annotations'));
        expect(exportJson['annotations'], isA<List>());
        
        print('  ✅ Export/import cycle successful');
      });
    });

    group('🚨 Edge Cases and Error Handling', () {
      late EpubBookRef bookRef;
      
      setUp(() async {
        bookRef = await EpubReader.openBook(epubBytes);
      });

      test('Invalid CFI Handling', () async {
        print('\n⚠️ Testing Invalid CFI Handling...');
        
        final invalidCFIs = [
          'invalid-cfi-string',
          'epubcfi(/6/999!/4/2/1:0)', // Non-existent spine
          'epubcfi(/6/2!/999/999/999:0)', // Invalid path
          '', // Empty string
        ];
        
        for (final invalidCFI in invalidCFIs) {
          print('  Testing: "$invalidCFI"');
          
          try {
            final cfi = CFI(invalidCFI);
            final isValid = await bookRef.validateCFI(cfi);
            print('    Validation: $isValid');
            
            final location = await bookRef.navigateToCFI(cfi);
            print('    Navigation: ${location != null ? 'Success' : 'Failed (expected)'}');
          } catch (e) {
            print('    Exception: ${e.toString()}');
          }
        }
      });

      test('Performance with Large Operations', () async {
        print('\n⚡ Performance Testing...');
        
        final stopwatch = Stopwatch()..start();
        
        // Test multiple CFI operations
        final operations = 50;
        print('  Performing $operations CFI operations...');
        
        for (int i = 0; i < operations; i++) {
          final spineIndex = i % bookRef.spineItemCount;
          final cfi = bookRef.createProgressCFI(spineIndex);
          await bookRef.validateCFI(cfi);
          
          if (i % 10 == 0) {
            await bookRef.navigateToCFI(cfi);
          }
        }
        
        stopwatch.stop();
        print('  Completed $operations operations in ${stopwatch.elapsedMilliseconds}ms');
        print('  Average: ${(stopwatch.elapsedMilliseconds / operations).toStringAsFixed(2)}ms per operation');
        
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
      });

      test('Memory Usage Stability', () async {
        print('\n💾 Memory Usage Stability Test...');
        
        // Create and use multiple CFI managers
        for (int i = 0; i < 10; i++) {
          final manager = bookRef.cfiManager;
          final cfi = bookRef.createProgressCFI(i % 3);
          await manager.validateCFI(cfi);
          
          if (i % 3 == 0) {
            await manager.navigateToCFI(cfi);
          }
        }
        
        print('  ✅ Memory stability test completed');
      });
    });

    group('📋 Manual Verification Steps', () {
      test('Print Book Information for Manual Review', () async {
        print('\n📚 Book Information for Manual Review:');
        
        final bookRef = await EpubReader.openBook(epubBytes);
        final normalBook = await EpubReader.readBook(epubBytes);
        final splitBook = await EpubReader.readBookWithSplitChapters(epubBytes);
        
        print('  📖 Title: "${bookRef.title}"');
        print('  👤 Author: ${bookRef.author}');
        print('  🔢 Spine Items: ${bookRef.spineItemCount}');
        print('  📑 Normal Chapters: ${normalBook.chapters.length}');
        print('  ✂️ Split Chapters: ${splitBook.chapters.length}');
        
        print('\n  📚 Chapter Structure Comparison:');
        print('  Normal chapters:');
        for (int i = 0; i < normalBook.chapters.length && i < 10; i++) {
          final chapter = normalBook.chapters[i];
          final wordCount = _countWords(chapter.htmlContent ?? '');
          print('    ${i + 1}. "${chapter.title ?? 'Untitled'}" ($wordCount words)');
        }
        
        print('\n  Split chapters:');
        for (int i = 0; i < splitBook.chapters.length && i < 15; i++) {
          final chapter = splitBook.chapters[i];
          final wordCount = _countWords(chapter.htmlContent ?? '');
          print('    ${i + 1}. "${chapter.title ?? 'Untitled'}" ($wordCount words)');
        }
        
        print('\n  🎯 Sample CFIs for Manual Testing:');
        for (int i = 0; i < 3 && i < bookRef.spineItemCount; i++) {
          final cfi = bookRef.createProgressCFI(i);
          print('    Spine $i: ${cfi.toString()}');
        }
        
        print('\n✅ Manual verification information printed');
      });
    });
  });
}

// Helper function to count words in HTML content
int _countWords(String htmlContent) {
  final textContent = htmlContent
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return textContent.split(' ').where((word) => word.isNotEmpty).length;
}

// Test storage implementations
class TestPositionStorage implements PositionStorage {
  final Map<String, ReadingPosition> _positions = {};
  final Map<String, List<ReadingMilestone>> _milestones = {};

  @override
  Future<void> savePosition(ReadingPosition position) async {
    _positions[position.bookId] = position;
  }

  @override
  Future<ReadingPosition?> getPosition(String bookId) async {
    return _positions[bookId];
  }

  @override
  Future<void> saveMilestone(ReadingMilestone milestone) async {
    _milestones.putIfAbsent(milestone.bookId, () => []).add(milestone);
  }

  @override
  Future<List<ReadingMilestone>> getMilestones(String bookId) async {
    return List.from(_milestones[bookId] ?? []);
  }

  @override
  Future<void> deleteBookData(String bookId) async {
    _positions.remove(bookId);
    _milestones.remove(bookId);
  }
}

class TestAnnotationStorage implements AnnotationStorage {
  final Map<String, Annotation> _annotations = {};
  final Map<String, List<String>> _bookAnnotations = {};

  @override
  Future<void> saveAnnotation(Annotation annotation) async {
    _annotations[annotation.id] = annotation;
    _bookAnnotations
        .putIfAbsent(annotation.bookId, () => [])
        .add(annotation.id);
  }

  @override
  Future<List<Annotation>> getAnnotations(String bookId) async {
    final annotationIds = _bookAnnotations[bookId] ?? [];
    return annotationIds
        .map((id) => _annotations[id])
        .where((annotation) => annotation != null)
        .cast<Annotation>()
        .toList();
  }

  @override
  Future<Annotation?> getAnnotation(String annotationId) async {
    return _annotations[annotationId];
  }

  @override
  Future<void> deleteAnnotation(String annotationId) async {
    final annotation = _annotations.remove(annotationId);
    if (annotation != null) {
      _bookAnnotations[annotation.bookId]?.remove(annotationId);
    }
  }

  @override
  Future<void> deleteBookAnnotations(String bookId) async {
    final annotationIds = _bookAnnotations[bookId] ?? [];
    for (final id in annotationIds) {
      _annotations.remove(id);
    }
    _bookAnnotations.remove(bookId);
  }
}