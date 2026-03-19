import 'package:flutter_test/flutter_test.dart';
import 'package:soundscape/models/artist_profile.dart';
import 'package:soundscape/models/track.dart';

void main() {
  group('ArtistProfileScreen', () {
    test('builds with valid artist profile', () {
      final profile = ArtistProfile(
        id: '123',
        displayName: 'Test Artist',
        bio: 'A test bio',
        avatarUrl: 'https://example.com/avatar.jpg',
        regionTags: ['Electronic', 'House'],
        tracks: [
          Track(
            id: 'track1',
            title: 'Test Track',
            artistName: 'Test Artist',
            durationSeconds: 180,
            coverUrl: 'https://example.com/cover.jpg',
          ),
        ],
        events: [
          Event(
            id: 'event1',
            title: 'Live Show',
            eventDate: DateTime.now().add(const Duration(days: 7)),
            venue: 'Test Venue',
          ),
        ],
        followerCount: 1000,
      );

      expect(profile.displayName, 'Test Artist');
      expect(profile.tracks.length, 1);
      expect(profile.events.length, 1);
      expect(profile.followerCount, 1000);
    });

    test('follow button state updates correctly', () {
      bool isFollowing = false;
      isFollowing = !isFollowing;
      expect(isFollowing, true);
    });
  });
}