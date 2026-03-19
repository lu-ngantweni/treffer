import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soundscape/main.dart';
import '../models/artist_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'artist_profile_screen.dart';

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});

  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  List<Map<String, dynamic>> _artists = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await supabase
          .from('users')
          .select('id, display_name, bio, avatar_url, region_tags')
          .eq('is_artist', true)
          .order('display_name');
      if (mounted) {
        setState(() {
          _artists = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.void_bg,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: SColors.void_bg,
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text('Artists', style: STextStyles.title),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: SColors.pulse)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: SErrorState(
                message: _error!,
                onRetry: () { setState(() { _loading = true; _error = null; }); _load(); },
              ),
            )
          else if (_artists.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No artists yet', style: STextStyles.body)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ArtistCard(artist: _artists[i]),
                  childCount: _artists.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final Map<String, dynamic> artist;
  const _ArtistCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = artist['avatar_url'] as String?;
    final name = artist['display_name'] as String? ?? 'Artist';
    final tags = List<String>.from(artist['region_tags'] ?? []);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ArtistProfileScreen(
          artistId: artist['id'] as String,
          artistName: name,
        ),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: SRadius.md,
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.5),
        ),
        child: Column(
          children: [
            // Avatar
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _avatarPlaceholder(name),
                      )
                    : _avatarPlaceholder(name),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: SColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tags.take(2).join(' · '),
                      style: const TextStyle(
                          color: SColors.textHint, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Container(
      color: SColors.pulseDeep,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
