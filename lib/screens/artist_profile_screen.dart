import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/artist_profile.dart';
import '../models/track.dart';
import '../services/artist_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'player_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistId;
  final String artistName;

  const ArtistProfileScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  final _artistService = ArtistService();
  final _audio = AudioService();

  ArtistProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
    _loadProfile();
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _artistService.fetchArtistProfile(widget.artistId);
      final following = await _artistService.isFollowing(widget.artistId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isFollowing = following;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _followLoading = true);
    try {
      final nowFollowing = await _artistService.toggleFollow(widget.artistId);
      if (mounted) {
        setState(() {
          _isFollowing = nowFollowing;
          _followLoading = false;
          if (_profile != null) {
            final delta = nowFollowing ? 1 : -1;
            _profile = ArtistProfile(
              id: _profile!.id,
              displayName: _profile!.displayName,
              bio: _profile!.bio,
              avatarUrl: _profile!.avatarUrl,
              regionTags: _profile!.regionTags,
              tracks: _profile!.tracks,
              events: _profile!.events,
              followerCount: _profile!.followerCount + delta,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _followLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update follow: $e'),
          backgroundColor: SColors.danger,
        ));
      }
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
    return Scaffold(
      backgroundColor: SColors.void_bg,
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          if (_audio.currentTrack != null)
            SMiniPlayer(
              track: _audio.currentTrack!,
              isPlaying: _audio.isPlaying,
              onTap: _openPlayer,
              onTogglePlay: _audio.togglePlayPause,
              onNext: _audio.playNext,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return CustomScrollView(slivers: [
        _buildAppBar(null),
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(color: SColors.pulse)),
        ),
      ]);
    }

    if (_error != null) {
      return CustomScrollView(slivers: [
        _buildAppBar(null),
        SliverFillRemaining(
          child: SErrorState(
            message: _error!,
            onRetry: () {
              setState(() { _loading = true; _error = null; });
              _loadProfile();
            },
          ),
        ),
      ]);
    }

    final profile = _profile!;

    return CustomScrollView(
      slivers: [
        _buildAppBar(profile),
        SliverToBoxAdapter(child: _buildHeader(profile)),
        if (profile.events.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SSectionHeader(title: 'Upcoming shows')),
          SliverToBoxAdapter(child: _buildEventsStrip(profile.events)),
        ],
        if (profile.tracks.isNotEmpty)
          const SliverToBoxAdapter(child: SSectionHeader(title: 'Tracks')),
        if (profile.tracks.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No tracks yet', style: STextStyles.body)),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final track = profile.tracks[i];
                final isPlaying = _audio.currentTrack?.id == track.id && _audio.isPlaying;
                return _ArtistTrackTile(
                  track: track,
                  isPlaying: isPlaying,
                  onTap: () {
                    _audio.playTrack(track, profile.tracks);
                    _openPlayer();
                  },
                );
              },
              childCount: profile.tracks.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  SliverAppBar _buildAppBar(ArtistProfile? profile) {
    return SliverAppBar(
      backgroundColor: SColors.surface,
      expandedHeight: profile?.avatarUrl != null ? 220 : 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: SColors.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        profile?.displayName ?? widget.artistName,
        style: STextStyles.subtitle,
      ),
      flexibleSpace: profile?.avatarUrl != null
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: profile!.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: SColors.surface),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          SColors.void_bg.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(ArtistProfile profile) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final isOwnProfile = Supabase.instance.client.auth.currentUser?.id == profile.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (profile.avatarUrl == null) ...[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [SColors.pulseDeep, SColors.pulse],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName, style: STextStyles.title),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.followerCount} ${profile.followerCount == 1 ? 'follower' : 'followers'}  ·  '
                      '${profile.tracks.length} ${profile.tracks.length == 1 ? 'track' : 'tracks'}',
                      style: STextStyles.body,
                    ),
                  ],
                ),
              ),
              if (isLoggedIn && !isOwnProfile)
                SFollowButton(
                  isFollowing: _isFollowing,
                  loading: _followLoading,
                  onTap: _toggleFollow,
                ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(profile.bio!, style: STextStyles.body),
          ],
          if (profile.regionTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: profile.regionTags.map((t) => STag(label: t)).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.07)),
        ],
      ),
    );
  }

  Widget _buildEventsStrip(List<Event> events) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (context, i) => _EventCard(event: events[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Artist track tile
// ─────────────────────────────────────────────

class _ArtistTrackTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;

  const _ArtistTrackTile({required this.track, required this.isPlaying, required this.onTap});

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
                      const SizedBox(height: 3),
                      Text(track.formattedDuration, style: STextStyles.caption),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: SDurations.fast,
                  child: Icon(
                    isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                    key: ValueKey(isPlaying),
                    color: SColors.pulse,
                    size: 32,
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

// ─────────────────────────────────────────────
// Event card
// ─────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SColors.surface,
        borderRadius: SRadius.md,
        border: Border.all(color: SColors.pulse.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event.formattedDate,
            style: const TextStyle(
              color: SColors.pulse,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.title,
            style: STextStyles.subtitle.copyWith(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (event.venue != null) ...[
            const SizedBox(height: 4),
            Text(event.venue!, style: STextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
