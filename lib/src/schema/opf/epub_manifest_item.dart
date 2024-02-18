class EpubManifestItem {
  final String? id;
  final String? href;
  final String? mediaType;
  final String? mediaOverlay;
  final String? requiredNamespace;
  final String? requiredModules;
  final String? fallback;
  final String? fallbackStyle;
  final String? properties;

  const EpubManifestItem({
    this.id,
    this.href,
    this.mediaType,
    this.mediaOverlay,
    this.requiredNamespace,
    this.requiredModules,
    this.fallback,
    this.fallbackStyle,
    this.properties,
  });

  @override
  int get hashCode {
    return id.hashCode ^
        href.hashCode ^
        mediaType.hashCode ^
        mediaOverlay.hashCode ^
        requiredNamespace.hashCode ^
        requiredModules.hashCode ^
        fallback.hashCode ^
        fallbackStyle.hashCode ^
        properties.hashCode;
  }

  @override
  bool operator ==(covariant EpubManifestItem other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.href == href &&
        other.mediaType == mediaType &&
        other.mediaOverlay == mediaOverlay &&
        other.requiredNamespace == requiredNamespace &&
        other.requiredModules == requiredModules &&
        other.fallback == fallback &&
        other.fallbackStyle == fallbackStyle &&
        other.properties == properties;
  }

  @override
  String toString() {
    return 'Id: $id, Href = $href, MediaType = $mediaType, Properties = $properties, MediaOverlay = $mediaOverlay';
  }
}
