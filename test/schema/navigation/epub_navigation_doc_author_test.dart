library epubreadertest;

import 'dart:math';

import 'package:epub_plus/src/schema/navigation/epub_navigation_doc_author.dart';
import 'package:test/test.dart';

import '../../random_data_generator.dart';

main() async {
  final generator = RandomDataGenerator(Random(7898), 10);
  final EpubNavigationDocAuthor reference =
      generator.randomNavigationDocAuthor();

  late EpubNavigationDocAuthor testNavigationDocAuthor;

  setUp(() async {
    testNavigationDocAuthor = EpubNavigationDocAuthor(
      authors: List.from(reference.authors),
    );
  });

  group("EpubNavigationDocAuthor", () {
    group(".equals", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationDocAuthor, equals(reference));
      });

      test("is false when Authors changes", () async {
        testNavigationDocAuthor.authors.add(generator.randomString());
        expect(testNavigationDocAuthor, isNot(reference));
      });
    });

    group(".hashCode", () {
      test("is true for equivalent objects", () async {
        expect(testNavigationDocAuthor.hashCode, equals(reference.hashCode));
      });

      test("is false when Authors changes", () async {
        testNavigationDocAuthor.authors.add(generator.randomString());
        expect(testNavigationDocAuthor.hashCode, isNot(reference.hashCode));
      });
    });
  });
}
