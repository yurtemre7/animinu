class AnimeEntry {
  String title;
  int currentEpisode;
  int totalEpisodes;
  DateTime added;

  AnimeEntry({
    required this.title,
    required this.currentEpisode,
    this.totalEpisodes = 0,
    required this.added,
  });

  factory AnimeEntry.fromSnapshot(dynamic json) {
    return AnimeEntry(
      title: json['title'].toString(),
      currentEpisode: int.tryParse(json['currentEpisode'].toString()) ?? 0,
      totalEpisodes: int.tryParse(json['totalEpisodes'].toString()) ?? 0,
      added: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(json['added'].toString()) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
