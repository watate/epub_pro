library epubreadertest;

import 'dart:math';

import 'package:epubx/src/schema/navigation/epub_navigation_point.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final generator = RandomDataGenerator(Random(7898), 10);
  final EpubNavigationPoint reference = generator.randomEpubNavigationPoint(1);

  late EpubNavigationPoint testNavigationPoint;

  setUp(() async {
    testNavigationPoint = EpubNavigationPoint()
      ..childNavigationPoints = List.from(reference.childNavigationPoints ?? [])
      ..classs = reference.classs
      ..content = reference.content
      ..id = reference.id
      ..navigationLabels = List.from(reference.navigationLabels ?? [])
      ..playOrder = reference.playOrder;
  });

  group("EpubNavigationPoint", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationPoint, equals(reference));
      });

      test("is false when ChildNavigationPoints changes", () async {
        testNavigationPoint.childNavigationPoints
            ?.add(generator.randomEpubNavigationPoint());
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when Class changes", () async {
        testNavigationPoint.classs = generator.randomString();
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when Content changes", () async {
        testNavigationPoint.content = generator.randomEpubNavigationContent();
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when Id changes", () async {
        testNavigationPoint.id = generator.randomString();
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationPoint.playOrder = generator.randomString();
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationPoint.navigationLabels
            ?.add(generator.randomEpubNavigationLabel());
        expect(testNavigationPoint, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationPoint.hashCode, equals(reference.hashCode));
      });

      test("is false when ChildNavigationPoints changes", () async {
        testNavigationPoint.childNavigationPoints
            ?.add(generator.randomEpubNavigationPoint());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when Class changes", () async {
        testNavigationPoint.classs = generator.randomString();
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when Content changes", () async {
        testNavigationPoint.content = generator.randomEpubNavigationContent();
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testNavigationPoint.id = generator.randomString();
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationPoint.playOrder = generator.randomString();
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationPoint.navigationLabels
            ?.add(generator.randomEpubNavigationLabel());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
