import 'package:quiver/core.dart';

class EpubMetadataCreator {
  String? creator;
  String? fileAs;
  String? role;

  @override
  int get hashCode => hash3(creator.hashCode, fileAs.hashCode, role.hashCode);

  @override
  bool operator ==(other) {
    var otherAs = other as EpubMetadataCreator?;
    if (otherAs == null) return false;
    return creator == otherAs.creator &&
        fileAs == otherAs.fileAs &&
        role == otherAs.role;
  }
}
