library epubreadertest;

import 'dart:math';

import 'package:epubx/src/schema/navigation/epub_navigation_target.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final RandomDataGenerator generator = RandomDataGenerator(Random(123778), 10);

  final EpubNavigationTarget reference = generator.randomEpubNavigationTarget();

  late EpubNavigationTarget testNavigationTarget;

  setUp(() async {
    testNavigationTarget = EpubNavigationTarget()
      ..classs = reference.classs
      ..content = reference.content
      ..id = reference.id
      ..navigationLabels = List.from(reference.navigationLabels ?? [])
      ..playOrder = reference.playOrder
      ..value = reference.value;
  });

  group("EpubNavigationTarget", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationTarget, equals(reference));
      });

      test("is false when Class changes", () async {
        testNavigationTarget.classs = generator.randomString();
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when Content changes", () async {
        testNavigationTarget.content = generator.randomEpubNavigationContent();
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when Id changes", () async {
        testNavigationTarget.id = generator.randomString();
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationTarget.navigationLabels = [
          generator.randomEpubNavigationLabel()
        ];
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationTarget.playOrder = generator.randomString();
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when Value changes", () async {
        testNavigationTarget.value = generator.randomString();
        expect(testNavigationTarget, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationTarget.hashCode, equals(reference.hashCode));
      });

      test("is false when Class changes", () async {
        testNavigationTarget.classs = generator.randomString();
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when Content changes", () async {
        testNavigationTarget.content = generator.randomEpubNavigationContent();
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testNavigationTarget.id = generator.randomString();
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationTarget.navigationLabels = [
          generator.randomEpubNavigationLabel()
        ];
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationTarget.playOrder = generator.randomString();
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when Value changes", () async {
        testNavigationTarget.value = generator.randomString();
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
