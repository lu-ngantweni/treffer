import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/track_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'artist_profile_screen.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _trackService = TrackService();
  final _audio = AudioService();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<Track> _all = [];
  List<Track> _results = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
    _loadAll();
    _controller.addListener(_onQueryChanged);
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final tracks = await _trackService.fetchTracks();
      if (mounted) {
        setState(() {
          _all = tracks;
          _results = tracks;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQueryChanged() {
    final q = _controller.text.trim().toLowerCase();
    if (q == _query) return;
    _query = q;
    setState(() {
      _results = q.isEmpty
          ? _all
          : _all.where((t) {
              return t.title.toLowerCase().contains(q) ||
                  (t.artistName?.toLowerCase().contains(q) ?? false) ||
                  t.genreTags.any((g) => g.toLowerCase().contains(q)) ||
                  t.regionTags.any((r) => r.toLowerCase().contains(q));
            }).toList();
    });
  }

  void _openPlayer() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      transitionDuration: SDurations.slide,
      reverseTransitionDuration: SDurations.slide,
      pageBuilder: (_, __, ___) => const PlayerScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: SCurves.slide)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.void_bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: SColors.elevated,
                borderRadius: SRadius.md,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: SColors.textHint, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: false,
                      style: const TextStyle(
                          color: SColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Artists, tracks, genres…',
                        hintStyle: TextStyle(color: SColors.textHint, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        _focus.unfocus();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close_rounded,
                            color: SColors.textHint, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: SColors.pulse));
    }

    if (_query.isEmpty) {
      return _buildGenreGrid();
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: SColors.textHint, size: 40),
            const SizedBox(height: 12),
            Text('No results for "$_query"',
                style: STextStyles.body, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final track = _results[i];
        final isPlaying =
            _audio.currentTrack?.id == track.id && _audio.isPlaying;
        return _SearchResult(
          track: track,
          isPlaying: isPlaying,
          onTap: () {
            _audio.playTrack(track, _results);
            _openPlayer();
          },
          onArtistTap: track.artistId != null
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ArtistProfileScreen(
                      artistId: track.artistId!,
                      artistName: track.artistName ?? 'Artist',
                    ),
                  ))
              : null,
        );
      },
    );
  }

  Widget _buildGenreGrid() {
    // Collect unique genres from all tracks
    final genres = <String>{};
    for (final t in _all) {
      genres.addAll(t.genreTags);
    }

    final genreList = genres.toList()..sort();
    if (genreList.isEmpty) {
      return const Center(
          child: Text('Start typing to search', style: STextStyles.body));
    }

    final colors = [
      const Color(0xFF312e81),
      const Color(0xFF0c3b2e),
      const Color(0xFF2d1b0e),
      const Color(0xFF1e3a4b),
      const Color(0xFF3b1f2b),
      const Color(0xFF1a2f1a),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browse by genre', style: STextStyles.subtitle),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              itemCount: genreList.length,
              itemBuilder: (context, i) {
                final genre = genreList[i];
                return GestureDetector(
                  onTap: () {
                    _controller.text = genre;
                    _focus.requestFocus();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: SRadius.md,
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      genre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onArtistTap;

  const _SearchResult({
    required this.track,
    required this.isPlaying,
    required this.onTap,
    this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SCoverArt(imageUrl: track.coverUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: TextStyle(
                        color: isPlaying ? SColors.pulse : SColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: onArtistTap,
                      child: Text(
                        track.artistName ?? 'Unknown artist',
                        style: TextStyle(
                          color: onArtistTap != null
                              ? SColors.pulseGlow.withOpacity(0.8)
                              : SColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: SDurations.fast,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  color: SColors.pulse,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
