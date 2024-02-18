import 'dart:math' show Random;

import 'package:epub_plus/epub_plus.dart';
import 'package:epub_plus/src/schema/navigation/epub_navigation_target.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_contributor.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_date.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_identifier.dart';
import 'package:epub_plus/src/schema/opf/epub_metadata_meta.dart';

class RandomString {
  final Random rng;

  RandomString(this.rng);

  static const asciiStart = 33;
  static const asciiEnd = 126;
  static const numericStart = 48;
  static const numericEnd = 57;
  static const lowerAlphaStart = 97;
  static const lowerAlphaEnd = 122;
  static const upperAlphaStart = 65;
  static const upperAlphaEnd = 90;

  /// Generates a random integer where [from] <= [to].
  int randomBetween(int from, int to) {
    if (from > to) throw Exception('$from is not > $to');
    return ((to - from) * rng.nextDouble()).toInt() + from;
  }

  /// Generates a random string of [length] with characters
  /// between ascii [from] to [to].
  /// Defaults to characters of ascii '!' to '~'.
  String randomString(
    int length, {
    int from = asciiStart,
    int to = asciiEnd,
  }) {
    return String.fromCharCodes(
        List.generate(length, (index) => randomBetween(from, to)));
  }

  /// Generates a random string of [length] with only numeric characters.
  String randomNumeric(int length) =>
      randomString(length, from: numericStart, to: numericEnd);

  /// Generates a random string of [length] with only alpha characters.
  String randomAlpha(int length) {
    var lowerAlphaLength = randomBetween(0, length);
    var upperAlphaLength = length - lowerAlphaLength;
    var lowerAlpha = randomString(lowerAlphaLength,
        from: lowerAlphaStart, to: lowerAlphaEnd);
    var upperAlpha = randomString(upperAlphaLength,
        from: upperAlphaStart, to: upperAlphaEnd);
    return randomMerge(lowerAlpha, upperAlpha);
  }

  /// Generates a random string of [length] with alpha-numeric characters.
  String randomAlphaNumeric(int length) {
    var alphaLength = randomBetween(0, length);
    var numericLength = length - alphaLength;
    var alpha = randomAlpha(alphaLength);
    var numeric = randomNumeric(numericLength);
    return randomMerge(alpha, numeric);
  }

  /// Merge [a] with [b] and scramble characters.
  String randomMerge(String a, String b) {
    List<int> mergedCodeUnits = List.from("$a$b".codeUnits);
    mergedCodeUnits.shuffle(rng);
    return String.fromCharCodes(mergedCodeUnits);
  }
}

class RandomDataGenerator {
  final Random rng;
  final RandomString _randomString;
  final int _length;

  RandomDataGenerator(this.rng, this._length)
      : _randomString = RandomString(rng);

  String randomString() {
    return _randomString.randomAlphaNumeric(_length);
  }

  EpubNavigationPoint randomEpubNavigationPoint([int depth = 0]) {
    return EpubNavigationPoint(
      id: randomString(),
      classs: randomString(),
      playOrder: randomString(),
      navigationLabels: [randomEpubNavigationLabel()],
      content: randomEpubNavigationContent(),
      childNavigationPoints:
          depth > 0 ? [randomEpubNavigationPoint(depth - 1)] : [],
    );
  }

  EpubNavigationContent randomEpubNavigationContent() {
    return EpubNavigationContent(
      id: randomString(),
      source: randomString(),
    );
  }

  EpubNavigationTarget randomEpubNavigationTarget() {
    return EpubNavigationTarget(
      id: randomString(),
      classs: randomString(),
      value: randomString(),
      playOrder: randomString(),
      navigationLabels: [randomEpubNavigationLabel()],
      content: randomEpubNavigationContent(),
    );
  }

  EpubNavigationLabel randomEpubNavigationLabel() {
    return EpubNavigationLabel(text: randomString());
  }

  EpubNavigationHead randomEpubNavigationHead() {
    return EpubNavigationHead(metadata: [randomNavigationHeadMeta()]);
  }

  EpubNavigationHeadMeta randomNavigationHeadMeta() {
    return EpubNavigationHeadMeta(
      content: randomString(),
      name: randomString(),
      scheme: randomString(),
    );
  }

  EpubNavigationDocTitle randomNavigationDocTitle() {
    return EpubNavigationDocTitle(titles: [randomString()]);
  }

