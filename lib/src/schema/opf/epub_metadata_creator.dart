class EpubMetadataCreator {
  final String? creator;
  final String? fileAs;
  final String? role;

  const EpubMetadataCreator({
    this.creator,
    this.fileAs,
    this.role,
  });

  @override
  int get hashCode => creator.hashCode ^ fileAs.hashCode ^ role.hashCode;

  @override
  bool operator ==(covariant EpubMetadataCreator other) {
    if (identical(this, other)) return true;

    return other.creator == creator &&
        other.fileAs == fileAs &&
        other.role == role;
  }
}
