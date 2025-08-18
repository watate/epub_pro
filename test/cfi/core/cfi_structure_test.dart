import 'package:test/test.dart';
import 'package:epub_pro/src/cfi/core/cfi_structure.dart';

void main() {
  group('CFI Structure Tests', () {
    group('CFIPart Tests', () {
      test('Basic CFI part creation', () {
        final part = CFIPart(index: 6);

        expect(part.index, equals(6));
        expect(part.id, isNull);
        expect(part.offset, isNull);
        expect(part.temporal, isNull);
        expect(part.spatial, isNull);
        expect(part.text, isNull);
        expect(part.side, isNull);
        expect(part.hasIndirection, isFalse);
      });

      test('CFI part with all properties', () {
        final part = CFIPart(
          index: 4,
          id: 'chapter1',
          offset: 123,
          temporal: 5.5,
          spatial: [10.0, 20.0],
          text: ['before', 'after'],
          side: 'before',
          hasIndirection: true,
        );

        expect(part.index, equals(4));
        expect(part.id, equals('chapter1'));
        expect(part.offset, equals(123));
        expect(part.temporal, equals(5.5));
        expect(part.spatial, equals([10.0, 20.0]));
        expect(part.text, equals(['before', 'after']));
        expect(part.side, equals('before'));
        expect(part.hasIndirection, isTrue);
      });

      test('CFI part comparison', () {
        final part1 = CFIPart(index: 6, offset: 10);
        final part2 = CFIPart(index: 6, offset: 20);
        final part3 = CFIPart(index: 8, offset: 5);
        final part4 = CFIPart(index: 6, offset: 10);

        expect(part1.compare(part2),
            lessThan(0)); // same index, part1 offset < part2 offset
        expect(part1.compare(part3), lessThan(0)); // part1 index < part3 index
        expect(part1.compare(part4), equals(0)); // identical parts
        expect(part2.compare(part1),
            greaterThan(0)); // part2 offset > part1 offset
      });

      test('CFI part comparison with temporal', () {
        final part1 = CFIPart(index: 6, offset: 10, temporal: 1.5);
        final part2 = CFIPart(index: 6, offset: 10, temporal: 2.5);
        final part3 = CFIPart(index: 6, offset: 10); // no temporal

        expect(part1.compare(part2),
            lessThan(0)); // same index/offset, part1 temporal < part2 temporal
        expect(part3.compare(part1),
            lessThan(0)); // no temporal comes before temporal
        expect(part1.compare(part3),
            greaterThan(0)); // temporal comes after no temporal
      });

      test('CFI part serialization', () {
        final simplePart = CFIPart(index: 6);
        expect(simplePart.toCFIString(), equals('/6'));

        final partWithId = CFIPart(index: 4, id: 'chapter1');
        expect(partWithId.toCFIString(), equals('/4[chapter1]'));

        final partWithOffset = CFIPart(index: 2, offset: 123);
        expect(partWithOffset.toCFIString(), equals('/2:123'));

        final partWithTemporal = CFIPart(index: 2, offset: 123, temporal: 5.5);
        expect(partWithTemporal.toCFIString(), equals('/2:123~5.5'));

        final partWithSpatial =
            CFIPart(index: 2, offset: 123, spatial: [10.0, 20.0]);
        expect(partWithSpatial.toCFIString(), equals('/2:123@10.0:20.0'));

        final partWithIndirection = CFIPart(index: 4, hasIndirection: true);
        expect(partWithIndirection.toCFIString(), equals('!/4'));

        final partWithText =
            CFIPart(index: 2, offset: 123, text: ['hello', 'world']);
        expect(partWithText.toCFIString(), equals('/2:123[,hello,world]'));

        final partWithSide = CFIPart(index: 2, offset: 123, side: 'before');
        expect(partWithSide.toCFIString(), equals('/2:123[before]'));
      });

      test('CFI part with special characters in ID', () {
        final part = CFIPart(index: 4, id: 'id[with]brackets');
        expect(part.toCFIString(), equals('/4[id^[with^]brackets]'));
      });

      test('CFI part equality', () {
        final part1 = CFIPart(index: 6, id: 'test', offset: 10);
        final part2 = CFIPart(index: 6, id: 'test', offset: 10);
        final part3 = CFIPart(index: 6, id: 'test', offset: 20);

        expect(part1, equals(part2));
        expect(part1, isNot(equals(part3)));
        expect(part1.hashCode, equals(part2.hashCode));
        expect(part1.hashCode, isNot(equals(part3.hashCode)));
      });
    });

    group('CFIPath Tests', () {
      test('Basic CFI path creation', () {
        final path = CFIPath(parts: [
          CFIPart(index: 6),
          CFIPart(index: 4),
          CFIPart(index: 2, offset: 10),
        ]);

        expect(path.parts.length, equals(3));
        expect(path.parts[0].index, equals(6));
        expect(path.parts[1].index, equals(4));
        expect(path.parts[2].index, equals(2));
        expect(path.parts[2].offset, equals(10));
      });

      test('CFI path comparison', () {
        final path1 =
            CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 4, offset: 10)]);
        final path2 =
            CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 4, offset: 20)]);
        final path3 = CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 8)]);
        final path4 = CFIPath(parts: [CFIPart(index: 6)]); // shorter path

        expect(path1.compare(path2), lessThan(0)); // path1 comes before path2
        expect(path1.compare(path3), lessThan(0)); // path1 comes before path3
        expect(path4.compare(path1), lessThan(0)); // shorter path comes first
        expect(path1.compare(path1), equals(0)); // same path
      });

      test('CFI path serialization', () {
        final path = CFIPath(parts: [
          CFIPart(index: 6),
          CFIPart(index: 4, id: 'chapter1'),
          CFIPart(index: 10, hasIndirection: true),
          CFIPart(index: 2, offset: 123),
        ]);

        expect(path.toCFIString(), equals('/6/4[chapter1]!/10/2:123'));
      });

      test('CFI path equality', () {
        final path1 = CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 4)]);
        final path2 = CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 4)]);
        final path3 = CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 8)]);

        expect(path1, equals(path2));
        expect(path1, isNot(equals(path3)));
        expect(path1.hashCode, equals(path2.hashCode));
        expect(path1.hashCode, isNot(equals(path3.hashCode)));
      });

      test('Empty CFI path', () {
        final path = CFIPath(parts: []);

        expect(path.parts.length, equals(0));
        expect(path.toCFIString(), equals(''));
      });
    });

    group('CFIStructure Tests', () {
      test('Point CFI structure', () {
        final structure = CFIStructure(
          start: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, hasIndirection: true),
            CFIPart(index: 2, offset: 10),
          ]),
        );

        expect(structure.parent, isNull);
        expect(structure.start, isNotNull);
        expect(structure.end, isNull);
        expect(structure.hasRange, isFalse);
      });

      test('Range CFI structure', () {
        final structure = CFIStructure(
          parent: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, hasIndirection: true),
          ]),
          start: CFIPath(parts: [CFIPart(index: 2, offset: 5)]),
          end: CFIPath(parts: [CFIPart(index: 2, offset: 15)]),
        );

        expect(structure.parent, isNotNull);
        expect(structure.start, isNotNull);
        expect(structure.end, isNotNull);
        expect(structure.hasRange, isTrue);
      });

      test('CFI structure collapse - range to point', () {
        final structure = CFIStructure(
          parent: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, hasIndirection: true),
          ]),
          start: CFIPath(parts: [CFIPart(index: 2, offset: 5)]),
          end: CFIPath(parts: [CFIPart(index: 2, offset: 15)]),
        );

        // Collapse to start
        final collapsedStart = structure.collapse();
        expect(collapsedStart.hasRange, isFalse);
        expect(collapsedStart.parent, isNull);
        expect(collapsedStart.end, isNull);
        expect(collapsedStart.start.parts.length,
            equals(3)); // parent + start combined
        expect(collapsedStart.start.parts[0].index, equals(6));
        expect(collapsedStart.start.parts[1].index, equals(4));
        expect(collapsedStart.start.parts[1].hasIndirection, isTrue);
        expect(collapsedStart.start.parts[2].index, equals(2));
        expect(collapsedStart.start.parts[2].offset, equals(5));

        // Collapse to end
        final collapsedEnd = structure.collapse(toEnd: true);
        expect(collapsedEnd.hasRange, isFalse);
        expect(collapsedEnd.parent, isNull);
        expect(collapsedEnd.end, isNull);
        expect(collapsedEnd.start.parts.length,
            equals(3)); // parent + end combined
        expect(collapsedEnd.start.parts[2].offset, equals(15));
      });

      test('CFI structure collapse - point CFI unchanged', () {
        final structure = CFIStructure(
          start: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, offset: 10),
          ]),
        );

        final collapsed = structure.collapse();
        expect(collapsed, same(structure)); // Should return the same instance
      });

      test('CFI structure comparison', () {
        final struct1 = CFIStructure(
          start: CFIPath(
              parts: [CFIPart(index: 6), CFIPart(index: 4, offset: 10)]),
        );
        final struct2 = CFIStructure(
          start: CFIPath(
              parts: [CFIPart(index: 6), CFIPart(index: 4, offset: 20)]),
        );
        final struct3 = CFIStructure(
          start:
              CFIPath(parts: [CFIPart(index: 8), CFIPart(index: 4, offset: 5)]),
        );

        expect(struct1.compare(struct2), lessThan(0));
        expect(struct1.compare(struct3), lessThan(0));
        expect(struct1.compare(struct1), equals(0));
      });

      test('CFI structure comparison with parent paths', () {
        final struct1 = CFIStructure(
          parent: CFIPath(parts: [CFIPart(index: 6)]),
          start: CFIPath(parts: [CFIPart(index: 4, offset: 10)]),
        );
        final struct2 = CFIStructure(
          start: CFIPath(
              parts: [CFIPart(index: 6), CFIPart(index: 4, offset: 10)]),
        );

        // These should be equivalent when comparing effective start paths
        expect(struct1.compare(struct2), equals(0));
        expect(struct2.compare(struct1), equals(0));
      });

      test('CFI structure serialization - point CFI', () {
        final structure = CFIStructure(
          start: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, hasIndirection: true),
            CFIPart(index: 2, offset: 10),
          ]),
        );

        expect(structure.toCFIString(), equals('epubcfi(/6!/4/2:10)'));
      });

      test('CFI structure serialization - range CFI', () {
        final structure = CFIStructure(
          parent: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, hasIndirection: true),
          ]),
          start: CFIPath(parts: [CFIPart(index: 2, offset: 5)]),
          end: CFIPath(parts: [CFIPart(index: 2, offset: 15)]),
        );

        expect(structure.toCFIString(), equals('epubcfi(/6!/4,/2:5,/2:15)'));
      });

      test('CFI structure serialization - range CFI without parent', () {
        final structure = CFIStructure(
          start: CFIPath(parts: [CFIPart(index: 2, offset: 5)]),
          end: CFIPath(parts: [CFIPart(index: 2, offset: 15)]),
        );

        expect(structure.toCFIString(), equals('epubcfi(,/2:5,/2:15)'));
      });

      test('CFI structure equality', () {
        final struct1 = CFIStructure(
          start: CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 4)]),
        );
        final struct2 = CFIStructure(
          start: CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 4)]),
        );
        final struct3 = CFIStructure(
          start: CFIPath(parts: [CFIPart(index: 6), CFIPart(index: 8)]),
        );

        expect(struct1, equals(struct2));
        expect(struct1, isNot(equals(struct3)));
        expect(struct1.hashCode, equals(struct2.hashCode));
        expect(struct1.hashCode, isNot(equals(struct3.hashCode)));
      });

      test('CFI structure with complex parent and range', () {
        final structure = CFIStructure(
          parent: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, id: 'chapter1', hasIndirection: true),
            CFIPart(index: 10),
          ]),
          start: CFIPath(parts: [CFIPart(index: 2, offset: 5)]),
          end: CFIPath(parts: [CFIPart(index: 4, offset: 15)]),
        );

        expect(structure.hasRange, isTrue);
        expect(structure.parent!.parts.length, equals(3));
        expect(structure.start.parts.length, equals(1));
        expect(structure.end!.parts.length, equals(1));

        final serialized = structure.toCFIString();
        expect(serialized, equals('epubcfi(/6!/4[chapter1]/10,/2:5,/4:15)'));
      });
    });

    group('Edge Cases', () {
      test('CFI part with empty text list', () {
        final part = CFIPart(index: 2, text: []);
        expect(part.toCFIString(), equals('/2'));
      });

      test('CFI part with empty spatial list', () {
        final part = CFIPart(index: 2, spatial: []);
        expect(part.toCFIString(), equals('/2'));
      });

      test('CFI part with zero values', () {
        final part =
            CFIPart(index: 0, offset: 0, temporal: 0.0, spatial: [0.0, 0.0]);
        expect(part.toCFIString(), equals('/0:0~0.0@0.0:0.0'));
      });

      test('CFI path with single part', () {
        final path = CFIPath(parts: [CFIPart(index: 2)]);
        expect(path.toCFIString(), equals('/2'));
        expect(path.parts.length, equals(1));
      });

      test('CFI structure comparison with empty paths', () {
        final struct1 = CFIStructure(start: CFIPath(parts: []));
        final struct2 = CFIStructure(start: CFIPath(parts: []));

        expect(struct1.compare(struct2), equals(0));
        expect(struct1, equals(struct2));
      });
    });

    group('Complex Scenarios', () {
      test('Deep nested CFI structure', () {
        final structure = CFIStructure(
          start: CFIPath(parts: [
            CFIPart(index: 6),
            CFIPart(index: 4, id: 'book'),
            CFIPart(index: 8, hasIndirection: true),
            CFIPart(index: 12, id: 'chapter1'),
            CFIPart(index: 6, id: 'section1'),
            CFIPart(
                index: 2,
                offset: 123,
                text: ['before', 'after'],
                temporal: 5.5),
          ]),
        );

        expect(structure.start.parts.length, equals(6));
        expect(structure.hasRange, isFalse);

        final serialized = structure.toCFIString();
        expect(serialized, contains('epubcfi('));
        expect(serialized, contains('[book]'));
        expect(serialized, contains('!'));
        expect(serialized, contains('[chapter1]'));
        expect(serialized, contains(':123'));
        expect(serialized, contains('~5.5'));
      });

      test('CFI structure with all assertion types', () {
        final structure = CFIStructure(
          parent: CFIPath(parts: [
            CFIPart(index: 6, id: 'spine-item'),
            CFIPart(index: 4, hasIndirection: true),
          ]),
          start: CFIPath(parts: [
            CFIPart(
                index: 2,
                offset: 10,
                text: ['start', 'text'],
                temporal: 1.0,
                spatial: [5.0, 10.0]),
          ]),
          end: CFIPath(parts: [
            CFIPart(index: 2, offset: 20, side: 'after'),
          ]),
        );

        expect(structure.hasRange, isTrue);

        final serialized = structure.toCFIString();
        expect(serialized, contains('[spine-item]'));
        expect(serialized, contains('!'));
        expect(serialized, contains(':10'));
        expect(serialized, contains('~1.0'));
        expect(serialized, contains('@5.0:10.0'));
        expect(serialized, contains('[,start,text]'));
        expect(serialized, contains(':20'));
        expect(serialized, contains('[after]'));
      });

      test('Performance with large CFI structures', () {
        // Create a CFI with many parts
        final parts = <CFIPart>[];
        for (int i = 0; i < 100; i++) {
          parts.add(CFIPart(index: i * 2 + 2, id: 'part$i'));
        }

        final path = CFIPath(parts: parts);
        final structure = CFIStructure(start: path);

        final stopwatch = Stopwatch()..start();
        final serialized = structure.toCFIString();
        stopwatch.stop();

        expect(parts.length, equals(100));
        expect(serialized.length, greaterThan(500)); // Should be a long string
        expect(stopwatch.elapsedMilliseconds, lessThan(10)); // Should be fast

        print(
            'Serialized large CFI (${parts.length} parts) in ${stopwatch.elapsedMicroseconds} μs');
      });
    });
  });
}
