library epubreadertest;

import 'dart:math';

import 'package:epub_plus/src/schema/opf/epub_guide_reference.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final RandomDataGenerator generator = RandomDataGenerator(Random(123778), 10);

  var reference = generator.randomEpubGuideReference();

  late EpubGuideReference testGuideReference;

  setUp(() async {
    testGuideReference = reference.copyWith();
  });

  group("EpubGuideReference", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testGuideReference, equals(reference));
      });

      test("is false when Href changes", () async {
        testGuideReference =
            testGuideReference.copyWith(href: generator.randomString());

        expect(testGuideReference, isNot(reference));
      });

      test("is false when Title changes", () async {
        testGuideReference =
            testGuideReference.copyWith(title: generator.randomString());
        expect(testGuideReference, isNot(reference));
      });

      test("is false when Type changes", () async {
        testGuideReference =
            testGuideReference.copyWith(type: generator.randomString());
        expect(testGuideReference, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testGuideReference.hashCode, equals(reference.hashCode));
      });

      test("is false when Href changes", () async {
        testGuideReference =
            testGuideReference.copyWith(href: generator.randomString());

        expect(testGuideReference.hashCode, isNot(reference.hashCode));
      });

      test("is false when Title changes", () async {
        testGuideReference =
            testGuideReference.copyWith(title: generator.randomString());
        expect(testGuideReference.hashCode, isNot(reference.hashCode));
      });

      test("is false when Type changes", () async {
        testGuideReference =
            testGuideReference.copyWith(type: generator.randomString());
        expect(testGuideReference.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubGuideReference {
  EpubGuideReference copyWith({
    String? type,
    String? title,
    String? href,
  }) {
    return EpubGuideReference(
      type: type ?? this.type,
      title: title ?? this.title,
      href: href ?? this.href,
    );
  }
}
