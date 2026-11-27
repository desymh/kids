import 'package:flutter/material.dart';
import 'core/storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();
  runApp(const QalbuKidsApp());
}

class QalbuKidsApp extends StatelessWidget {
  final String? initialRoute;
  const QalbuKidsApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QalbuKids',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      initialRoute: initialRoute,
      home: initialRoute == null ? const SplashScreen() : null,
      routes: {
        if (initialRoute != null) '/': (_) => const ProfileSetupScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
