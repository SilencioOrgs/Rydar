import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/auth_service.dart';

class RydarApp extends StatelessWidget {
  const RydarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rydar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AuthGate(),
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        LeaderboardScreen.routeName: (_) => const LeaderboardScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null
            ? const SplashScreen()
            : const HomeScreen();
      },
    );
  }
}
