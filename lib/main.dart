import 'package:flutter/material.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'core/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();
  final initialRoute = await storage.isRegistered() ? '/home' : '/';
  runApp(QalbuKidsApp(initialRoute: initialRoute));
}

class QalbuKidsApp extends StatelessWidget {
  final String initialRoute;
  const QalbuKidsApp({super.key, this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QalbuKids',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      initialRoute: initialRoute,
      routes: {
        '/': (_) => const ProfileSetupScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
