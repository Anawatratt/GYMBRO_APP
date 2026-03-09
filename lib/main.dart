import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'app_state.dart';
import 'seed.dart';

import 'screens/friends_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/search_screen.dart';
import 'screens/plan_list_screen.dart';
import 'screens/plan_detail_screen.dart';
import 'screens/custom_plan_screen.dart';
import 'screens/progress_analytics_screen.dart';
import 'screens/progress_breakdown_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/friend_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await seedAll();
  runApp(const ProviderScope(child: GymbroApp()));
}

class GymbroApp extends StatelessWidget {
  const GymbroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gymbro',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE53935),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E), fontSize: 20, fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login':              (c) => const LoginScreen(),
        '/register':           (c) => const RegisterScreen(),
        '/home':               (c) => const HomeScreen(),
        '/search':             (c) => const SearchScreen(),
        '/plans':              (c) => const PlanListScreen(),
        '/planDetail':         (c) => const PlanDetailScreen(),
        '/customPlan':         (c) => const CustomPlanScreen(),
        '/progressAnalytics':  (c) => const ProgressAnalyticsScreen(),
        '/progressBreakdown':  (c) => const ProgressBreakdownScreen(),
        '/notes':              (c) => const NotesScreen(),
        '/workoutHistory':     (c) => const WorkoutHistoryScreen(),
        '/friendProfile':      (c) => const FriendProfileScreen(),
        '/friends':            (c) => const FriendsScreen(),
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (firebaseUser) {
        if (firebaseUser == null) return const LoginScreen();
        final userDoc = ref.watch(currentUserDocProvider);
        return userDoc.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const HomeScreen(),
          data: (appUser) {
            if (appUser == null || !appUser.profileComplete) return const ProfileSetupScreen();
            return const HomeScreen();
          },
        );
      },
    );
  }
}
