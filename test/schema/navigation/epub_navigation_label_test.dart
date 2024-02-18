library epubreadertest;

import 'dart:math';

import 'package:epub_plus/src/schema/navigation/epub_navigation_label.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final RandomDataGenerator generator = RandomDataGenerator(Random(123778), 10);

  final EpubNavigationLabel reference = generator.randomEpubNavigationLabel();

  late EpubNavigationLabel testNavigationLabel;
  setUp(() async {
    testNavigationLabel = reference.copyWith();
  });

  group("EpubNavigationLabel", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationLabel, equals(reference));
      });

      test("is false when Text changes", () async {
        testNavigationLabel =
            reference.copyWith(text: generator.randomString());
        expect(testNavigationLabel, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationLabel.hashCode, equals(reference.hashCode));
      });

      test("is false when Metadata changes", () async {
        testNavigationLabel = reference.copyWith(
          text: generator.randomString(),
        );
        expect(testNavigationLabel.hashCode, isNot(reference.hashCode));
      });
    });
  });
}

extension on EpubNavigationLabel {
  EpubNavigationLabel copyWith({
    String? text,
  }) {
    return EpubNavigationLabel(
      text: text ?? this.text,
    );
  }
}
