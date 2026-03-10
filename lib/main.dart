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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE53935),
          secondary: const Color(0xFFE53935),
          surface: const Color(0xFF1C1C1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161618),
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(color: Color(0xFF1C1C1E)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
          ),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF161618)),
        dividerTheme: const DividerThemeData(color: Color(0xFF2C2C2E)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
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
