import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/storage_service.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _backgroundColor = Color(0xFFE6F5EE);

  final StorageService _storage = StorageService();
  late final AnimationController _entryController;
  late final AnimationController _floatController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _textRevealAnimation;
  late final Animation<double> _floatAnimation;
  Timer? _navigationTimer;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _textRevealAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.38, 0.92, curve: Curves.easeInOutCubic),
    );
    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _floatController.repeat(reverse: true);
    _navigationTimer = Timer(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    final registered = await _storage.isRegistered();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            registered ? const HomeScreen() : const ProfileSetupScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width * 0.55;
    final logoHeight = logoWidth * 420 / 594;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              ),
              child: SizedBox(
                width: logoWidth,
                height: logoHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/logo_qalbukids.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: logoHeight * 0.60,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedBuilder(
                        key: const ValueKey('splash-text-reveal'),
                        animation: _textRevealAnimation,
                        builder: (context, child) => ClipRect(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: 1 - _textRevealAnimation.value,
                              child: child,
                            ),
                          ),
                        ),
                        child: const ColoredBox(color: _backgroundColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
