import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signIn(
        '${username.toLowerCase()}@gymbro.app',
        password,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: Colors.red[400],
          ),
        );
      }
      setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final appUser = await ref.read(userServiceProvider).getUserOnce(uid);
    if (!mounted) return;

    // Refresh profile image URL so token is always valid after re-upload.
    ref.read(userServiceProvider).refreshProfileImageUrl(uid);

    if (appUser == null || !appUser.profileComplete) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains('user-not-found') || msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Invalid username or password';
    }
    if (msg.contains('network')) return 'Network error, try again';
    return 'Login failed, please try again';
  }

  static const _logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/gymbro-f4ff7.firebasestorage.app/o/Screenshot%202026-03-11%20134028.png?alt=media&token=57485e66-36dc-4bca-9ea1-bb5aad4265fa';

  static const _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide.none,
  );

  static const _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: Color(0xFFE53935), width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    final loading = _loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: _logoUrl,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox(
                            width: 96,
                            height: 96,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFE53935), strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1C1C1E),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Color(0xFFE53935),
                              size: 52,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'GymBro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username
                  TextField(
                    controller: _usernameCtrl,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Color(0xFF9E9E9E)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      border: _inputBorder,
                      enabledBorder: _inputBorder,
                      focusedBorder: _focusedBorder,
                      labelStyle:
                          const TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Color(0xFF9E9E9E)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF9E9E9E),
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      border: _inputBorder,
                      enabledBorder: _inputBorder,
                      focusedBorder: _focusedBorder,
                      labelStyle:
                          const TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign In button
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withAlpha(80),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