  EpubNavigationDocAuthor randomNavigationDocAuthor() {
    return EpubNavigationDocAuthor(authors: [randomString()]);
  }

  EpubPackage randomEpubPackage() {
    return EpubPackage(
      guide: randomEpubGuide(),
      manifest: randomEpubManifest(),
      metadata: randomEpubMetadata(),
      spine: randomEpubSpine(),
      version: rng.nextBool() ? EpubVersion.epub2 : EpubVersion.epub3,
    );
  }

  EpubSpine randomEpubSpine() {
    final reference = EpubSpine(
      tableOfContents: _randomString.randomAlpha(_length),
      items: [randomEpubSpineItemRef()],
      ltr: true,
    );
    return reference;
  }

  EpubSpineItemRef randomEpubSpineItemRef() {
    return EpubSpineItemRef(
      idRef: _randomString.randomAlpha(_length),
      isLinear: true,
    );
  }

  EpubManifest randomEpubManifest() {
    return EpubManifest(items: [randomEpubManifestItem()]);
  }

  EpubManifestItem randomEpubManifestItem() {
    return EpubManifestItem(
      fallback: _randomString.randomAlpha(_length),
      fallbackStyle: _randomString.randomAlpha(_length),
      href: _randomString.randomAlpha(_length),
      id: _randomString.randomAlpha(_length),
      mediaType: _randomString.randomAlpha(_length),
      requiredModules: _randomString.randomAlpha(_length),
      requiredNamespace: _randomString.randomAlpha(_length),
    );
  }

  EpubGuide randomEpubGuide() {
    return EpubGuide(items: [randomEpubGuideReference()]);
  }

  EpubGuideReference randomEpubGuideReference() {
    return EpubGuideReference(
      href: _randomString.randomAlpha(_length),
      title: _randomString.randomAlpha(_length),
      type: _randomString.randomAlpha(_length),
    );
  }

  EpubMetadata randomEpubMetadata() {
    var reference = EpubMetadata(
      contributors: [randomEpubMetadataContributor()],
      coverages: [_randomString.randomAlpha(_length)],
      creators: [randomEpubMetadataCreator()],
      dates: [randomEpubMetadataDate()],
      description: _randomString.randomAlpha(_length),
      formats: [_randomString.randomAlpha(_length)],
      identifiers: [randomEpubMetadataIdentifier()],
      languages: [_randomString.randomAlpha(_length)],
      metaItems: [randomEpubMetadataMeta()],
      publishers: [_randomString.randomAlpha(_length)],
      relations: [_randomString.randomAlpha(_length)],
      rights: [_randomString.randomAlpha(_length)],
      sources: [_randomString.randomAlpha(_length)],
      subjects: [_randomString.randomAlpha(_length)],
      titles: [_randomString.randomAlpha(_length)],
      types: [_randomString.randomAlpha(_length)],
    );

    return reference;
  }

  EpubMetadataMeta randomEpubMetadataMeta() {
    return EpubMetadataMeta(
      content: _randomString.randomAlpha(_length),
      id: _randomString.randomAlpha(_length),
      name: _randomString.randomAlpha(_length),
      property: _randomString.randomAlpha(_length),
      refines: _randomString.randomAlpha(_length),
      scheme: _randomString.randomAlpha(_length),
    );
  }

  EpubMetadataIdentifier randomEpubMetadataIdentifier() {
    return EpubMetadataIdentifier(
      id: _randomString.randomAlpha(_length),
      scheme: _randomString.randomAlpha(_length),
      identifier: _randomString.randomAlpha(_length),
    );
  }

  EpubMetadataDate randomEpubMetadataDate() {
    return EpubMetadataDate(
      event: _randomString.randomAlpha(_length),
      date: _randomString.randomAlpha(_length),
    );
  }

  EpubMetadataContributor randomEpubMetadataContributor() {
    return EpubMetadataContributor(
      fileAs: _randomString.randomAlpha(_length),
      role: _randomString.randomAlpha(_length),
      contributor: _randomString.randomAlpha(_length),
    );
  }

  EpubMetadataCreator randomEpubMetadataCreator() {
    return EpubMetadataCreator(
      fileAs: _randomString.randomAlpha(_length),
      role: _randomString.randomAlpha(_length),
      creator: _randomString.randomAlpha(_length),
    );
  }
}
