import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';

class RydarApp extends StatelessWidget {
  const RydarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rydar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        LeaderboardScreen.routeName: (_) => const LeaderboardScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
      initialRoute: SplashScreen.routeName,
    );
  }
}
