import 'package:collection/collection.dart';

class EpubMetadataMeta {
  final String? name;
  final String? content;
  final String? id;
  final String? refines;
  final String? property;
  final String? scheme;
  final Map<String, String> attributes;

  const EpubMetadataMeta({
    this.name,
    this.content,
    this.id,
    this.refines,
    this.property,
    this.scheme,
    this.attributes = const <String, String>{},
  });

  @override
  int get hashCode {
    return name.hashCode ^
        content.hashCode ^
        id.hashCode ^
        refines.hashCode ^
        property.hashCode ^
        scheme.hashCode ^
        const DeepCollectionEquality().hash(attributes);
  }

  @override
  bool operator ==(covariant EpubMetadataMeta other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other.name == name &&
        other.content == content &&
        other.id == id &&
        other.refines == refines &&
        other.property == property &&
        other.scheme == scheme &&
        mapEquals(other.attributes, attributes);
  }
}
