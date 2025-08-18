import 'package:test/test.dart';
import 'package:epub_pro/src/cfi/core/cfi.dart';
import 'package:epub_pro/src/cfi/core/cfi_comparator.dart';
import 'package:epub_pro/src/cfi/core/cfi_range.dart';

void main() {
  group('CFI Basic Functionality', () {
    test('CFI parsing - simple point CFI', () {
      final cfi = CFI('epubcfi(/6/4!/4/10/2:3)');
      
      expect(cfi.isPoint, isTrue);
      expect(cfi.isRange, isFalse);
      expect(cfi.toString(), equals('epubcfi(/6/4!/4/10/2:3)'));
    });

    test('CFI parsing - range CFI', () {
      final cfi = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
      
      expect(cfi.isRange, isTrue);
      expect(cfi.isPoint, isFalse);
    });

    test('CFI comparison - reading order', () {
      final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)');
      final cfi2 = CFI('epubcfi(/6/4!/4/10/2:5)');
      final cfi3 = CFI('epubcfi(/6/6!/4/10/2:1)');
      
      expect(cfi1.compare(cfi2), lessThan(0)); // cfi1 comes before cfi2
      expect(cfi2.compare(cfi1), greaterThan(0)); // cfi2 comes after cfi1
      expect(cfi1.compare(cfi1), equals(0)); // same CFI
      expect(cfi1.compare(cfi3), lessThan(0)); // different spine items
    });

    test('CFI collapse - range to point', () {
      final rangeCfi = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
      
      final startCfi = rangeCfi.collapse();
      final endCfi = rangeCfi.collapse(toEnd: true);
      
      expect(startCfi.isPoint, isTrue);
      expect(endCfi.isPoint, isTrue);
      expect(startCfi.compare(endCfi), lessThan(0));
    });

    test('CFI structure equality', () {
      final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)');
      final cfi2 = CFI('epubcfi(/6/4!/4/10/2:3)');
      final cfi3 = CFI('epubcfi(/6/4!/4/10/2:5)');
      
      expect(cfi1, equals(cfi2));
      expect(cfi1, isNot(equals(cfi3)));
    });
  });

  group('CFI Comparator Utilities', () {
    test('Sort CFIs by reading order', () {
      final cfis = [
        CFI('epubcfi(/6/6!/4/10/2:1)'),
        CFI('epubcfi(/6/4!/4/10/2:5)'),
        CFI('epubcfi(/6/4!/4/10/2:3)'),
        CFI('epubcfi(/6/2!/4/10/2:1)'),
      ];
      
      final sorted = CFIComparator.sortByReadingOrder(cfis);
      
      expect(sorted[0].toString(), contains('/6/2!'));
      expect(sorted[1].toString(), contains('/6/4!/4/10/2:3'));
      expect(sorted[2].toString(), contains('/6/4!/4/10/2:5'));
      expect(sorted[3].toString(), contains('/6/6!'));
    });

    test('Find earliest and latest CFIs', () {
      final cfis = [
        CFI('epubcfi(/6/6!/4/10/2:1)'),
        CFI('epubcfi(/6/4!/4/10/2:5)'),
        CFI('epubcfi(/6/2!/4/10/2:1)'),
      ];
      
      final earliest = CFIComparator.findEarliest(cfis);
      final latest = CFIComparator.findLatest(cfis);
      
      expect(earliest?.toString(), contains('/6/2!'));
      expect(latest?.toString(), contains('/6/6!'));
    });

    test('Extract spine index', () {
      final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)'); // Spine index 1 (4/2 - 1)
      final cfi2 = CFI('epubcfi(/6/6!/4/10/2:3)'); // Spine index 2 (6/2 - 1)
      
      final spine1 = CFIComparator.extractSpineIndex(cfi1);
      final spine2 = CFIComparator.extractSpineIndex(cfi2);
      
      expect(spine1, equals(1));
      expect(spine2, equals(2));
    });

    test('Group CFIs by spine', () {
      final cfis = [
        CFI('epubcfi(/6/4!/4/10/2:1)'), // Spine 1
        CFI('epubcfi(/6/6!/4/10/2:5)'), // Spine 2
        CFI('epubcfi(/6/4!/4/10/2:8)'), // Spine 1
      ];
      
      final grouped = CFIComparator.groupBySpine(cfis);
      
      expect(grouped[1]?.length, equals(2));
      expect(grouped[2]?.length, equals(1));
      
      // Check that spine 1 CFIs are sorted
      final spine1CFIs = grouped[1]!;
      expect(spine1CFIs[0].toString(), contains('2:1'));
      expect(spine1CFIs[1].toString(), contains('2:8'));
    });
  });

  group('CFI Range Operations', () {
    test('Create range from start and end CFIs', () {
      final startCfi = CFI('epubcfi(/6/4!/4/10/2:5)');
      final endCfi = CFI('epubcfi(/6/4!/4/10/2:15)');
      
      final rangeCfi = CFIRange.fromStartEnd(startCfi, endCfi);
      
      expect(rangeCfi.isRange, isTrue);
      expect(rangeCfi.toString(), contains(','));
    });

    test('Create range from text offsets', () {
      final baseCfi = CFI('epubcfi(/6/4!/4/10/2)');
      
      final rangeCfi = CFIRange.fromTextOffsets(baseCfi, 5, 15);
      
      expect(rangeCfi.isRange, isTrue);
      
      final length = CFIRange.getLength(rangeCfi);
      expect(length, equals(10)); // 15 - 5 = 10
    });

    test('Expand point CFI to range', () {
      final pointCfi = CFI('epubcfi(/6/4!/4/10/2:10)');
      
      final rangeCfi = CFIRange.expandAround(pointCfi, before: 3, after: 5);
      
      expect(rangeCfi.isRange, isTrue);
      
      final startCfi = rangeCfi.collapse();
      final endCfi = rangeCfi.collapse(toEnd: true);
      
      // Should expand from position 7 to position 15
      expect(startCfi.toString(), contains(':7'));
      expect(endCfi.toString(), contains(':15'));
    });

    test('Check if range contains point', () {
      final rangeCfi = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
      final pointInside = CFI('epubcfi(/6/4!/4/10/2:8)');
      final pointOutside = CFI('epubcfi(/6/4!/4/10/2:20)');
      
      expect(CFIRange.contains(rangeCfi, pointInside), isTrue);
      expect(CFIRange.contains(rangeCfi, pointOutside), isFalse);
    });

    test('Merge overlapping ranges', () {
      final ranges = [
        CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)'),
        CFI('epubcfi(/6/4!/4/10,/2:8,/2:15)'),  // Overlaps with first
        CFI('epubcfi(/6/4!/4/10,/2:20,/2:25)'), // Separate
      ];
      
      final merged = CFIRange.mergeRanges(ranges);
      
      expect(merged.length, equals(2)); // Should merge first two
      
      // First merged range should span from 5 to 15
      final firstRange = merged[0];
      final startCfi = firstRange.collapse();
      final endCfi = firstRange.collapse(toEnd: true);
      
      expect(startCfi.toString(), contains(':5'));
      expect(endCfi.toString(), contains(':15'));
    });
  });

  group('Error Handling', () {
    test('Invalid CFI format throws exception', () {
      expect(() => CFI('invalid-cfi'), throwsFormatException);
      expect(() => CFI('epubcfi(malformed'), throwsFormatException);
      expect(() => CFI('epubcfi()'), throwsFormatException);
    });

    test('Invalid range operations throw exceptions', () {
      final rangeCfi = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
      final pointCfi = CFI('epubcfi(/6/4!/4/10/2:8)');
      
      // Can't create range from range CFIs
      expect(() => CFIRange.fromStartEnd(rangeCfi, pointCfi), throwsArgumentError);
      
      // Can't create text offsets with invalid range
      expect(() => CFIRange.fromTextOffsets(pointCfi, 15, 5), throwsArgumentError);
    });
  });
}