import 'epub_guide.dart';
import 'epub_manifest.dart';
import 'epub_metadata.dart';
import 'epub_spine.dart';
import 'epub_version.dart';

class EpubPackage {
  final EpubVersion? version;
  final EpubMetadata? metadata;
  final EpubManifest? manifest;
  final EpubSpine? spine;
  final EpubGuide? guide;

  const EpubPackage({
    this.version,
    this.metadata,
    this.manifest,
    this.spine,
    this.guide,
  });

  EpubPackage copyWith({
    EpubVersion? version,
    EpubMetadata? metadata,
    EpubManifest? manifest,
    EpubSpine? spine,
    EpubGuide? guide,
  }) {
    return EpubPackage(
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
      manifest: manifest ?? this.manifest,
      spine: spine ?? this.spine,
      guide: guide ?? this.guide,
    );
  }

  @override
  int get hashCode {
    return version.hashCode ^
        metadata.hashCode ^
        manifest.hashCode ^
        spine.hashCode ^
        guide.hashCode;
  }

  @override
  bool operator ==(covariant EpubPackage other) {
    if (identical(this, other)) return true;

    return other.version == version &&
        other.metadata == metadata &&
        other.manifest == manifest &&
        other.spine == spine &&
        other.guide == guide;
  }
}
