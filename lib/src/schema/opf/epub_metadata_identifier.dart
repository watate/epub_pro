import 'package:quiver/core.dart';

class EpubMetadataIdentifier {
  String? id;
  String? scheme;
  String? identifier;

  @override
  int get hashCode => hash3(id.hashCode, scheme.hashCode, identifier.hashCode);

  @override
  bool operator ==(other) {
    var otherAs = other as EpubMetadataIdentifier?;
    if (otherAs == null) return false;
    return id == otherAs.id &&
        scheme == otherAs.scheme &&
        identifier == otherAs.identifier;
  }
}
