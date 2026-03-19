import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/track.dart';
import '../services/track_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'artist_profile_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _trackService = TrackService();
  final _audio = AudioService();
  List<Track> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
    _loadTracks();
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    super.dispose();
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await _trackService.fetchTracks();
      if (mounted) setState(() { _tracks = tracks; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: SColors.void_bg,
        body: Center(child: CircularProgressIndicator(color: SColors.pulse)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: SColors.void_bg,
        body: SErrorState(
          message: _error!,
          onRetry: () {
            setState(() { _loading = true; _error = null; });
            _loadTracks();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: SColors.void_bg,
      body: RefreshIndicator(
        color: SColors.pulse,
        backgroundColor: SColors.surface,
        onRefresh: _loadTracks,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (_tracks.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SSectionHeader(title: 'New releases')),
              SliverToBoxAdapter(child: _buildFeaturedStrip()),
            ],
            const SliverToBoxAdapter(child: SSectionHeader(title: 'All tracks')),
            if (_tracks.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No tracks yet', style: STextStyles.body)),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final track = _tracks[i];
                    return _TrackTile(
                      track: track,
                      isPlaying: _audio.currentTrack?.id == track.id && _audio.isPlaying,
                      onTap: () {
                        _audio.playTrack(track, _tracks);
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
                  childCount: _tracks.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return const SliverAppBar(
      backgroundColor: SColors.void_bg,
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text('soundscape', style: STextStyles.display),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      height: 44,
      decoration: BoxDecoration(
        color: SColors.elevated,
        borderRadius: SRadius.md,
      ),
      child: const Row(
        children: [
          SizedBox(width: 14),
          Icon(Icons.search_rounded, color: SColors.textHint, size: 18),
          SizedBox(width: 10),
          Text('Search artists, tracks…',
              style: TextStyle(color: SColors.textHint, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFeaturedStrip() {
    final featured = _tracks.take(5).toList();
    return SizedBox(
      height: 155,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: featured.length,
        itemBuilder: (context, i) {
          final track = featured[i];
          return _FeaturedCard(
            track: track,
            isPlaying: _audio.currentTrack?.id == track.id && _audio.isPlaying,
            onTap: () {
              _audio.playTrack(track, _tracks);
              _openPlayer();
            },
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;

  const _FeaturedCard({required this.track, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SDurations.normal,
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: SRadius.md,
          border: Border.all(
            color: isPlaying ? SColors.pulse.withOpacity(0.6) : Colors.white.withOpacity(0.06),
            width: isPlaying ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: SCoverArt(imageUrl: track.coverUrl, size: 120, radius: BorderRadius.zero),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: isPlaying ? SColors.pulse : SColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(track.artistName ?? '', style: STextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onArtistTap;

  const _TrackTile({required this.track, required this.isPlaying, required this.onTap, this.onArtistTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SDurations.normal,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: SColors.surface,
        borderRadius: SRadius.md,
        border: Border.all(
          color: isPlaying ? SColors.pulse.withOpacity(0.4) : Colors.white.withOpacity(0.04),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: SRadius.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SCoverArt(imageUrl: track.coverUrl, size: 52),
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
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: onArtistTap,
                        child: Text(
                          track.artistName ?? 'Unknown artist',
                          style: TextStyle(
                            color: onArtistTap != null
                                ? SColors.pulseGlow.withOpacity(0.8)
                                : SColors.textHint,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (track.genreTags.isNotEmpty) ...[
                            STag(label: track.genreTags.first),
                            const SizedBox(width: 8),
                          ],
                          Text(track.formattedDuration, style: STextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: SDurations.fast,
                  child: Icon(
                    isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                    key: ValueKey(isPlaying),
                    color: SColors.pulse,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
