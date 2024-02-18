library epubreadertest;

import 'dart:math';

import 'package:epub_plus/epub_plus.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final generator = RandomDataGenerator(Random(7898), 10);
  final EpubNavigationPoint reference = generator.randomEpubNavigationPoint(1);

  late EpubNavigationPoint testNavigationPoint;

  setUp(() async {
    testNavigationPoint = reference.copyWith();
  });

  group("EpubNavigationPoint", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationPoint, equals(reference));
      });

      test("is false when ChildNavigationPoints changes", () async {
        testNavigationPoint.childNavigationPoints
            .add(generator.randomEpubNavigationPoint());
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when Class changes", () async {
        testNavigationPoint =
            testNavigationPoint.copyWith(classs: generator.randomString());
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when Content changes", () async {
        testNavigationPoint = testNavigationPoint.copyWith(
            content: generator.randomEpubNavigationContent());
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when Id changes", () async {
        testNavigationPoint =
            testNavigationPoint.copyWith(id: generator.randomString());
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationPoint =
            testNavigationPoint.copyWith(playOrder: generator.randomString());
        expect(testNavigationPoint, isNot(reference));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationPoint.navigationLabels
            .add(generator.randomEpubNavigationLabel());
        expect(testNavigationPoint, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationPoint.hashCode, equals(reference.hashCode));
      });

      test("is false when ChildNavigationPoints changes", () async {
        testNavigationPoint.childNavigationPoints
            .add(generator.randomEpubNavigationPoint());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when Class changes", () async {
        testNavigationPoint =
            testNavigationPoint.copyWith(classs: generator.randomString());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when Content changes", () async {
        testNavigationPoint = testNavigationPoint.copyWith(
            content: generator.randomEpubNavigationContent());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testNavigationPoint =
            testNavigationPoint.copyWith(id: generator.randomString());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationPoint =
            testNavigationPoint.copyWith(playOrder: generator.randomString());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationPoint.navigationLabels
            .add(generator.randomEpubNavigationLabel());
        expect(testNavigationPoint.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubNavigationPoint {
  EpubNavigationPoint copyWith({
    String? id,
    String? classs,
    String? playOrder,
    List<EpubNavigationLabel>? navigationLabels,
    EpubNavigationContent? content,
    List<EpubNavigationPoint>? childNavigationPoints,
  }) {
    return EpubNavigationPoint(
      id: id ?? this.id,
      classs: classs ?? this.classs,
      playOrder: playOrder ?? this.playOrder,
      navigationLabels: navigationLabels ?? List.from(this.navigationLabels),
      content: content ?? this.content,
      childNavigationPoints:
          childNavigationPoints ?? List.from(this.childNavigationPoints),
    );
  }
}
