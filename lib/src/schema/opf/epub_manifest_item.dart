import 'package:quiver/core.dart';

class EpubManifestItem {
  String? id;
  String? href;
  String? mediaType;
  String? mediaOverlay;
  String? requiredNamespace;
  String? requiredModules;
  String? fallback;
  String? fallbackStyle;
  String? properties;

  @override
  int get hashCode => hashObjects([
        id.hashCode,
        href.hashCode,
        mediaType.hashCode,
        mediaOverlay.hashCode,
        requiredNamespace.hashCode,
        requiredModules.hashCode,
        fallback.hashCode,
        fallbackStyle.hashCode,
        properties.hashCode
      ]);

  @override
  bool operator ==(other) {
    var otherAs = other as EpubManifestItem?;
    if (otherAs == null) {
      return false;
    }

    return id == otherAs.id &&
        href == otherAs.href &&
        mediaType == otherAs.mediaType &&
        mediaOverlay == otherAs.mediaOverlay &&
        requiredNamespace == otherAs.requiredNamespace &&
        requiredModules == otherAs.requiredModules &&
        fallback == otherAs.fallback &&
        fallbackStyle == otherAs.fallbackStyle &&
        properties == otherAs.properties;
  }

  @override
  String toString() {
    return 'Id: $id, Href = $href, MediaType = $mediaType, Properties = $properties, MediaOverlay = $mediaOverlay';
  }
}
