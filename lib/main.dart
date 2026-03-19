import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const SoundscapeApp());
}

final supabase = Supabase.instance.client;

class SoundscapeApp extends StatelessWidget {
  const SoundscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soundscape',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootRouter(),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.session != null) {
          return const AppShell();
        }
        return const AuthScreen();
      },
    );
  }
}
