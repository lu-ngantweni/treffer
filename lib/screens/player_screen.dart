import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final _audio = AudioService();
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: SDurations.slide,
      vsync: this,
    )..forward();
    _audio.addListener(_onAudio);
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _audio.removeListener(_onAudio);
    super.dispose();
  }

  Future<void> _close() async {
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final track = _audio.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _ctrl, curve: SCurves.slide)),
      child: Scaffold(
        backgroundColor: SColors.void_bg,
        body: SafeArea(
          child: Column(
            children: [
              // Drag handle + close
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _close,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: SColors.textSecondary, size: 30),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Now playing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: SColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Artwork — fills most of the screen
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: SRadius.lg,
                    child: track.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _artworkPlaceholder(),
                            errorWidget: (_, __, ___) => _artworkPlaceholder(),
                          )
                        : _artworkPlaceholder(),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Track info + like
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              color: SColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artistName ?? 'Unknown artist',
                            style: STextStyles.body,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {}, // future: like track
                      child: Icon(
                        Icons.favorite_border_rounded,
                        color: SColors.textHint,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: SColors.pulse,
                        inactiveTrackColor: SColors.elevated,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _audio.duration.inSeconds > 0
                            ? _audio.position.inSeconds
                                .toDouble()
                                .clamp(0, _audio.duration.inSeconds.toDouble())
                            : 0,
                        min: 0,
                        max: _audio.duration.inSeconds > 0
                            ? _audio.duration.inSeconds.toDouble()
                            : 1,
                        onChanged: (v) =>
                            _audio.seekTo(Duration(seconds: v.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(_audio.position), style: STextStyles.caption),
                          Text(_fmt(_audio.duration), style: STextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Shuffle (placeholder)
                    Icon(Icons.shuffle_rounded, color: SColors.textHint, size: 22),

                    // Previous
                    GestureDetector(
                      onTap: _audio.playPrevious,
                      child: const Icon(Icons.skip_previous_rounded,
                          color: SColors.textSecondary, size: 40),
                    ),

                    // Play / pause — main button
                    GestureDetector(
                      onTap: _audio.togglePlayPause,
                      child: AnimatedContainer(
                        duration: SDurations.fast,
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: SColors.pulse,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SColors.pulse.withOpacity(0.35),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: SDurations.fast,
                          child: Icon(
                            _audio.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(_audio.isPlaying),
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),

                    // Next
                    GestureDetector(
                      onTap: _audio.playNext,
                      child: const Icon(Icons.skip_next_rounded,
                          color: SColors.textSecondary, size: 40),
                    ),

                    // Repeat (placeholder)
                    Icon(Icons.repeat_rounded, color: SColors.textHint, size: 22),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SColors.pulseDeep, SColors.pulse],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded,
            color: Colors.white38, size: 80),
      ),
    );
  }
}
