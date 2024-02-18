import 'package:collection/collection.dart';

import 'epub_metadata_contributor.dart';
import 'epub_metadata_creator.dart';
import 'epub_metadata_date.dart';
import 'epub_metadata_identifier.dart';
import 'epub_metadata_meta.dart';

class EpubMetadata {
  final List<String> titles;
  final List<EpubMetadataCreator> creators;
  final List<String> subjects;
  final String? description;
  final List<String> publishers;
  final List<EpubMetadataContributor> contributors;
  final List<EpubMetadataDate> dates;
  final List<String> types;
  final List<String> formats;
  final List<EpubMetadataIdentifier> identifiers;
  final List<String> sources;
  final List<String> languages;
  final List<String> relations;
  final List<String> coverages;
  final List<String> rights;
  final List<EpubMetadataMeta> metaItems;

  const EpubMetadata({
    this.titles = const <String>[],
    this.creators = const <EpubMetadataCreator>[],
    this.subjects = const <String>[],
    this.description,
    this.publishers = const <String>[],
    this.contributors = const <EpubMetadataContributor>[],
    this.dates = const <EpubMetadataDate>[],
    this.types = const <String>[],
    this.formats = const <String>[],
    this.identifiers = const <EpubMetadataIdentifier>[],
    this.sources = const <String>[],
    this.languages = const <String>[],
    this.relations = const <String>[],
    this.coverages = const <String>[],
    this.rights = const <String>[],
    this.metaItems = const <EpubMetadataMeta>[],
  });

  @override
  int get hashCode {
    final hash = const DeepCollectionEquality().hash;

    return hash(titles) ^
        hash(creators) ^
        hash(subjects) ^
        description.hashCode ^
        hash(publishers) ^
        hash(contributors) ^
        hash(dates) ^
        hash(types) ^
        hash(formats) ^
        hash(identifiers) ^
        hash(sources) ^
        hash(languages) ^
        hash(relations) ^
        hash(coverages) ^
        hash(rights) ^
        hash(metaItems);
  }

  @override
  bool operator ==(covariant EpubMetadata other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return listEquals(other.titles, titles) &&
        listEquals(other.creators, creators) &&
        listEquals(other.subjects, subjects) &&
        other.description == description &&
        listEquals(other.publishers, publishers) &&
        listEquals(other.contributors, contributors) &&
        listEquals(other.dates, dates) &&
        listEquals(other.types, types) &&
        listEquals(other.formats, formats) &&
        listEquals(other.identifiers, identifiers) &&
        listEquals(other.sources, sources) &&
        listEquals(other.languages, languages) &&
        listEquals(other.relations, relations) &&
        listEquals(other.coverages, coverages) &&
        listEquals(other.rights, rights) &&
        listEquals(other.metaItems, metaItems);
  }
}
