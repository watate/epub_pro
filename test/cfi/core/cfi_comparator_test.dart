import 'package:test/test.dart';
import 'package:epub_pro/src/cfi/core/cfi.dart';
import 'package:epub_pro/src/cfi/core/cfi_comparator.dart';

void main() {
  group('CFI Comparator Tests', () {
    group('Basic CFI Sorting', () {
      test('Sort CFIs by reading order - simple cases', () {
        final cfis = [
          CFI('epubcfi(/6/6!/4/10/2:1)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/4!/4/10/2:3)'),
          CFI('epubcfi(/6/2!/4/10/2:1)'),
        ];

        final sorted = CFIComparator.sortByReadingOrder(cfis);

        expect(sorted.length, equals(4));
        expect(sorted[0].toString(), equals('epubcfi(/6/2!/4/10/2:1)'));
        expect(sorted[1].toString(), equals('epubcfi(/6/4!/4/10/2:3)'));
        expect(sorted[2].toString(), equals('epubcfi(/6/4!/4/10/2:5)'));
        expect(sorted[3].toString(), equals('epubcfi(/6/6!/4/10/2:1)'));
      });

      test('Sort CFIs with different spine positions', () {
        final cfis = [
          CFI('epubcfi(/6/8!/4/10/2:1)'), // Spine 3
          CFI('epubcfi(/6/2!/4/10/2:1)'), // Spine 0
          CFI('epubcfi(/6/6!/4/10/2:1)'), // Spine 2
          CFI('epubcfi(/6/4!/4/10/2:1)'), // Spine 1
        ];

        final sorted = CFIComparator.sortByReadingOrder(cfis);

        expect(sorted[0].toString(), contains('/6/2!'));
        expect(sorted[1].toString(), contains('/6/4!'));
        expect(sorted[2].toString(), contains('/6/6!'));
        expect(sorted[3].toString(), contains('/6/8!'));
      });

      test('Sort CFIs with same spine but different positions', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/20/2:1)'),
          CFI('epubcfi(/6/4!/4/10/2:1)'),
          CFI('epubcfi(/6/4!/4/10/4:1)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
        ];

        final sorted = CFIComparator.sortByReadingOrder(cfis);

        expect(sorted[0].toString(), equals('epubcfi(/6/4!/4/10/2:1)'));
        expect(sorted[1].toString(), equals('epubcfi(/6/4!/4/10/2:5)'));
        expect(sorted[2].toString(), equals('epubcfi(/6/4!/4/10/4:1)'));
        expect(sorted[3].toString(), equals('epubcfi(/6/4!/4/20/2:1)'));
      });

      test('Sort range CFIs', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10,/2:10,/2:20)'),
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)'),
          CFI('epubcfi(/6/2!/4/10,/2:1,/2:10)'),
        ];

        final sorted = CFIComparator.sortByReadingOrder(cfis);

        expect(sorted[0].toString(), contains('/6/2!'));
        expect(sorted[1].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:15)'));
        expect(sorted[2].toString(), equals('epubcfi(/6/4!/4/10,/2:10,/2:20)'));
      });

      test('Sort empty list', () {
        final cfis = <CFI>[];
        final sorted = CFIComparator.sortByReadingOrder(cfis);

        expect(sorted, isEmpty);
      });

      test('Sort single CFI', () {
        final cfis = [CFI('epubcfi(/6/4!/4/10/2:1)')];
        final sorted = CFIComparator.sortByReadingOrder(cfis);

        expect(sorted.length, equals(1));
        expect(sorted[0].toString(), equals('epubcfi(/6/4!/4/10/2:1)'));
      });
    });

    group('Finding Earliest and Latest CFIs', () {
      test('Find earliest CFI', () {
        final cfis = [
          CFI('epubcfi(/6/6!/4/10/2:1)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/2!/4/10/2:1)'),
        ];

        final earliest = CFIComparator.findEarliest(cfis);

        expect(earliest, isNotNull);
        expect(earliest!.toString(), equals('epubcfi(/6/2!/4/10/2:1)'));
      });

      test('Find latest CFI', () {
        final cfis = [
          CFI('epubcfi(/6/6!/4/10/2:1)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/2!/4/10/2:1)'),
        ];

        final latest = CFIComparator.findLatest(cfis);

        expect(latest, isNotNull);
        expect(latest!.toString(), equals('epubcfi(/6/6!/4/10/2:1)'));
      });

      test('Find earliest and latest with same CFI', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
        ];

        final earliest = CFIComparator.findEarliest(cfis);
        final latest = CFIComparator.findLatest(cfis);

        expect(earliest, isNotNull);
        expect(latest, isNotNull);
        expect(earliest!.toString(), equals(latest!.toString()));
      });

      test('Find earliest and latest with empty list', () {
        final cfis = <CFI>[];

        final earliest = CFIComparator.findEarliest(cfis);
        final latest = CFIComparator.findLatest(cfis);

        expect(earliest, isNull);
        expect(latest, isNull);
      });

      test('Find earliest and latest with range CFIs', () {
        final cfis = [
          CFI('epubcfi(/6/6!/4/10,/2:5,/2:15)'),
          CFI('epubcfi(/6/4!/4/10,/2:1,/2:10)'),
          CFI('epubcfi(/6/8!/4/10,/2:3,/2:20)'),
        ];

        final earliest = CFIComparator.findEarliest(cfis);
        final latest = CFIComparator.findLatest(cfis);

        expect(earliest, isNotNull);
        expect(latest, isNotNull);
        expect(earliest!.toString(), contains('/6/4!'));
        expect(latest!.toString(), contains('/6/8!'));
      });
    });

    group('Spine Index Extraction', () {
      test('Extract spine index from simple CFIs', () {
        final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)'); // Spine index 1
        final cfi2 = CFI('epubcfi(/6/6!/4/10/2:3)'); // Spine index 2
        final cfi3 = CFI('epubcfi(/6/2!/4/10/2:3)'); // Spine index 0

        expect(CFIComparator.extractSpineIndex(cfi1), equals(1));
        expect(CFIComparator.extractSpineIndex(cfi2), equals(2));
        expect(CFIComparator.extractSpineIndex(cfi3), equals(0));
      });

      test('Extract spine index from range CFIs', () {
        final cfi1 = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)'); // Spine index 1
        final cfi2 = CFI('epubcfi(/6/8!/4/10,/2:5,/2:15)'); // Spine index 3

        expect(CFIComparator.extractSpineIndex(cfi1), equals(1));
        expect(CFIComparator.extractSpineIndex(cfi2), equals(3));
      });

      test('Extract spine index from complex CFIs', () {
        final cfi1 =
            CFI('epubcfi(/6/4[chapter1]!/4/10[para]/2:3)'); // Spine index 1
        final cfi2 =
            CFI('epubcfi(/6/10[chapter2]!/4/10[para]/2:3)'); // Spine index 4

        expect(CFIComparator.extractSpineIndex(cfi1), equals(1));
        expect(CFIComparator.extractSpineIndex(cfi2), equals(4));
      });

      test('Extract spine index handles edge cases', () {
        final cfi1 = CFI(
            'epubcfi(/6/0!/4/10/2:3)'); // Invalid spine item, falls back to first part
        final cfi2 = CFI('epubcfi(/6/100!/4/10/2:3)'); // Spine index 49

        expect(CFIComparator.extractSpineIndex(cfi1),
            equals(2)); // Falls back to first part: (6/2)-1 = 2
        expect(CFIComparator.extractSpineIndex(cfi2), equals(49));
      });
    });

    group('Grouping CFIs by Spine', () {
      test('Group CFIs by spine index', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10/2:1)'), // Spine 1
          CFI('epubcfi(/6/6!/4/10/2:5)'), // Spine 2
          CFI('epubcfi(/6/4!/4/10/2:8)'), // Spine 1
          CFI('epubcfi(/6/2!/4/10/2:3)'), // Spine 0
          CFI('epubcfi(/6/6!/4/10/2:1)'), // Spine 2
        ];

        final grouped = CFIComparator.groupBySpine(cfis);

        expect(grouped.containsKey(0), isTrue);
        expect(grouped.containsKey(1), isTrue);
        expect(grouped.containsKey(2), isTrue);
        expect(grouped.containsKey(3), isFalse);

        expect(grouped[0]!.length, equals(1));
        expect(grouped[1]!.length, equals(2));
        expect(grouped[2]!.length, equals(2));

        // Check that CFIs within each spine are sorted
        final spine1CFIs = grouped[1]!;
        expect(spine1CFIs[0].toString(), contains('2:1'));
        expect(spine1CFIs[1].toString(), contains('2:8'));

        final spine2CFIs = grouped[2]!;
        expect(spine2CFIs[0].toString(), contains('2:1'));
        expect(spine2CFIs[1].toString(), contains('2:5'));
      });

      test('Group CFIs with range CFIs', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10,/2:1,/2:10)'), // Spine 1
          CFI('epubcfi(/6/6!/4/10/2:5)'), // Spine 2 (point)
          CFI('epubcfi(/6/4!/4/10/2:8)'), // Spine 1 (point)
        ];

        final grouped = CFIComparator.groupBySpine(cfis);

        expect(grouped[1]!.length, equals(2));
        expect(grouped[2]!.length, equals(1));
      });

      test('Group empty CFI list', () {
        final cfis = <CFI>[];
        final grouped = CFIComparator.groupBySpine(cfis);

        expect(grouped, isEmpty);
      });

      test('Group CFIs with invalid spine indices', () {
        final cfis = [
          CFI('epubcfi(/6/0!/4/10/2:1)'), // Invalid spine (index 0), falls back to spine 2
          CFI('epubcfi(/6/4!/4/10/2:1)'), // Valid spine 1
        ];

        final grouped = CFIComparator.groupBySpine(cfis);

        // Both CFIs are grouped based on extracted spine indices
        expect(grouped.containsKey(1), isTrue);
        expect(grouped.containsKey(2), isTrue);
        expect(grouped[1]!.length, equals(1));
        expect(grouped[2]!.length, equals(1));
        expect(
            grouped.length, equals(2)); // Two groups due to fallback behavior
      });
    });

    group('Filtering CFIs in Range', () {
      test('Filter CFIs in range', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10/2:1)'), // Before range
          CFI('epubcfi(/6/4!/4/10/2:5)'), // In range
          CFI('epubcfi(/6/4!/4/10/2:8)'), // In range
          CFI('epubcfi(/6/4!/4/10/2:15)'), // After range
        ];

        final start = CFI('epubcfi(/6/4!/4/10/2:3)');
        final end = CFI('epubcfi(/6/4!/4/10/2:12)');

        final filtered = CFIComparator.filterInRange(cfis, start, end);

        expect(filtered.length, equals(2));
        expect(filtered.any((cfi) => cfi.toString().contains('2:5')), isTrue);
        expect(filtered.any((cfi) => cfi.toString().contains('2:8')), isTrue);
      });

      test('Filter CFIs - edge cases at boundaries', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10/2:5)'), // At start boundary
          CFI('epubcfi(/6/4!/4/10/2:8)'), // In middle
          CFI('epubcfi(/6/4!/4/10/2:12)'), // At end boundary
        ];

        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/4!/4/10/2:12)');

        final filtered = CFIComparator.filterInRange(cfis, start, end);

        expect(filtered.length, equals(3)); // All should be included
      });

      test('Filter empty list', () {
        final cfis = <CFI>[];
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/4!/4/10/2:12)');

        final filtered = CFIComparator.filterInRange(cfis, start, end);

        expect(filtered, isEmpty);
      });
    });

    group('CFI Range Operations', () {
      test('Check if CFI is in range using isInRange', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/4!/4/10/2:15)');
        final pointInside = CFI('epubcfi(/6/4!/4/10/2:8)');
        final pointBefore = CFI('epubcfi(/6/4!/4/10/2:3)');
        final pointAfter = CFI('epubcfi(/6/4!/4/10/2:20)');
        final pointDifferentSpine = CFI('epubcfi(/6/6!/4/10/2:8)');

        expect(CFIComparator.isInRange(pointInside, start, end), isTrue);
        expect(CFIComparator.isInRange(pointBefore, start, end), isFalse);
        expect(CFIComparator.isInRange(pointAfter, start, end), isFalse);
        expect(
            CFIComparator.isInRange(pointDifferentSpine, start, end), isFalse);
      });

      test('Check if CFI is in range - edge cases', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/4!/4/10/2:15)');
        final pointAtStart = CFI('epubcfi(/6/4!/4/10/2:5)');
        final pointAtEnd = CFI('epubcfi(/6/4!/4/10/2:15)');

        expect(CFIComparator.isInRange(pointAtStart, start, end), isTrue);
        expect(CFIComparator.isInRange(pointAtEnd, start, end), isTrue);
      });

      test('Distance calculation between CFIs', () {
        final cfi1 = CFI('epubcfi(/6/4!/4/10/2:5)');
        final cfi2 =
            CFI('epubcfi(/6/4!/4/10/2:10)'); // Same spine, different offset
        final cfi3 = CFI('epubcfi(/6/6!/4/10/2:5)'); // Different spine

        final sameSpineDistance = CFIComparator.calculateDistance(cfi1, cfi2);
        final differentSpineDistance =
            CFIComparator.calculateDistance(cfi1, cfi3);

        expect(
            sameSpineDistance, lessThan(100)); // Small distance for same spine
        expect(differentSpineDistance,
            greaterThan(1000)); // Large distance for different spine
        expect(sameSpineDistance, equals(5.0)); // Exact offset difference
      });

      test('Find closest CFI', () {
        final target = CFI('epubcfi(/6/4!/4/10/2:10)');
        final candidates = [
          CFI('epubcfi(/6/4!/4/10/2:5)'), // Distance: 5
          CFI('epubcfi(/6/4!/4/10/2:15)'), // Distance: 5
          CFI('epubcfi(/6/4!/4/10/2:8)'), // Distance: 2
          CFI('epubcfi(/6/6!/4/10/2:10)'), // Distance: >10000 (different spine)
        ];

        final closest = CFIComparator.findClosest(target, candidates);

        expect(closest, isNotNull);
        expect(closest!.toString(), contains('2:8'));
      });
    });

    group('Performance Tests', () {
      test('Sort large number of CFIs', () {
        const count = 1000;
        final cfis = <CFI>[];

        // Generate CFIs in reverse order
        for (int i = count - 1; i >= 0; i--) {
          final spineIndex = (i % 10) * 2 +
              2; // Spine indices 2, 4, 6, 8, 10, 12, 14, 16, 18, 20
          final offset = i;
          cfis.add(CFI('epubcfi(/6/$spineIndex!/4/10/2:$offset)'));
        }

        final stopwatch = Stopwatch()..start();
        final sorted = CFIComparator.sortByReadingOrder(cfis);
        stopwatch.stop();

        expect(sorted.length, equals(count));

        // Check that they're sorted correctly
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].compare(sorted[i + 1]), lessThanOrEqualTo(0));
        }

        print('Sorted $count CFIs in ${stopwatch.elapsedMicroseconds} μs');
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
      });

      test('Group large number of CFIs by spine', () {
        const count = 1000;
        final cfis = <CFI>[];

        for (int i = 0; i < count; i++) {
          final spineIndex = (i % 20) * 2 + 2; // 20 different spines
          cfis.add(CFI('epubcfi(/6/$spineIndex!/4/10/2:$i)'));
        }

        final stopwatch = Stopwatch()..start();
        final grouped = CFIComparator.groupBySpine(cfis);
        stopwatch.stop();

        expect(grouped.length, equals(20));

        // Check that all CFIs are accounted for
        int totalCfis = 0;
        for (final spine in grouped.values) {
          totalCfis += spine.length;
        }
        expect(totalCfis, equals(count));

        print(
            'Grouped $count CFIs by spine in ${stopwatch.elapsedMicroseconds} μs');
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be fast
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Handle CFIs with unusual indices', () {
        final cfis = [
          CFI('epubcfi(/6/1!/4/10/2:1)'), // Odd spine index
          CFI('epubcfi(/6/999999!/4/10/2:1)'), // Very large spine index
          CFI('epubcfi(/6/0!/4/10/2:1)'), // Zero spine index (invalid)
        ];

        final sorted = CFIComparator.sortByReadingOrder(cfis);
        expect(sorted.length, equals(3));

        final indices = sorted
            .map((cfi) => CFIComparator.extractSpineIndex(cfi) ?? -1)
            .toList();
        expect(indices[0], lessThanOrEqualTo(indices[1]));
        expect(indices[1], lessThanOrEqualTo(indices[2]));
      });

      test('Handle mixed point and range CFIs', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10/2:1)'), // Point
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)'), // Range
          CFI('epubcfi(/6/4!/4/10/2:8)'), // Point
        ];

        final sorted = CFIComparator.sortByReadingOrder(cfis);
        expect(sorted.length, equals(3));

        // All should be sorted by their effective start positions
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].compare(sorted[i + 1]), lessThanOrEqualTo(0));
        }
      });

      test('Handle identical CFIs', () {
        final cfis = [
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
        ];

        final sorted = CFIComparator.sortByReadingOrder(cfis);
        expect(sorted.length, equals(3));

        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].compare(sorted[i + 1]), equals(0));
        }

        final grouped = CFIComparator.groupBySpine(cfis);
        expect(grouped[1]!.length, equals(3));
      });

      test('Stability of sort operations', () {
        // Create CFIs that are equal in terms of reading order but different objects
        final cfis = [
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
          CFI('epubcfi(/6/4!/4/10/2:5)'),
        ];

        // Add unique markers to track original order
        final originalOrder = <String>[];
        for (int i = 0; i < cfis.length; i++) {
          originalOrder.add('${cfis[i].toString()}_$i');
        }

        final sorted = CFIComparator.sortByReadingOrder(cfis);

        // Sort should be stable - equal elements maintain relative order
        expect(sorted.length, equals(cfis.length));
        for (int i = 0; i < sorted.length; i++) {
          expect(sorted[i].toString(), equals(cfis[i].toString()));
        }
      });
    });
  });
}
