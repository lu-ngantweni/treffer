import 'package:soundscape/models/track.dart';

class ArtistProfile {
  final String id;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final List<String> regionTags;
  final List<Track> tracks;
  final List<Event> events;
  final int followerCount;

  const ArtistProfile({
    required this.id,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.regionTags = const [],
    this.tracks = const [],
    this.events = const [],
    this.followerCount = 0,
  });

  factory ArtistProfile.fromJson(
    Map<String, dynamic> json, {
    List<Track> tracks = const [],
    List<Event> events = const [],
    int followerCount = 0,
  }) {
    return ArtistProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      regionTags: List<String>.from(json['region_tags'] ?? []),
      tracks: tracks,
      events: events,
      followerCount: followerCount,
    );
  }
}

class Event {
  final String id;
  final String title;
  final String? venue;
  final DateTime eventDate;
  final String? ticketUrl;

  const Event({
    required this.id,
    required this.title,
    this.venue,
    required this.eventDate,
    this.ticketUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      venue: json['venue'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      ticketUrl: json['ticket_url'] as String?,
    );
  }

  String get formattedDate {
    return '${eventDate.day} ${_monthName(eventDate.month)} ${eventDate.year}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}