class Track {
  final String id;
  final String title;
  final String? audioUrl;
  final String? coverUrl;
  final List<String> genreTags;
  final List<String> regionTags;
  final int durationSeconds;
  final int playCount;
  final String? artistId;
  final String? artistName;

  const Track({
    required this.id,
    required this.title,
    this.audioUrl,
    this.coverUrl,
    this.genreTags = const [],
    this.regionTags = const [],
    this.durationSeconds = 0,
    this.playCount = 0,
    this.artistId,
    this.artistName,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      audioUrl: json['audio_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      genreTags: List<String>.from(json['genre_tags'] ?? []),
      regionTags: List<String>.from(json['region_tags'] ?? []),
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      playCount: json['play_count'] as int? ?? 0,
      artistId: json['artist_id'] as String?,
      artistName: json['users']?['display_name'] as String?,
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}