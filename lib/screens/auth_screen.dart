import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignUp) {
        final res = await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
        if (res.user != null) {
          await supabase.from('users').insert({
            'id': res.user!.id,
            'email': _email.text.trim(),
            'display_name': _displayName.text.trim(),
          });
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.void_bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo
              const Text('soundscape', style: STextStyles.display),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: STextStyles.body,
              ),

              const SizedBox(height: 48),

              // Fields
              if (_isSignUp) ...[
                _label('Display name'),
                TextField(
                  controller: _displayName,
                  style: const TextStyle(color: SColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'How should we call you?'),
                ),
                const SizedBox(height: 16),
              ],

              _label('Email'),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: SColors.textPrimary),
                decoration: const InputDecoration(hintText: 'your@email.com'),
              ),
              const SizedBox(height: 16),

              _label('Password'),
              TextField(
                controller: _password,
                obscureText: true,
                style: const TextStyle(color: SColors.textPrimary),
                decoration: const InputDecoration(hintText: '••••••••'),
              ),

              const SizedBox(height: 28),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SColors.danger.withOpacity(0.1),
                    borderRadius: SRadius.md,
                    border: Border.all(color: SColors.danger.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: SColors.danger, fontSize: 13)),
                ),
                const SizedBox(height: 20),
              ],

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Create account' : 'Sign in'),
                ),
              ),

              const SizedBox(height: 20),

              // Toggle sign in / sign up
              Center(
                child: TextButton(
                  onPressed: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                    style: const TextStyle(
                      color: SColors.pulse,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: STextStyles.body),
    );
  }
}
