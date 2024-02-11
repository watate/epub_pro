class EpubMetadataDate {
  final String? date;
  final String? event;

  const EpubMetadataDate({
    this.date,
    this.event,
  });

  @override
  int get hashCode => date.hashCode ^ event.hashCode;

  @override
  bool operator ==(covariant EpubMetadataDate other) {
    if (identical(this, other)) return true;

    return other.date == date && other.event == event;
  }
}
