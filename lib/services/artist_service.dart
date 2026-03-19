import 'package:soundscape/main.dart';
import '../models/track.dart';
import '../models/artist_profile.dart';
 
class ArtistService {
  // Fetch a full artist profile by user ID.
  //
  // Makes three parallel queries:
  //   1. users row — display_name, bio, avatar_url, region_tags
  //   2. tracks for this artist — same join as TrackService
  //   3. upcoming events for this artist — ordered by date ascending
  //
  // Follower count is a separate aggregate query so it stays accurate
  // without denormalising into the users table.
  Future<ArtistProfile> fetchArtistProfile(String artistId) async {
    final results = await Future.wait([
      supabase
          .from('users')
          .select('id, display_name, bio, avatar_url, region_tags')
          .eq('id', artistId)
          .single(),
      supabase
          .from('tracks')
          .select('*, users(display_name)')
          .eq('artist_id', artistId)
          .order('released_at', ascending: false),
      supabase
          .from('events')
          .select()
          .eq('artist_id', artistId)
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true),
      supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', artistId),
    ]);
 
    final userJson = results[0] as Map<String, dynamic>;
    final tracksJson = results[1] as List<dynamic>;
    final eventsJson = results[2] as List<dynamic>;
    final followsJson = results[3] as List<dynamic>;
 
    final tracks = tracksJson.map((j) => Track.fromJson(j)).toList();
    final events = eventsJson.map((j) => Event.fromJson(j)).toList();
 
    return ArtistProfile.fromJson(
      userJson,
      tracks: tracks,
      events: events,
      followerCount: followsJson.length,
    );
  }
 
  // Check whether the signed-in user is following this artist.
  Future<bool> isFollowing(String artistId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;
 
    final result = await supabase
        .from('follows')
        .select('follower_id')
        .eq('follower_id', userId)
        .eq('following_id', artistId)
        .maybeSingle();
 
    return result != null;
  }
 
  // Toggle follow state — insert if not following, delete if already following.
  // Returns the new following state (true = now following).
  Future<bool> toggleFollow(String artistId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');
 
    final alreadyFollowing = await isFollowing(artistId);
 
    if (alreadyFollowing) {
      await supabase
          .from('follows')
          .delete()
          .eq('follower_id', userId)
          .eq('following_id', artistId);
      return false;
    } else {
      await supabase.from('follows').insert({
        'follower_id': userId,
        'following_id': artistId,
      });
      return true;
    }
  }
}