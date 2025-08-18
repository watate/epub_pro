import 'package:test/test.dart';
import 'package:epub_pro/src/cfi/core/cfi.dart';
import 'package:epub_pro/src/cfi/core/cfi_range.dart';

void main() {
  group('CFI Range Tests', () {
    group('Range Creation - fromStartEnd', () {
      test('Create range from same spine CFIs', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/4!/4/10/2:15)');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:15)'));
      });

      test('Create range from different elements same spine', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/4!/4/12/2:15)');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4,/10/2:5,/12/2:15)'));
      });

      test('Create range from different spines', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/6!/4/10/2:15)');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(
            range.toString(), equals('epubcfi(/6,/4!/4/10/2:5,/6!/4/10/2:15)'));
      });

      test('Create range with no common parent', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/8/6!/4/10/2:15)');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(),
            equals('epubcfi(,/6/4!/4/10/2:5,/8/6!/4/10/2:15)'));
      });

      test('Reject range CFI as input', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final point = CFI('epubcfi(/6/4!/4/10/2:20)');

        expect(() => CFIRange.fromStartEnd(range, point),
            throwsA(isA<ArgumentError>()));
        expect(() => CFIRange.fromStartEnd(point, range),
            throwsA(isA<ArgumentError>()));
      });

      test('Handle CFIs with IDs', () {
        final start = CFI('epubcfi(/6/4[chapter1]!/4/10[para]/2:5)');
        final end = CFI('epubcfi(/6/4[chapter1]!/4/10[para]/2:15)');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(), contains('[chapter1]'));
        expect(range.toString(), contains('[para]'));
      });
    });

    group('Range Creation - fromTextOffsets', () {
      test('Create range within text node', () {
        final base = CFI('epubcfi(/6/4!/4/10/2)');
        final range = CFIRange.fromTextOffsets(base, 5, 15);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:15)'));
      });

      test('Create range with zero start offset', () {
        final base = CFI('epubcfi(/6/4!/4/10/2)');
        final range = CFIRange.fromTextOffsets(base, 0, 10);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:0,/2:10)'));
      });

      test('Create range with same start and end', () {
        final base = CFI('epubcfi(/6/4!/4/10/2)');
        final range = CFIRange.fromTextOffsets(base, 5, 5);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:5)'));
      });

      test('Preserve base CFI properties', () {
        final base = CFI('epubcfi(/6/4[chapter1]!/4/10[para]/2:100)');
        final range = CFIRange.fromTextOffsets(base, 5, 15);

        expect(range.isRange, isTrue);
        expect(range.toString(), contains('[chapter1]'));
        expect(range.toString(), contains('[para]'));
        expect(range.toString(), contains('/2:5'));
        expect(range.toString(), contains('/2:15'));
      });

      test('Reject range CFI as base', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');

        expect(() => CFIRange.fromTextOffsets(range, 5, 15),
            throwsA(isA<ArgumentError>()));
      });

      test('Reject invalid offsets', () {
        final base = CFI('epubcfi(/6/4!/4/10/2)');

        expect(() => CFIRange.fromTextOffsets(base, 15, 5),
            throwsA(isA<ArgumentError>()));
      });

      test('Handle single element path', () {
        final base = CFI('epubcfi(/6)');
        final range = CFIRange.fromTextOffsets(base, 5, 15);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(,/6:5,/6:15)'));
      });
    });

    group('Range Creation - expandAround', () {
      test('Expand around point with before and after', () {
        final point = CFI('epubcfi(/6/4!/4/10/2:10)');
        final range = CFIRange.expandAround(point, before: 3, after: 5);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:7,/2:15)'));
      });

      test('Expand around point with only before', () {
        final point = CFI('epubcfi(/6/4!/4/10/2:10)');
        final range = CFIRange.expandAround(point, before: 5);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:10)'));
      });

      test('Expand around point with only after', () {
        final point = CFI('epubcfi(/6/4!/4/10/2:10)');
        final range = CFIRange.expandAround(point, after: 8);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:10,/2:18)'));
      });

      test('Expand around point at beginning (clamp to 0)', () {
        final point = CFI('epubcfi(/6/4!/4/10/2:3)');
        final range = CFIRange.expandAround(point, before: 10, after: 5);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:0,/2:8)'));
      });

      test('Expand around point without offset', () {
        final point = CFI('epubcfi(/6/4!/4/10/2)');
        final range = CFIRange.expandAround(point, before: 3, after: 5);

        expect(range.isRange, isTrue);
        expect(range.toString(), equals('epubcfi(/6/4!/4/10,/2:0,/2:5)'));
      });

      test('Reject range CFI as input', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');

        expect(() => CFIRange.expandAround(range, before: 3, after: 5),
            throwsA(isA<ArgumentError>()));
      });
    });

    group('Range Operations - contains', () {
      test('Check if point is in range - inside', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final point = CFI('epubcfi(/6/4!/4/10/2:8)');

        expect(CFIRange.contains(range, point), isTrue);
      });

      test('Check if point is in range - at start boundary', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final point = CFI('epubcfi(/6/4!/4/10/2:5)');

        expect(CFIRange.contains(range, point), isTrue);
      });

      test('Check if point is in range - at end boundary', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final point = CFI('epubcfi(/6/4!/4/10/2:15)');

        expect(CFIRange.contains(range, point), isTrue);
      });

      test('Check if point is in range - before start', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final point = CFI('epubcfi(/6/4!/4/10/2:3)');

        expect(CFIRange.contains(range, point), isFalse);
      });

      test('Check if point is in range - after end', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final point = CFI('epubcfi(/6/4!/4/10/2:20)');

        expect(CFIRange.contains(range, point), isFalse);
      });

      test('Check if point is in range - different spine', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final point = CFI('epubcfi(/6/6!/4/10/2:8)');

        expect(CFIRange.contains(range, point), isFalse);
      });

      test('Reject point CFI as range parameter', () {
        final point1 = CFI('epubcfi(/6/4!/4/10/2:8)');
        final point2 = CFI('epubcfi(/6/4!/4/10/2:10)');

        expect(() => CFIRange.contains(point1, point2),
            throwsA(isA<ArgumentError>()));
      });

      test('Reject range CFI as point parameter', () {
        final range1 = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final range2 = CFI('epubcfi(/6/4!/4/10,/2:8,/2:12)');

        expect(() => CFIRange.contains(range1, range2),
            throwsA(isA<ArgumentError>()));
      });
    });

    group('Range Metrics - getLength', () {
      test('Get length of simple text range', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final length = CFIRange.getLength(range);

        expect(length, equals(10));
      });

      test('Get length of zero-length range', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:5)');
        final length = CFIRange.getLength(range);

        expect(length, equals(0));
      });

      test('Get length returns null for point CFI', () {
        final point = CFI('epubcfi(/6/4!/4/10/2:5)');
        final length = CFIRange.getLength(point);

        expect(length, isNull);
      });

      test('Get length returns null for cross-element range', () {
        final range = CFI('epubcfi(/6/4!/4,/10/2:5,/12/2:15)');
        final length = CFIRange.getLength(range);

        expect(length, isNull);
      });

      test('Get length returns null for different index range', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/4:15)');
        final length = CFIRange.getLength(range);

        expect(length, isNull);
      });

      test('Get length returns null for range without offsets', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2,/4)');
        final length = CFIRange.getLength(range);

        expect(length, isNull);
      });
    });

    group('Range Operations - mergeRanges', () {
      test('Merge overlapping ranges', () {
        final ranges = [
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)'),
          CFI('epubcfi(/6/4!/4/10,/2:8,/2:15)'),
          CFI('epubcfi(/6/4!/4/10,/2:20,/2:25)'),
        ];

        final merged = CFIRange.mergeRanges(ranges);

        expect(merged.length, equals(2));
        expect(merged[0].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:15)'));
        expect(merged[1].toString(), equals('epubcfi(/6/4!/4/10,/2:20,/2:25)'));
      });

      test('Merge adjacent ranges', () {
        final ranges = [
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)'),
          CFI('epubcfi(/6/4!/4/10,/2:10,/2:15)'),
          CFI('epubcfi(/6/4!/4/10,/2:15,/2:20)'),
        ];

        final merged = CFIRange.mergeRanges(ranges);

        expect(merged.length, equals(1));
        expect(merged[0].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:20)'));
      });

      test('Merge ranges with no overlap', () {
        final ranges = [
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:8)'),
          CFI('epubcfi(/6/4!/4/10,/2:15,/2:20)'),
          CFI('epubcfi(/6/4!/4/10,/2:25,/2:30)'),
        ];

        final merged = CFIRange.mergeRanges(ranges);

        expect(merged.length, equals(3));
        expect(merged, equals(ranges));
      });

      test('Merge ranges out of order', () {
        final ranges = [
          CFI('epubcfi(/6/4!/4/10,/2:20,/2:25)'),
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)'),
          CFI('epubcfi(/6/4!/4/10,/2:8,/2:15)'),
        ];

        final merged = CFIRange.mergeRanges(ranges);

        expect(merged.length, equals(2));
        expect(merged[0].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:15)'));
        expect(merged[1].toString(), equals('epubcfi(/6/4!/4/10,/2:20,/2:25)'));
      });

      test('Merge single range', () {
        final ranges = [CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)')];
        final merged = CFIRange.mergeRanges(ranges);

        expect(merged.length, equals(1));
        expect(merged[0], equals(ranges[0]));
      });

      test('Merge empty list', () {
        final ranges = <CFI>[];
        final merged = CFIRange.mergeRanges(ranges);

        expect(merged, isEmpty);
      });

      test('Reject point CFIs in merge', () {
        final ranges = [
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)'),
          CFI('epubcfi(/6/4!/4/10/2:8)'), // Point CFI
        ];

        expect(
            () => CFIRange.mergeRanges(ranges), throwsA(isA<ArgumentError>()));
      });

      test('Merge complex overlapping scenario', () {
        final ranges = [
          CFI('epubcfi(/6/4!/4/10,/2:1,/2:5)'),
          CFI('epubcfi(/6/4!/4/10,/2:3,/2:8)'),
          CFI('epubcfi(/6/4!/4/10,/2:6,/2:12)'),
          CFI('epubcfi(/6/4!/4/10,/2:20,/2:25)'),
          CFI('epubcfi(/6/4!/4/10,/2:15,/2:22)'),
        ];

        final merged = CFIRange.mergeRanges(ranges);

        expect(merged.length, equals(2));
        expect(merged[0].toString(), equals('epubcfi(/6/4!/4/10,/2:1,/2:12)'));
        expect(merged[1].toString(), equals('epubcfi(/6/4!/4/10,/2:15,/2:25)'));
      });
    });

    group('Range Operations - splitAt', () {
      test('Split range at middle point', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final splitPoint = CFI('epubcfi(/6/4!/4/10/2:10)');

        final parts = CFIRange.splitAt(range, splitPoint);

        expect(parts, isNotNull);
        expect(parts!.length, equals(2));
        expect(parts[0].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:10)'));
        expect(parts[1].toString(), equals('epubcfi(/6/4!/4/10,/2:10,/2:15)'));
      });

      test('Split range at start boundary', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final splitPoint = CFI('epubcfi(/6/4!/4/10/2:5)');

        final parts = CFIRange.splitAt(range, splitPoint);

        expect(parts, isNotNull);
        expect(parts!.length, equals(2));
        expect(parts[0].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:5)'));
        expect(parts[1].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:15)'));
      });

      test('Split range at end boundary', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final splitPoint = CFI('epubcfi(/6/4!/4/10/2:15)');

        final parts = CFIRange.splitAt(range, splitPoint);

        expect(parts, isNotNull);
        expect(parts!.length, equals(2));
        expect(parts[0].toString(), equals('epubcfi(/6/4!/4/10,/2:5,/2:15)'));
        expect(parts[1].toString(), equals('epubcfi(/6/4!/4/10,/2:15,/2:15)'));
      });

      test('Split range outside boundaries returns null', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final splitPoint = CFI('epubcfi(/6/4!/4/10/2:20)');

        final parts = CFIRange.splitAt(range, splitPoint);

        expect(parts, isNull);
      });

      test('Split range with point before range returns null', () {
        final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final splitPoint = CFI('epubcfi(/6/4!/4/10/2:3)');

        final parts = CFIRange.splitAt(range, splitPoint);

        expect(parts, isNull);
      });

      test('Reject point CFI as range parameter', () {
        final point1 = CFI('epubcfi(/6/4!/4/10/2:8)');
        final point2 = CFI('epubcfi(/6/4!/4/10/2:10)');

        expect(() => CFIRange.splitAt(point1, point2),
            throwsA(isA<ArgumentError>()));
      });

      test('Reject range CFI as split point', () {
        final range1 = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final range2 = CFI('epubcfi(/6/4!/4/10,/2:8,/2:12)');

        expect(() => CFIRange.splitAt(range1, range2),
            throwsA(isA<ArgumentError>()));
      });
    });

    group('Edge Cases and Complex Scenarios', () {
      test('Range operations with temporal offsets', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5~1.5)');
        final end = CFI('epubcfi(/6/4!/4/10/2:15~2.5)');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(), contains('~1.5'));
        expect(range.toString(), contains('~2.5'));
      });

      test('Range operations with spatial coordinates', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5@10.0)');
        final end = CFI('epubcfi(/6/4!/4/10/2:15@30.0)');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(), contains('@10.0'));
        expect(range.toString(), contains('@30.0'));
      });

      test('Range operations with text assertions', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5[,hello,world])');
        final end = CFI('epubcfi(/6/4!/4/10/2:15[,foo,bar])');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(), contains('[,hello,world]'));
        expect(range.toString(), contains('[,foo,bar]'));
      });

      test('Range operations with side bias', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5[before])');
        final end = CFI('epubcfi(/6/4!/4/10/2:15[after])');

        final range = CFIRange.fromStartEnd(start, end);

        expect(range.isRange, isTrue);
        expect(range.toString(), contains('[before]'));
        expect(range.toString(), contains('[after]'));
      });

      test('Complex range merge with different spine items', () {
        final ranges = [
          CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)'),
          CFI('epubcfi(/6/6!/4/10,/2:5,/2:10)'),
          CFI('epubcfi(/6/4!/4/12,/2:5,/2:10)'),
        ];

        final merged = CFIRange.mergeRanges(ranges);

        // Each range is in different location, no merging should occur
        expect(merged.length, equals(3));
      });

      test('Performance with many small ranges', () {
        const count = 100;
        final ranges = <CFI>[];

        // Create overlapping ranges: 0-5, 2-7, 4-9, 6-11, etc.
        for (int i = 0; i < count; i++) {
          final start = i * 2;
          final end = start + 5;
          ranges.add(CFI('epubcfi(/6/4!/4/10,/2:$start,/2:$end)'));
        }

        final stopwatch = Stopwatch()..start();
        final merged = CFIRange.mergeRanges(ranges);
        stopwatch.stop();

        // Should merge overlapping ranges efficiently - with overlapping ranges,
        // we should get much fewer than 100 (likely just 1 big merged range)
        expect(merged.length, lessThan(5));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));

        print(
            'Merged $count overlapping ranges into ${merged.length} ranges in ${stopwatch.elapsedMicroseconds} μs');
      });
    });

    group('Integration with CFI Operations', () {
      test('Range collapse matches fromStartEnd logic', () {
        final start = CFI('epubcfi(/6/4!/4/10/2:5)');
        final end = CFI('epubcfi(/6/4!/4/10/2:15)');
        final range = CFIRange.fromStartEnd(start, end);

        final collapsedStart = range.collapse();
        final collapsedEnd = range.collapse(toEnd: true);

        expect(collapsedStart.toString(), equals(start.toString()));
        expect(collapsedEnd.toString(), equals(end.toString()));
      });

      test('Range creation preserves CFI comparison order', () {
        final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)');
        final cfi2 = CFI('epubcfi(/6/4!/4/10/2:8)');
        final cfi3 = CFI('epubcfi(/6/4!/4/10/2:12)');

        final range1 = CFIRange.fromStartEnd(cfi1, cfi2);
        final range2 = CFIRange.fromStartEnd(cfi2, cfi3);

        expect(range1.compare(range2), lessThan(0));
        expect(CFIRange.contains(range1, cfi1), isTrue);
        expect(CFIRange.contains(range1, cfi3), isFalse);
        expect(CFIRange.contains(range2, cfi2), isTrue);
        expect(CFIRange.contains(range2, cfi1), isFalse);
      });

      test('Range serialization round-trip', () {
        final originalRange = CFI(
            'epubcfi(/6/4[chapter1]!/4/10[para],/2:5[before],/2:15[after])');

        expect(originalRange.isRange, isTrue);

        final collapsed = originalRange.collapse();
        final collapsedEnd = originalRange.collapse(toEnd: true);
        final reconstructed = CFIRange.fromStartEnd(collapsed, collapsedEnd);

        expect(reconstructed.toString(), equals(originalRange.toString()));
      });
    });
  });
}
