library epubreadertest;

import 'dart:math';

import 'package:epub_plus/src/schema/navigation/epub_navigation_head_meta.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final generator = RandomDataGenerator(Random(7898), 10);
  final EpubNavigationHeadMeta reference = generator.randomNavigationHeadMeta();

  late EpubNavigationHeadMeta testNavigationDocTitle;

  setUp(() async {
    testNavigationDocTitle = reference.copyWith();
  });

  group("EpubNavigationHeadMeta", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationDocTitle, equals(reference));
      });

      test("is false when Content changes", () async {
        testNavigationDocTitle =
            testNavigationDocTitle.copyWith(content: generator.randomString());
        expect(testNavigationDocTitle, isNot(reference));
      });
      test("is false when Name changes", () async {
        testNavigationDocTitle =
            testNavigationDocTitle.copyWith(name: generator.randomString());
        expect(testNavigationDocTitle, isNot(reference));
      });
      test("is false when Scheme changes", () async {
        testNavigationDocTitle =
            testNavigationDocTitle.copyWith(scheme: generator.randomString());
        expect(testNavigationDocTitle, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationDocTitle.hashCode, equals(reference.hashCode));
      });

      test("is false when Content changes", () async {
        testNavigationDocTitle =
            testNavigationDocTitle.copyWith(content: generator.randomString());
        expect(testNavigationDocTitle.hashCode, isNot(reference.hashCode));
      });
      test("is false when Name changes", () async {
        testNavigationDocTitle =
            testNavigationDocTitle.copyWith(name: generator.randomString());
        expect(testNavigationDocTitle.hashCode, isNot(reference.hashCode));
      });
      test("is false when Scheme changes", () async {
        testNavigationDocTitle =
            testNavigationDocTitle.copyWith(scheme: generator.randomString());
        expect(testNavigationDocTitle.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubNavigationHeadMeta {
  EpubNavigationHeadMeta copyWith({
    String? content,
    String? name,
    String? scheme,
  }) {
    return EpubNavigationHeadMeta(
      content: content ?? this.content,
      name: name ?? this.name,
      scheme: scheme ?? this.scheme,
    );
  }
}
