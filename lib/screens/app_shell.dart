import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'artist_list_screen.dart';
import 'profile_screen.dart';
import 'player_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final _audio = AudioService();

  // Keep screens alive while switching tabs
  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    ArtistListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _audio.init();
    _audio.addListener(_onAudio);
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    super.dispose();
  }

  void _openPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: SDurations.slide,
        reverseTransitionDuration: SDurations.slide,
        pageBuilder: (_, __, ___) => const PlayerScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: SCurves.slide)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.void_bg,
      body: IndexedStack(
        index: _tab,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player slides in above nav bar
          AnimatedSize(
            duration: SDurations.normal,
            curve: SCurves.slide,
            child: _audio.currentTrack != null
                ? _buildMiniPlayer()
                : const SizedBox.shrink(),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final track = _audio.currentTrack!;
    return GestureDetector(
      onTap: _openPlayer,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: SColors.surface,
          border: Border(
            top: BorderSide(color: SColors.pulse.withOpacity(0.25), width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: track.coverUrl != null
                    ? Image.network(
                        track.coverUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _miniCoverPlaceholder(),
                      )
                    : _miniCoverPlaceholder(),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                        color: SColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artistName ?? 'Unknown artist',
                      style: const TextStyle(
                          color: SColors.textHint, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play/pause
              GestureDetector(
                onTap: _audio.togglePlayPause,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: AnimatedSwitcher(
                    duration: SDurations.fast,
                    child: Icon(
                      _audio.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey(_audio.isPlaying),
                      color: SColors.pulse,
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Skip next
              GestureDetector(
                onTap: _audio.playNext,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  child: Icon(Icons.skip_next_rounded,
                      color: SColors.textHint, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCoverPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [SColors.pulseDeep, SColors.pulse],
        ),
      ),
      child: const Icon(Icons.music_note_rounded,
          color: Colors.white38, size: 18),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 60 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: SColors.void_bg,
        border: Border(
          top: BorderSide(
              color: Colors.white.withOpacity(0.06), width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: _tab, onTap: (i) => setState(() => _tab = i)),
            _NavItem(icon: Icons.search_rounded, label: 'Search', index: 1, current: _tab, onTap: (i) => setState(() => _tab = i)),
            _NavItem(icon: Icons.mic_rounded, label: 'Artists', index: 2, current: _tab, onTap: (i) => setState(() => _tab = i)),
            _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 3, current: _tab, onTap: (i) => setState(() => _tab = i)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: SDurations.normal,
              curve: SCurves.settle,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? SColors.pulse.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: SRadius.full,
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? SColors.pulse : SColors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: SDurations.fast,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? SColors.pulse : SColors.textHint,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
