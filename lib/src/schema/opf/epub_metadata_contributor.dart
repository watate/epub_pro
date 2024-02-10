import 'package:quiver/core.dart';

class EpubMetadataContributor {
  String? contributor;
  String? fileAs;
  String? role;

  @override
  int get hashCode =>
      hash3(contributor.hashCode, fileAs.hashCode, role.hashCode);

  @override
  bool operator ==(other) {
    var otherAs = other as EpubMetadataContributor?;
    if (otherAs == null) return false;

    return contributor == otherAs.contributor &&
        fileAs == otherAs.fileAs &&
        role == otherAs.role;
  }
}
