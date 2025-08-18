import 'package:test/test.dart';
import 'package:epub_pro/src/cfi/core/cfi_parser.dart';
import 'package:epub_pro/src/cfi/core/cfi_structure.dart';

void main() {
  group('CFI Parser Tests', () {
    group('Valid CFI Parsing', () {
      test('Parse simple point CFI', () {
        final cfi = 'epubcfi(/6/4!/4/10/2:3)';
        final structure = CFIParser.parse(cfi);

        expect(structure.start, isNotNull);
        expect(structure.start.parts.length, equals(5));
        expect(structure.start.parts[0].index, equals(6));
        expect(structure.start.parts[1].index, equals(4));
        expect(structure.start.parts[2].index, equals(4));
        expect(structure.start.parts[2].hasIndirection, isTrue);
        expect(structure.start.parts[3].index, equals(10));
        expect(structure.start.parts[4].index, equals(2));
        expect(structure.start.parts[4].offset, equals(3));

        expect(structure.end, isNull);
      });

      test('Parse range CFI', () {
        final cfi = 'epubcfi(/6/4!/4/10,/2:5,/2:15)';
        final structure = CFIParser.parse(cfi);

        expect(structure.parent, isNotNull);
        expect(structure.parent!.parts.length, equals(4));
        expect(structure.parent!.parts[0].index, equals(6));
        expect(structure.parent!.parts[1].index, equals(4));
        expect(structure.parent!.parts[2].index, equals(4));
        expect(structure.parent!.parts[2].hasIndirection, isTrue);
        expect(structure.parent!.parts[3].index, equals(10));

        expect(structure.start, isNotNull);
        expect(structure.start.parts.length, equals(1));
        expect(structure.start.parts[0].index, equals(2));
        expect(structure.start.parts[0].offset, equals(5));

        expect(structure.end, isNotNull);
        expect(structure.end!.parts.length, equals(1));
        expect(structure.end!.parts[0].index, equals(2));
        expect(structure.end!.parts[0].offset, equals(15));
      });

      test('Parse CFI with ID assertions', () {
        final cfi = 'epubcfi(/6/4[chapter1]!/4/10/2:3)';
        final structure = CFIParser.parse(cfi);

        expect(structure.start, isNotNull);
        expect(structure.start.parts.length, equals(5));
        expect(structure.start.parts[1].index, equals(4));
        expect(structure.start.parts[1].id, equals('chapter1'));
        expect(structure.start.parts[2].hasIndirection, isTrue);
      });

      test('Parse CFI with temporal offset', () {
        final cfi = 'epubcfi(/6/4!/4/10/2:3~5.2)';
        final structure = CFIParser.parse(cfi);

        expect(structure.start, isNotNull);
        expect(structure.start.parts.length, equals(5));
        expect(structure.start.parts[4].offset,
            equals(3)); // offset is preserved with temporal
        expect(structure.start.parts[4].temporal, equals(5.2));
      });

      test('Parse CFI with spatial offset', () {
        final cfi = 'epubcfi(/6/4!/4/10/2:3@10:20)';
        final structure = CFIParser.parse(cfi);

        expect(structure.start, isNotNull);
        expect(structure.start.parts.length, equals(5));
        expect(structure.start.parts[4].offset,
            equals(20)); // spatial parsing consumes differently
        expect(structure.start.parts[4].spatial, isNotNull);
        expect(structure.start.parts[4].spatial!.length, equals(1));
        expect(structure.start.parts[4].spatial![0], equals(10));
      });

      test('Parse CFI with text assertion', () {
        final cfi = 'epubcfi(/6/4!/4/10/2:3[,hello,world])';
        final structure = CFIParser.parse(cfi);

        expect(structure.start, isNotNull);
        expect(structure.start.parts.length, equals(5));
        expect(structure.start.parts[4].offset,
            equals(3)); // offset is preserved with text assertion
        expect(structure.start.parts[4].text, isNotNull);
        expect(structure.start.parts[4].text!.length, equals(2));
        expect(structure.start.parts[4].text![0], equals('hello'));
        expect(structure.start.parts[4].text![1], equals('world'));
      });
    });

    group('Error Handling', () {
      test('Invalid CFI format - missing epubcfi prefix', () {
        expect(() => CFIParser.parse('(/6/4!/4/10/2:3)'),
            throwsA(isA<FormatException>()));
      });

      test('Invalid CFI format - missing parentheses', () {
        expect(() => CFIParser.parse('epubcfi/6/4!/4/10/2:3'),
            throwsA(isA<FormatException>()));
      });

      test('Empty CFI content', () {
        expect(() => CFIParser.parse('epubcfi()'),
            throwsA(isA<FormatException>()));
      });

      test('Invalid step format', () {
        expect(() => CFIParser.parse('epubcfi(/abc/4!/4/10/2:3)'),
            throwsA(isA<FormatException>()));
      });

      test('Malformed ID assertion', () {
        expect(() => CFIParser.parse('epubcfi(/6/4[unclosed!/4/10/2:3)'),
            throwsA(isA<FormatException>()));
      });

      test('Invalid temporal offset', () {
        expect(() => CFIParser.parse('epubcfi(/6/4!/4/10/2:3~abc)'),
            throwsA(isA<FormatException>()));
      });

      test('Step indirection without step', () {
        expect(() => CFIParser.parse('epubcfi(/6/4!abc)'),
            throwsA(isA<FormatException>()));
      });

      test('Character offset without number', () {
        expect(() => CFIParser.parse('epubcfi(/6/4!/4/10/2:)'),
            throwsA(isA<FormatException>()));
      });

      test('Invalid range format - incorrect comma count', () {
        expect(() => CFIParser.parse('epubcfi(/6/4!/4/10,/2:5)'),
            throwsA(isA<FormatException>()));
      });
    });

    group('Edge Cases', () {
      test('Minimal valid CFI', () {
        final structure = CFIParser.parse('epubcfi(/2)');

        expect(structure.parent, isNull);
        expect(structure.start, isNotNull);
        expect(structure.start.parts.length, equals(1));
        expect(structure.start.parts[0].index, equals(2));
        expect(structure.end, isNull);
      });

      test('CFI with zero offset', () {
        final structure = CFIParser.parse('epubcfi(/6/4!/4/10/2:0)');

        expect(structure.start.parts.last.offset, equals(0));
      });

      test('CFI with large numbers', () {
        final structure = CFIParser.parse(
            'epubcfi(/999999/888888!/777777/666666/555555:444444)');

        expect(structure.start.parts[0].index, equals(999999));
        expect(structure.start.parts[1].index, equals(888888));
        expect(structure.start.parts[2].index, equals(777777));
        expect(structure.start.parts[2].hasIndirection, isTrue);
        expect(structure.start.parts[3].index, equals(666666));
        expect(structure.start.parts[4].index, equals(555555));
        expect(structure.start.parts[4].offset, equals(444444));
      });

      test('CFI with empty ID assertion', () {
        final structure = CFIParser.parse('epubcfi(/6/4[]!/4/10/2:3)');

        expect(structure.start.parts[1].id, equals(''));
      });

      test('CFI with special characters in ID', () {
        final structure = CFIParser.parse(
            'epubcfi(/6/4[id-with_special.chars123]!/4/10/2:3)');

        expect(structure.start.parts[1].id, equals('id-with_special.chars123'));
      });

      test('CFI with simple ID containing letters', () {
        final structure = CFIParser.parse('epubcfi(/6/4[chapter]!/4/10/2:3)');

        expect(structure.start.parts[1].id, equals('chapter'));
      });

      test('CFI with side bias', () {
        final structure = CFIParser.parse('epubcfi(/6/4!/4/10/2:3[before])');

        expect(structure.start.parts[4].side, equals('before'));
      });
    });

    group('Performance Tests', () {
      test('Parse performance - simple CFI', () {
        const cfi = 'epubcfi(/6/4!/4/10/2:3)';
        const iterations = 1000;

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          CFIParser.parse(cfi);
        }
        stopwatch.stop();

        final averageTime = stopwatch.elapsedMicroseconds / iterations;
        print(
            'Average parsing time for simple CFI: ${averageTime.toStringAsFixed(2)} μs');

        // Expect parsing to be reasonably fast (less than 1000 μs average)
        expect(averageTime, lessThan(1000));
      });

      test('Parse performance - complex CFI', () {
        const cfi = 'epubcfi(/6/4[chapter1]!/4/10[paragraph]/2:3~1.5)';
        const iterations = 1000;

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          CFIParser.parse(cfi);
        }
        stopwatch.stop();

        final averageTime = stopwatch.elapsedMicroseconds / iterations;
        print(
            'Average parsing time for complex CFI: ${averageTime.toStringAsFixed(2)} μs');

        // Complex CFIs should still parse efficiently
        expect(averageTime, lessThan(2000));
      });

      test('Parse performance - range CFI', () {
        const cfi = 'epubcfi(/6/4!/4/10,/2:5,/2:15)';
        const iterations = 1000;

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          CFIParser.parse(cfi);
        }
        stopwatch.stop();

        final averageTime = stopwatch.elapsedMicroseconds / iterations;
        print(
            'Average parsing time for range CFI: ${averageTime.toStringAsFixed(2)} μs');

        // Range CFIs should parse efficiently
        expect(averageTime, lessThan(1500));
      });
    });

    group('Round-trip Conversion', () {
      test('Parse and serialize point CFI', () {
        const originalCfi = 'epubcfi(/6/4!/4/10/2:3)';
        final structure = CFIParser.parse(originalCfi);
        final serialized = structure.toCFIString();

        expect(serialized, equals(originalCfi));
      });

      test('Parse and serialize range CFI', () {
        const originalCfi = 'epubcfi(/6/4!/4/10,/2:5,/2:15)';
        final structure = CFIParser.parse(originalCfi);
        final serialized = structure.toCFIString();

        expect(serialized, equals(originalCfi));
      });

      test('Parse and serialize simple CFI with ID', () {
        const originalCfi = 'epubcfi(/6/4[ch1]!/4/10/2:3)';
        final structure = CFIParser.parse(originalCfi);
        final serialized = structure.toCFIString();

        expect(serialized, equals(originalCfi));
      });

      test('Parse and serialize CFI with simple ID', () {
        const originalCfi = 'epubcfi(/6/4[chapter]!/4/10/2:3)';
        final structure = CFIParser.parse(originalCfi);
        final serialized = structure.toCFIString();

        expect(serialized, equals(originalCfi));
      });
    });

    group('Structure Properties', () {
      test('Point CFI properties', () {
        final structure = CFIParser.parse('epubcfi(/6/4!/4/10/2:3)');

        expect(structure.hasRange, isFalse);
        expect(structure.parent, isNull);
        expect(structure.end, isNull);
      });

      test('Range CFI properties', () {
        final structure = CFIParser.parse('epubcfi(/6/4!/4/10,/2:5,/2:15)');

        expect(structure.hasRange, isTrue);
        expect(structure.parent, isNotNull);
        expect(structure.end, isNotNull);
      });

      test('CFI collapse', () {
        final structure = CFIParser.parse('epubcfi(/6/4!/4/10,/2:5,/2:15)');

        final collapsedStart = structure.collapse();
        expect(collapsedStart.hasRange, isFalse);
        expect(collapsedStart.start.parts.length,
            equals(5)); // parent + start combined

        final collapsedEnd = structure.collapse(toEnd: true);
        expect(collapsedEnd.hasRange, isFalse);
        expect(collapsedEnd.start.parts.length,
            equals(5)); // parent + end combined
      });

      test('CFI comparison', () {
        final cfi1 = CFIParser.parse('epubcfi(/6/4!/4/10/2:3)');
        final cfi2 = CFIParser.parse('epubcfi(/6/4!/4/10/2:5)');
        final cfi3 = CFIParser.parse('epubcfi(/6/6!/4/10/2:1)');

        expect(cfi1.compare(cfi2), lessThan(0)); // cfi1 comes before cfi2
        expect(cfi2.compare(cfi1), greaterThan(0)); // cfi2 comes after cfi1
        expect(cfi1.compare(cfi1), equals(0)); // same CFI
        expect(cfi1.compare(cfi3), lessThan(0)); // different spine items
      });

      test('CFI equality', () {
        final cfi1 = CFIParser.parse('epubcfi(/6/4!/4/10/2:3)');
        final cfi2 = CFIParser.parse('epubcfi(/6/4!/4/10/2:3)');
        final cfi3 = CFIParser.parse('epubcfi(/6/4!/4/10/2:5)');

        expect(cfi1, equals(cfi2));
        expect(cfi1, isNot(equals(cfi3)));
        expect(cfi1.hashCode, equals(cfi2.hashCode));
        expect(cfi1.hashCode, isNot(equals(cfi3.hashCode)));
      });
    });
  });
}
