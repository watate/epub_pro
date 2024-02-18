library epubreadertest;

import 'dart:math';

import 'package:epub_plus/epub_plus.dart';
import 'package:epub_plus/src/schema/navigation/epub_navigation_target.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final RandomDataGenerator generator = RandomDataGenerator(Random(123778), 10);

  final EpubNavigationTarget reference = generator.randomEpubNavigationTarget();

  late EpubNavigationTarget testNavigationTarget;

  setUp(() async {
    testNavigationTarget = reference.copyWith();
  });

  group("EpubNavigationTarget", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationTarget, equals(reference));
      });

      test("is false when Class changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(classs: generator.randomString());
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when Content changes", () async {
        testNavigationTarget = testNavigationTarget.copyWith(
            content: generator.randomEpubNavigationContent());
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when Id changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(id: generator.randomString());
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationTarget = testNavigationTarget.copyWith(
            navigationLabels: [generator.randomEpubNavigationLabel()]);
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(playOrder: generator.randomString());
        expect(testNavigationTarget, isNot(reference));
      });
      test("is false when Value changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(value: generator.randomString());
        expect(testNavigationTarget, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationTarget.hashCode, equals(reference.hashCode));
      });

      test("is false when Class changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(classs: generator.randomString());
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when Content changes", () async {
        testNavigationTarget = testNavigationTarget.copyWith(
            content: generator.randomEpubNavigationContent());
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when Id changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(id: generator.randomString());
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when NavigationLabels changes", () async {
        testNavigationTarget = testNavigationTarget.copyWith(
            navigationLabels: [generator.randomEpubNavigationLabel()]);
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when PlayOrder changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(playOrder: generator.randomString());
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
      test("is false when Value changes", () async {
        testNavigationTarget =
            testNavigationTarget.copyWith(value: generator.randomString());
        expect(testNavigationTarget.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubNavigationTarget {
  EpubNavigationTarget copyWith({
    String? id,
    String? classs,
    String? value,
    String? playOrder,
    List<EpubNavigationLabel>? navigationLabels,
    EpubNavigationContent? content,
  }) {
    return EpubNavigationTarget(
      id: id ?? this.id,
      classs: classs ?? this.classs,
      value: value ?? this.value,
      playOrder: playOrder ?? this.playOrder,
      navigationLabels: navigationLabels ?? List.from(this.navigationLabels),
      content: content ?? this.content,
    );
  }
}
