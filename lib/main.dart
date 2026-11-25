import 'package:flutter/material.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QalbuKidsApp());
}

class QalbuKidsApp extends StatelessWidget {
  const QalbuKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QalbuKids',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (_) => const ProfileSetupScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
