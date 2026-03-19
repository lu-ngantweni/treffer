import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soundscape/main.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      if (mounted) setState(() { _profile = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.void_bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: SColors.void_bg,
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text('Profile', style: STextStyles.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: SColors.textHint, size: 20),
                onPressed: _signOut,
                tooltip: 'Sign out',
              ),
            ],
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
          else
            SliverToBoxAdapter(child: _buildProfile()),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final profile = _profile;
    final user = supabase.auth.currentUser;
    final name = profile?['display_name'] as String? ?? 'Listener';
    final bio = profile?['bio'] as String?;
    final avatarUrl = profile?['avatar_url'] as String?;
    final tags = List<String>.from(profile?['region_tags'] ?? []);
    final email = user?.email ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SColors.pulseDeep, SColors.pulse],
              ),
              border: Border.all(color: SColors.pulse.withOpacity(0.3), width: 2),
            ),
            child: avatarUrl != null
                ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          Text(name, style: STextStyles.title),
          const SizedBox(height: 4),
          Text(email, style: STextStyles.body),

          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: STextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],

          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: tags.map((t) => STag(label: t)).toList(),
            ),
          ],

          const SizedBox(height: 32),

          // Stats row
          _buildStatsRow(),

          const SizedBox(height: 32),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 24),

          // Settings list
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () {}, // future
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'About Soundscape',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SColors.textSecondary,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: SRadius.md),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        supabase
            .from('follows')
            .select('follower_id')
            .eq('following_id', supabase.auth.currentUser!.id),
        supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', supabase.auth.currentUser!.id),
      ]),
      builder: (context, snap) {
        final followers = (snap.data?[0] as List?)?.length ?? 0;
        final following = (snap.data?[1] as List?)?.length ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatBlock(value: followers.toString(), label: 'Followers'),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.white.withOpacity(0.1),
            ),
            _StatBlock(value: following.toString(), label: 'Following'),
          ],
        );
      },
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 2),
        Text(label, style: STextStyles.caption),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: SRadius.md,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: SColors.textHint, size: 20),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: STextStyles.subtitle)),
              const Icon(Icons.chevron_right_rounded, color: SColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
