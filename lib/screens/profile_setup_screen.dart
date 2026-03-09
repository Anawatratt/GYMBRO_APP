import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _gymCtrl = TextEditingController(text: 'CMU Gym');
  String _fitnessLevel = 'beginner';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill display name from auth
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null) {
      _nameCtrl.text = user!.displayName!;
    }
    // Or get from Firestore doc that was newly created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appUser = ref.read(currentUserDocProvider).value;
      if (appUser != null && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = appUser.displayName;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _gymCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required.'), backgroundColor: Colors.red),
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(userServiceProvider).completeProfile(
            uid: uid,
            displayName: name,
            fitnessLevel: _fitnessLevel,
            bio: _bioCtrl.text.trim(),
            gymName: _gymCtrl.text.trim(),
          );
      // The AuthGate will detect profileComplete = true and navigate to Home
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF283593), Color(0xFF5C6BC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),
              const Text("Let's set up your profile!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 6),
              Text('Help us personalize your GymBro experience.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15)),
              const SizedBox(height: 36),

              _label('Display Name *'),
              const SizedBox(height: 8),
              _textField(controller: _nameCtrl, hint: 'e.g. JJ', icon: Icons.person_outline),
              const SizedBox(height: 24),

              _label('Fitness Level *'),
              const SizedBox(height: 12),
              Row(
                children: ['beginner', 'intermediate', 'advanced'].map((level) {
                  final selected = _fitnessLevel == level;
                  final colors = {
                    'beginner': const Color(0xFF4CAF50),
                    'intermediate': const Color(0xFFFF9800),
                    'advanced': const Color(0xFFE53935),
                  };
                  final color = colors[level]!;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _fitnessLevel = level),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? color : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? color : Colors.grey.withAlpha(40),
                              width: selected ? 0 : 1,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: color.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: Column(
                            children: [
                              Text(
                                level[0].toUpperCase() + level.substring(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: selected ? Colors.white : Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              _label('Bio (optional)'),
              const SizedBox(height: 8),
              _textField(controller: _bioCtrl, hint: 'Tell us about yourself...', maxLines: 3),
              const SizedBox(height: 24),

              _label('Gym Name (optional)'),
              const SizedBox(height: 8),
              _textField(controller: _gymCtrl, hint: 'CMU Gym', icon: Icons.location_on_outlined),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E)));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400], size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}
