import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  Track? _currentTrack;
  List<Track> _queue = [];
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Track? get currentTrack => _currentTrack;
  List<Track> get queue => _queue;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  AudioPlayer get player => _player;

  // Sample audio for testing — replace with real URLs when tracks have audio_url
  static const String _sampleAudioUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  void init() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> playTrack(Track track, List<Track> queue) async {
    _currentTrack = track;
    _queue = queue;
    notifyListeners();

    final url = track.audioUrl ?? _sampleAudioUrl;
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playNext() async {
    if (_currentTrack == null || _queue.isEmpty) return;
    final currentIndex = _queue.indexWhere((t) => t.id == _currentTrack!.id);
    if (currentIndex < _queue.length - 1) {
      await playTrack(_queue[currentIndex + 1], _queue);
    }
  }

  Future<void> playPrevious() async {
    if (_currentTrack == null || _queue.isEmpty) return;
    // If more than 3 seconds in, restart current track
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final currentIndex = _queue.indexWhere((t) => t.id == _currentTrack!.id);
    if (currentIndex > 0) {
      await playTrack(_queue[currentIndex - 1], _queue);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}