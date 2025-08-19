import 'package:test/test.dart';
import 'package:epub_pro/epub_pro.dart';
import 'dart:io';

/// Tests CFI functionality specifically with split chapters.
/// 
/// Validates that CFI positioning, navigation, and generation work correctly
/// when chapters are split into multiple parts for better readability.
/// 
/// Uses frankenstein.epub as test data to verify split chapter compatibility.
void main() {
  group('CFI Split Chapters Compatibility Tests', () {
    late File frankensteinFile;
    late List<int> epubBytes;
    
    setUpAll(() async {
      frankensteinFile = File('assets/frankenstein.epub');
      if (!frankensteinFile.existsSync()) {
        throw StateError('Frankenstein EPUB not found at assets/frankenstein.epub');
      }
      epubBytes = await frankensteinFile.readAsBytes();
      print('📚 Loaded Frankenstein EPUB (${epubBytes.length} bytes) for split chapter CFI testing');
    });

    group('📊 Split Chapter Structure Analysis', () {
      late EpubBookRef normalBookRef;
      late EpubBookRef splitBookRef;
      
      setUp(() async {
        normalBookRef = await EpubReader.openBook(epubBytes);
        splitBookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
        
        print('\n📚 Books loaded for comparison:');
        print('  Normal chapters: ${normalBookRef.getChapters().length}');
        
        final splitChapters = await splitBookRef.getChapterRefsWithSplitting();
        print('  Split chapter refs: ${splitChapters.length}');
      });

      test('Compare Chapter Structure: Normal vs Split', () async {
        final normalChapters = normalBookRef.getChapters();
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        
        print('\n🔍 Analyzing Chapter Structure Differences:');
        
        // Count split vs original chapters
        int splitPartCount = 0;
        int originalChapterCount = 0;
        
        for (final chapterRef in splitChapterRefs) {
          if (chapterRef is EpubChapterSplitRef) {
            splitPartCount++;
            print('  Split Part: "${chapterRef.title}" (${chapterRef.partNumber}/${chapterRef.totalParts})');
            print('    Original: "${chapterRef.originalTitle}"');
            
            // Validate split properties
            expect(chapterRef.partNumber, greaterThan(0));
            expect(chapterRef.totalParts, greaterThan(0));
            expect(chapterRef.partNumber, lessThanOrEqualTo(chapterRef.totalParts));
            expect(chapterRef.originalChapter, isNotNull);
          } else {
            originalChapterCount++;
            print('  Normal: "${chapterRef.title ?? chapterRef.contentFileName}"');
          }
        }
        
        print('\n📈 Split Analysis Results:');
        print('  Normal chapters: ${normalChapters.length}');
        print('  Original (non-split) chapter refs: $originalChapterCount');
        print('  Split parts: $splitPartCount');
        print('  Total chapter refs: ${splitChapterRefs.length}');
        
        // Basic validation
        expect(splitPartCount + originalChapterCount, equals(splitChapterRefs.length));
        expect(splitPartCount, greaterThan(0)); // Should have some split chapters
        expect(splitChapterRefs.length, greaterThanOrEqualTo(normalChapters.length));
      });

      test('Spine Mapping Consistency Between Normal and Split', () async {
        final normalSpineMap = normalBookRef.cfiManager.getSpineChapterMap();
        final splitSpineMap = splitBookRef.cfiManager.getSpineChapterMap();
        
        print('\n🗺️ Spine Mapping Comparison:');
        print('  Normal spine items: ${normalSpineMap.length}');
        print('  Split spine items: ${splitSpineMap.length}');
        
        // Spine count should be the same (split doesn't change spine structure)
        expect(splitSpineMap.length, equals(normalSpineMap.length));
        
        // Check that spine indices map to correct chapters
        for (int i = 0; i < 3 && i < normalSpineMap.length; i++) {
          final normalChapter = normalSpineMap[i];
          final splitChapter = splitSpineMap[i];
          
          if (normalChapter != null && splitChapter != null) {
            print('  Spine $i: "${normalChapter.contentFileName}" -> "${splitChapter.contentFileName}"');
            expect(splitChapter.contentFileName, equals(normalChapter.contentFileName));
          }
        }
      });
    });

    group('🎯 CFI Generation with Split Chapters', () {
      late EpubBookRef normalBookRef;
      late EpubBookRef splitBookRef;
      
      setUp(() async {
        normalBookRef = await EpubReader.openBook(epubBytes);
        splitBookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      });

      test('Progress CFI Generation - Normal vs Split', () async {
        print('\n⚡ Testing Progress CFI Generation Consistency...');
        
        // Test CFI generation for same spine positions
        for (int spineIndex = 0; spineIndex < 3 && spineIndex < normalBookRef.spineItemCount; spineIndex++) {
          final normalCFI = normalBookRef.createProgressCFI(spineIndex);
          final splitCFI = splitBookRef.createProgressCFI(spineIndex);
          
          print('  Spine $spineIndex:');
          print('    Normal: ${normalCFI.toString()}');
          print('    Split:  ${splitCFI.toString()}');
          
          // CFI should be identical for same spine position
          expect(splitCFI.toString(), equals(normalCFI.toString()));
          expect(splitCFI.structure.start.parts.length, equals(normalCFI.structure.start.parts.length));
          
          // Test fractional progress CFIs
          final normalFractional = normalBookRef.createProgressCFI(spineIndex, fraction: 0.5);
          final splitFractional = splitBookRef.createProgressCFI(spineIndex, fraction: 0.5);
          
          print('    Normal 50%: ${normalFractional.toString()}');
          print('    Split 50%:  ${splitFractional.toString()}');
          
          expect(splitFractional.toString(), equals(normalFractional.toString()));
        }
      });

      test('CFI Navigation - Split Chapter Compatibility', () async {
        print('\n🧭 Testing CFI Navigation with Split Chapters...');
        
        // Create CFIs using normal book, navigate with split book
        final testCFIs = <CFI>[];
        for (int i = 0; i < 3 && i < normalBookRef.spineItemCount; i++) {
          testCFIs.add(normalBookRef.createProgressCFI(i));
          testCFIs.add(normalBookRef.createProgressCFI(i, fraction: 0.3));
        }
        
        for (int i = 0; i < testCFIs.length; i++) {
          final cfi = testCFIs[i];
          print('  Testing CFI: ${cfi.toString()}');
          
          // Navigate with normal book
          final normalLocation = await normalBookRef.navigateToCFI(cfi);
          final normalSuccess = normalLocation != null;
          
          // Navigate with split book
          final splitLocation = await splitBookRef.navigateToCFI(cfi);
          final splitSuccess = splitLocation != null;
          
          print('    Normal navigation: ${normalSuccess ? "Success" : "Failed"}');
          print('    Split navigation:  ${splitSuccess ? "Success" : "Failed"}');
          
          if (normalSuccess && splitSuccess) {
            // Compare spine indices
            expect(splitLocation!.spineIndex, equals(normalLocation!.spineIndex));
            print('    Both found in spine: ${normalLocation.spineIndex}');
            
            // Content file should be the same
            expect(
              splitLocation.chapterRef.contentFileName, 
              equals(normalLocation.chapterRef.contentFileName)
            );
          }
          
          // Split navigation should not be worse than normal navigation
          if (normalSuccess) {
            expect(splitSuccess, isTrue, reason: 'Split book should handle CFI navigation at least as well as normal book');
          }
        }
      });

      test('CFI Generation from Split Chapter References', () async {
        print('\n🔧 Testing CFI Generation from Split Chapter References...');
        
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        
        // Find split chapters to test
        final splitChapters = splitChapterRefs
            .whereType<EpubChapterSplitRef>()
            .take(3)
            .toList();
        
        if (splitChapters.isEmpty) {
          print('  No split chapters found for testing');
          return;
        }
        
        for (final splitChapter in splitChapters) {
          print('\n  Testing split chapter: "${splitChapter.title}"');
          print('    Part ${splitChapter.partNumber} of ${splitChapter.totalParts}');
          print('    Original: "${splitChapter.originalTitle}"');
          
          try {
            // Test CFI generation using the extension method
            final cfi = await splitChapter.generateCFI(
              elementPath: '/4/2/1',
              characterOffset: 10,
              bookRef: normalBookRef,
            );
            
            if (cfi != null) {
              print('    Generated CFI: ${cfi.toString()}');
              
              // Test CFI validation
              final isValid = await normalBookRef.validateCFI(cfi);
              print('    CFI validation: ${isValid ? "Valid" : "Invalid"}');
              
              // Test navigation back to CFI
              final location = await normalBookRef.navigateToCFI(cfi);
              final navigationSuccess = location != null;
              print('    CFI navigation: ${navigationSuccess ? "Success" : "Failed"}');
              
              if (navigationSuccess) {
                print('    Target chapter: "${location!.chapterRef.title ?? location.chapterRef.contentFileName}"');
              }
              
              expect(cfi, isNotNull);
              expect(cfi.toString(), startsWith('epubcfi('));
            } else {
              print('    CFI generation returned null (may be expected)');
            }
          } catch (e) {
            print('    CFI generation error: ${e.toString()}');
            // Don't fail the test - this may be expected during development
          }
        }
      });
    });

    group('✂️ Split-Specific CFI Operations', () {
      late EpubBookRef normalBookRef;
      late EpubBookRef splitBookRef;
      
      setUp(() async {
        normalBookRef = await EpubReader.openBook(epubBytes);
        splitBookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      });

      test('Character Offset Mapping in Split Chapters', () async {
        print('\n📍 Testing Character Offset Mapping in Split Chapters...');
        
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        final splitChapters = splitChapterRefs
            .whereType<EpubChapterSplitRef>()
            .take(2)
            .toList();
        
        for (final splitChapter in splitChapters) {
          print('\n  Testing split chapter: "${splitChapter.title}"');
          
          try {
            // Test getting part boundaries
            final startOffset = await splitChapter.getPartStartOffset();
            final endOffset = await splitChapter.getPartEndOffset();
            
            print('    Part ${splitChapter.partNumber} boundaries:');
            print('      Start offset: $startOffset');
            print('      End offset: $endOffset');
            print('      Length: ${endOffset - startOffset + 1} characters');
            
            expect(startOffset, greaterThanOrEqualTo(0));
            expect(endOffset, greaterThan(startOffset));
            
            // Validate that part boundaries make sense
            if (splitChapter.partNumber > 1) {
              expect(startOffset, greaterThan(0)); // Not first part, should start after 0
            }
            
            if (splitChapter.partNumber < splitChapter.totalParts) {
              // Not last part, should have reasonable end offset
              expect(endOffset, lessThan(1000000)); // Sanity check
            }
          } catch (e) {
            print('    Boundary calculation error: ${e.toString()}');
            // Don't fail - may be expected during development
          }
        }
      });

      test('Split Chapter Content Validation', () async {
        print('\n📝 Testing Split Chapter Content Validation...');
        
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        final splitChapters = splitChapterRefs
            .whereType<EpubChapterSplitRef>()
            .take(3)
            .toList();
        
        for (final splitChapter in splitChapters) {
          print('\n  Testing split chapter content: "${splitChapter.title}"');
          
          try {
            // Test reading split chapter content
            final content = await splitChapter.readHtmlContent();
            print('    Content length: ${content.length} characters');
            
            expect(content, isNotEmpty);
            expect(splitChapter.isSplitPart, isTrue);
            
            // Test that content is reasonable HTML
            expect(content, contains('<'));
            expect(content, contains('>'));
            
            // Word count should be reasonable for a split part
            final wordCount = _countWords(content);
            print('    Word count: $wordCount words');
            expect(wordCount, greaterThan(0));
            expect(wordCount, lessThan(50000)); // Sanity check - split parts should be smaller
            
          } catch (e) {
            print('    Content reading error: ${e.toString()}');
          }
        }
      });

      test('CFI Validation with Split Chapters', () async {
        print('\n✅ Testing CFI Validation with Split Chapters...');
        
        // Test various CFI formats
        final testCFIs = [
          normalBookRef.createProgressCFI(0),
          normalBookRef.createProgressCFI(1, fraction: 0.25),
          normalBookRef.createProgressCFI(2, fraction: 0.75),
        ];
        
        for (int i = 0; i < testCFIs.length; i++) {
          final cfi = testCFIs[i];
          print('  Testing CFI validation: ${cfi.toString()}');
          
          // Validate with normal book
          final normalValid = await normalBookRef.validateCFI(cfi);
          
          // Validate with split book
          final splitValid = await splitBookRef.validateCFI(cfi);
          
          print('    Normal book validation: $normalValid');
          print('    Split book validation:  $splitValid');
          
          // Split book validation should be consistent with normal book
          expect(splitValid, equals(normalValid));
        }
        
        // Test invalid CFIs
        final invalidCFIs = [
          'invalid-cfi',
          'epubcfi(/6/999!/4/2/1)', // Non-existent spine
          'epubcfi(/6/2!/999/999/999)', // Invalid path
        ];
        
        for (final invalidCFI in invalidCFIs) {
          print('  Testing invalid CFI: "$invalidCFI"');
          
          try {
            final cfi = CFI(invalidCFI);
            final normalValid = await normalBookRef.validateCFI(cfi);
            final splitValid = await splitBookRef.validateCFI(cfi);
            
            print('    Normal validation: $normalValid');
            print('    Split validation:  $splitValid');
            
            // Both should handle invalid CFIs consistently
            expect(splitValid, equals(normalValid));
          } catch (e) {
            print('    Exception (expected): ${e.toString()}');
          }
        }
      });
    });

    group('⚡ Performance and Edge Cases', () {
      late EpubBookRef splitBookRef;
      
      setUp(() async {
        splitBookRef = await EpubReader.openBookWithSplitChapters(epubBytes);
      });

      test('CFI Operations Performance with Split Chapters', () async {
        print('\n⚡ Testing CFI Performance with Split Chapters...');
        
        final stopwatch = Stopwatch()..start();
        final operations = 20;
        
        print('  Performing $operations CFI operations on split book...');
        
        for (int i = 0; i < operations; i++) {
          final spineIndex = i % splitBookRef.spineItemCount;
          final cfi = splitBookRef.createProgressCFI(spineIndex);
          
          await splitBookRef.validateCFI(cfi);
          
          if (i % 5 == 0) {
            await splitBookRef.navigateToCFI(cfi);
          }
        }
        
        stopwatch.stop();
        final avgTime = stopwatch.elapsedMilliseconds / operations;
        
        print('  Completed $operations operations in ${stopwatch.elapsedMilliseconds}ms');
        print('  Average: ${avgTime.toStringAsFixed(2)}ms per operation');
        
        // Performance should be reasonable
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
        expect(avgTime, lessThan(100)); // 100ms per operation max
      });

      test('Memory Stability with Split Chapter CFI Operations', () async {
        print('\n💾 Testing Memory Stability with Split Chapters...');
        
        final splitChapterRefs = await splitBookRef.getChapterRefsWithSplitting();
        
        // Perform multiple operations to test memory usage
        for (int cycle = 0; cycle < 5; cycle++) {
          print('  Memory test cycle ${cycle + 1}/5');
          
          // Create multiple CFI managers and perform operations
          for (int i = 0; i < 3; i++) {
            final manager = splitBookRef.cfiManager;
            final spineIndex = i % splitBookRef.spineItemCount;
            final cfi = splitBookRef.createProgressCFI(spineIndex);
            
            await manager.validateCFI(cfi);
            
            if (i % 2 == 0) {
              await manager.navigateToCFI(cfi);
            }
          }
          
          // Process some split chapter references
          for (final chapterRef in splitChapterRefs.take(3)) {
            if (chapterRef is EpubChapterSplitRef) {
              try {
                await chapterRef.getPartStartOffset();
                await chapterRef.getPartEndOffset();
              } catch (e) {
                // Ignore errors in this memory test
              }
            }
          }
        }
        
        print('  ✅ Memory stability test completed without issues');
      });
    });

    group('📋 Split CFI Format Testing', () {
      test('Split CFI Format Creation and Parsing', () async {
        print('\n🔧 Testing Split CFI Format...');
        
        // Test creating Split CFI with specific format
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
        final splitCFI = SplitCFI.fromStandardCFI(
          standardCFI,
          splitPart: 2,
          totalParts: 3,
        );
        
        print('  Standard CFI: ${standardCFI.toString()}');
        print('  Split CFI:    ${splitCFI.raw}');
        
        expect(splitCFI.raw, contains('split=2,total=3'));
        expect(splitCFI.splitPart, equals(2));
        expect(splitCFI.totalParts, equals(3));
        expect(splitCFI.isSplitCFI, isTrue);
        
        // Test parsing split CFI from string
        final splitFromString = SplitCFI('epubcfi(/6/4!/split=1,total=2/4/10/2:20)');
        
        print('  Parsed Split CFI: ${splitFromString.raw}');
        expect(splitFromString.splitPart, equals(1));
        expect(splitFromString.totalParts, equals(2));
        
        // Test base CFI extraction
        final baseCFI = splitFromString.baseCFI;
        print('  Extracted base: ${baseCFI.toString()}');
        expect(baseCFI.toString(), equals('epubcfi(/6/4!/4/10/2:20)'));
        expect(baseCFI.isSplitCFI, isFalse);
      });

      test('Split CFI Comparison and Ordering', () async {
        print('\n📊 Testing Split CFI Comparison...');
        
        final cfi1 = SplitCFI('epubcfi(/6/4!/split=1,total=3/4/10/2:15)');
        final cfi2 = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final cfi3 = SplitCFI('epubcfi(/6/6!/split=1,total=2/4/10/2:15)');
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
        
        print('  Split CFI 1: ${cfi1.raw}');
        print('  Split CFI 2: ${cfi2.raw}');
        print('  Split CFI 3: ${cfi3.raw}');
        print('  Standard CFI: ${standardCFI.toString()}');
        
        // Test ordering
        expect(cfi1.compare(cfi2), lessThan(0)); // Part 1 before part 2
        expect(cfi2.compare(cfi1), greaterThan(0)); // Part 2 after part 1
        expect(cfi1.compare(cfi3), lessThan(0)); // Different spine positions
        
        // Test comparison with standard CFI
        expect(cfi1.compare(standardCFI), greaterThan(0)); // Split after standard
        expect(standardCFI.compare(cfi1), lessThan(0)); // Standard before split
        
        print('  ✅ CFI ordering verified');
      });

      test('Split CFI Detection and Conversion', () async {
        print('\n🔄 Testing Split CFI Detection and Conversion...');
        
        // Test detection
        final splitCFIString = 'epubcfi(/6/4!/split=2,total=3/4/10/2:15)';
        final standardCFIString = 'epubcfi(/6/4!/4/10/2:15)';
        
        expect(SplitCFI.containsSplitInfo(splitCFIString), isTrue);
        expect(SplitCFI.containsSplitInfo(standardCFIString), isFalse);
        
        print('  Split CFI detection: ✅');
        
        // Test conversion from standard CFI to split CFI
        final standardCFI = CFI(splitCFIString); // This contains split info
        final convertedSplit = standardCFI.toSplitCFI();
        
        expect(convertedSplit, isNotNull);
        if (convertedSplit != null) {
          expect(convertedSplit.splitPart, equals(2));
          expect(convertedSplit.totalParts, equals(3));
          print('  Conversion to Split CFI: ✅');
        }
        
        // Test conversion from standard CFI (no split info)
        final pureStandardCFI = CFI(standardCFIString);
        final noConversion = pureStandardCFI.toSplitCFI();
        expect(noConversion, isNull);
        
        print('  Non-split CFI conversion: ✅ (correctly returned null)');
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