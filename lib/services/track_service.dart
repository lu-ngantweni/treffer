import 'package:soundscape/main.dart';
import '../models/track.dart';
 
class TrackService {
  Future<List<Track>> fetchTracks() async {
    final response = await supabase
        .from('tracks')
        .select('*, users(display_name)')
        .order('released_at', ascending: false);
 
    return (response as List).map((json) => Track.fromJson(json)).toList();
  }
}