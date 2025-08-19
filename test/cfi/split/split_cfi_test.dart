import 'package:test/test.dart';
import 'package:epub_pro/src/cfi/core/cfi.dart';
import 'package:epub_pro/src/cfi/split/split_cfi.dart';

void main() {
  group('Split CFI Tests', () {
    group('Basic Split CFI Creation', () {
      test('Create Split CFI from string with split notation', () {
        const cfiString = 'epubcfi(/6/4!/split=2,total=3/4/10/2:15)';
        final splitCFI = SplitCFI(cfiString);

        expect(splitCFI.splitPart, equals(2));
        expect(splitCFI.totalParts, equals(3));
        expect(splitCFI.raw, equals(cfiString));
        expect(splitCFI.isSplitCFI, isTrue);
      });

      test('Create Split CFI from standard CFI and split info', () {
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
        final splitCFI = SplitCFI.fromStandardCFI(
          standardCFI,
          splitPart: 2,
          totalParts: 3,
        );

        expect(splitCFI.splitPart, equals(2));
        expect(splitCFI.totalParts, equals(3));
        expect(splitCFI.baseCFI, equals(standardCFI));
        expect(splitCFI.raw, contains('split=2,total=3'));
      });

      test('Extract base CFI correctly', () {
        const cfiString = 'epubcfi(/6/4!/split=2,total=3/4/10/2:15)';
        final splitCFI = SplitCFI(cfiString);
        final baseCFI = splitCFI.baseCFI;

        expect(baseCFI.raw, equals('epubcfi(/6/4!/4/10/2:15)'));
        expect(baseCFI.isSplitCFI, isFalse);
      });
    });

    group('Split CFI Validation', () {
      test('Validate correct split part numbers', () {
        expect(
          () => SplitCFI.fromStandardCFI(
            CFI('epubcfi(/6/4!/4/10/2:15)'),
            splitPart: 2,
            totalParts: 3,
          ),
          returnsNormally,
        );
      });

      test('Reject invalid split part numbers', () {
        expect(
          () => SplitCFI.fromStandardCFI(
            CFI('epubcfi(/6/4!/4/10/2:15)'),
            splitPart: 0,
            totalParts: 3,
          ),
          throwsFormatException,
        );

        expect(
          () => SplitCFI.fromStandardCFI(
            CFI('epubcfi(/6/4!/4/10/2:15)'),
            splitPart: 4,
            totalParts: 3,
          ),
          throwsFormatException,
        );

        expect(
          () => SplitCFI.fromStandardCFI(
            CFI('epubcfi(/6/4!/4/10/2:15)'),
            splitPart: 1,
            totalParts: 0,
          ),
          throwsFormatException,
        );
      });

      test('Reject malformed split CFI strings', () {
        expect(
          () => SplitCFI('epubcfi(/6/4!/invalid=2,total=3/4/10/2:15)'),
          throwsFormatException,
        );

        expect(
          () => SplitCFI('epubcfi(/6/4!/split=a,total=3/4/10/2:15)'),
          throwsFormatException,
        );

        expect(
          () => SplitCFI('epubcfi(/6/4!/4/10/2:15)'), // No split info
          throwsFormatException,
        );
      });
    });

    group('Split CFI Comparison', () {
      test('Compare Split CFIs by base position then split part', () {
        final splitCFI1 = SplitCFI('epubcfi(/6/4!/split=1,total=3/4/10/2:15)');
        final splitCFI2 = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final splitCFI3 = SplitCFI('epubcfi(/6/6!/split=1,total=2/4/10/2:15)');

        // Same base position, different parts
        expect(splitCFI1.compare(splitCFI2), lessThan(0));
        expect(splitCFI2.compare(splitCFI1), greaterThan(0));
        expect(splitCFI1.compare(splitCFI1), equals(0));

        // Different base positions
        expect(splitCFI1.compare(splitCFI3), lessThan(0));
        expect(splitCFI3.compare(splitCFI1), greaterThan(0));
      });

      test('Compare Split CFI with standard CFI', () {
        final splitCFI = SplitCFI('epubcfi(/6/4!/split=1,total=3/4/10/2:15)');
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');

        // Split CFI should come after standard CFI at same base position
        expect(splitCFI.compare(standardCFI), greaterThan(0));
        expect(standardCFI.compare(splitCFI), lessThan(0));
      });
    });

    group('Split CFI Conversion', () {
      test('Convert Split CFI to standard CFI', () {
        final splitCFI = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final standardCFI = splitCFI.toStandardCFI();

        expect(standardCFI.raw, equals('epubcfi(/6/4!/4/10/2:15)'));
        expect(standardCFI.isSplitCFI, isFalse);
      });

      test('Copy Split CFI with different split info', () {
        final originalSplit =
            SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final copiedSplit = originalSplit.copyWithSplitInfo(
          splitPart: 1,
          totalParts: 4,
        );

        expect(copiedSplit.splitPart, equals(1));
        expect(copiedSplit.totalParts, equals(4));
        expect(copiedSplit.baseCFI, equals(originalSplit.baseCFI));
        expect(copiedSplit.raw, contains('split=1,total=4'));
      });
    });

    group('Split CFI Detection', () {
      test('Detect split CFI in strings', () {
        expect(
          SplitCFI.containsSplitInfo(
              'epubcfi(/6/4!/split=2,total=3/4/10/2:15)'),
          isTrue,
        );

        expect(
          SplitCFI.containsSplitInfo('epubcfi(/6/4!/4/10/2:15)'),
          isFalse,
        );

        expect(
          SplitCFI.containsSplitInfo('epubcfi(/6/4!/split=invalid/4/10/2:15)'),
          isFalse,
        );
      });

      test('Convert standard CFI to Split CFI if split info present', () {
        final cfiWithSplit = CFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final cfiWithoutSplit = CFI('epubcfi(/6/4!/4/10/2:15)');

        expect(cfiWithSplit.toSplitCFI(), isNotNull);
        expect(cfiWithSplit.toSplitCFI()!.splitPart, equals(2));

        expect(cfiWithoutSplit.toSplitCFI(), isNull);
      });
    });

    group('Split CFI String Building', () {
      test('Build valid split CFI string format', () {
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
        final splitCFI = SplitCFI.fromStandardCFI(
          standardCFI,
          splitPart: 2,
          totalParts: 3,
        );

        final expected = 'epubcfi(/6/4!/split=2,total=3/4/10/2:15)';
        expect(splitCFI.raw, equals(expected));
      });

      test('Handle CFI without character offset', () {
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2)');
        final splitCFI = SplitCFI.fromStandardCFI(
          standardCFI,
          splitPart: 1,
          totalParts: 2,
        );

        final expected = 'epubcfi(/6/4!/split=1,total=2/4/10/2)';
        expect(splitCFI.raw, equals(expected));
      });

      test('Handle range CFI with split notation', () {
        final rangeCFI = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
        final splitCFI = SplitCFI.fromStandardCFI(
          rangeCFI,
          splitPart: 2,
          totalParts: 3,
        );

        expect(splitCFI.raw, contains('split=2,total=3'));
        expect(splitCFI.isRange, isTrue);
      });
    });

    group('Split CFI Edge Cases', () {
      test('Handle single part split (should be valid)', () {
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
        final splitCFI = SplitCFI.fromStandardCFI(
          standardCFI,
          splitPart: 1,
          totalParts: 1,
        );

        expect(splitCFI.splitPart, equals(1));
        expect(splitCFI.totalParts, equals(1));
      });

      test('Handle large part numbers', () {
        final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
        final splitCFI = SplitCFI.fromStandardCFI(
          standardCFI,
          splitPart: 99,
          totalParts: 100,
        );

        expect(splitCFI.splitPart, equals(99));
        expect(splitCFI.totalParts, equals(100));
        expect(splitCFI.raw, contains('split=99,total=100'));
      });
    });

    group('Split CFI Equality and Hashing', () {
      test('Equal Split CFIs have same hash code', () {
        final splitCFI1 = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final splitCFI2 = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');

        expect(splitCFI1, equals(splitCFI2));
        expect(splitCFI1.hashCode, equals(splitCFI2.hashCode));
      });

      test('Different Split CFIs are not equal', () {
        final splitCFI1 = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final splitCFI2 = SplitCFI('epubcfi(/6/4!/split=1,total=3/4/10/2:15)');
        final splitCFI3 = SplitCFI('epubcfi(/6/4!/split=2,total=2/4/10/2:15)');

        expect(splitCFI1, isNot(equals(splitCFI2)));
        expect(splitCFI1, isNot(equals(splitCFI3)));
        expect(splitCFI2, isNot(equals(splitCFI3)));
      });
    });

    group('Split CFI toString', () {
      test('Provides meaningful string representation', () {
        final splitCFI = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
        final stringRep = splitCFI.toString();

        expect(stringRep, contains('SplitCFI'));
        expect(stringRep, contains('part: 2/3'));
        expect(stringRep, contains('base: epubcfi(/6/4!/4/10/2:15)'));
      });
    });
  });
}
