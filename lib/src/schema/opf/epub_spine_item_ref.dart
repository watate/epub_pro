import 'package:quiver/core.dart';

class EpubSpineItemRef {
  String? idRef;
  bool? isLinear;

  @override
  int get hashCode => hash2(idRef.hashCode, isLinear.hashCode);

  @override
  bool operator ==(other) {
    var otherAs = other as EpubSpineItemRef?;
    if (otherAs == null) {
      return false;
    }

    return idRef == otherAs.idRef && isLinear == otherAs.isLinear;
  }

  @override
  String toString() {
    return 'IdRef: $idRef';
  }
}
