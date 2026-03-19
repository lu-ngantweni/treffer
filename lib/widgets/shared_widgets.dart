import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// Cover art with placeholder
// ─────────────────────────────────────────────

class SCoverArt extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? radius;

  const SCoverArt({
    super.key,
    this.imageUrl,
    required this.size,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final br = radius ?? SRadius.sm;
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
                placeholder: (_, __) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SColors.pulseDeep, SColors.pulse],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white.withOpacity(0.4),
        size: size * 0.4,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Genre / region tag chip
// ─────────────────────────────────────────────

class STag extends StatelessWidget {
  final String label;
  const STag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SColors.pulse.withOpacity(0.15),
        borderRadius: SRadius.full,
        border: Border.all(color: SColors.pulse.withOpacity(0.25), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SColors.pulseGlow,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────

class SSectionHeader extends StatelessWidget {
  final String title;
  const SSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(title, style: STextStyles.subtitle),
    );
  }
}

// ─────────────────────────────────────────────
// Animated follow button
// ─────────────────────────────────────────────

class SFollowButton extends StatefulWidget {
  final bool isFollowing;
  final bool loading;
  final VoidCallback onTap;

  const SFollowButton({
    super.key,
    required this.isFollowing,
    required this.loading,
    required this.onTap,
  });

  @override
  State<SFollowButton> createState() => _SFollowButtonState();
}

class _SFollowButtonState extends State<SFollowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: SCurves.spring),
    );
  }

  @override
  void didUpdateWidget(SFollowButton old) {
    super.didUpdateWidget(old);
    if (old.isFollowing != widget.isFollowing) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: SDurations.normal,
        curve: SCurves.settle,
        decoration: BoxDecoration(
          color: widget.isFollowing ? Colors.transparent : SColors.pulse,
          border: Border.all(
            color: widget.isFollowing
                ? Colors.white.withOpacity(0.3)
                : SColors.pulse,
            width: 1.5,
          ),
          borderRadius: SRadius.full,
        ),
        child: InkWell(
          onTap: widget.loading ? null : widget.onTap,
          borderRadius: SRadius.full,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            child: widget.loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SColors.textSecondary,
                    ),
                  )
                : AnimatedSwitcher(
                    duration: SDurations.fast,
                    child: Text(
                      widget.isFollowing ? 'Following' : 'Follow',
                      key: ValueKey(widget.isFollowing),
                      style: TextStyle(
                        color: widget.isFollowing
                            ? SColors.textSecondary
                            : SColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error state widget
// ─────────────────────────────────────────────

class SErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: SColors.danger.withOpacity(0.1),
                borderRadius: SRadius.full,
                border: Border.all(
                    color: SColors.danger.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: SColors.danger, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style: STextStyles.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: STextStyles.body,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 28),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Mini player bar — persistent bottom strip
// ─────────────────────────────────────────────

class SMiniPlayer extends StatelessWidget {
  final dynamic track; // Track
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;

  const SMiniPlayer({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    required this.onTogglePlay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: SColors.surface,
          border: Border(
            top: BorderSide(
                color: SColors.pulse.withOpacity(0.25), width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SCoverArt(imageUrl: track.coverUrl, size: 40, radius: SRadius.xs),
              const SizedBox(width: 12),
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
                      style: STextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _MiniBtn(
                icon: isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: SColors.pulse,
                size: 28,
                onTap: onTogglePlay,
              ),
              _MiniBtn(
                icon: Icons.skip_next_rounded,
                color: SColors.textHint,
                size: 24,
                onTap: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
