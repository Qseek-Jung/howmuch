import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';
import '../services/remote_config_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start minimum timer
    final minSplashDuration = Future.delayed(const Duration(seconds: 3));

    // Fetch global settings (ads, etc.)
    final configFetch = RemoteConfigService.instance.fetchSettings();

    // Wait for both
    await Future.wait([minSplashDuration, configFetch]);

    // Check if onboarding was already seen
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding_v1') ?? false;

    if (mounted) {
      if (seenOnboarding) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/howmuch-icon_600.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Big Title
                  const Text(
                    "얼마야?",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C2C2E),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Multi-language translations
                  _buildTranslation("How much?", 1.0, 18, FontWeight.w600),
                  const SizedBox(height: 10),
                  _buildTranslation("いくらですか？", 0.75, 17, FontWeight.w500),
                  const SizedBox(height: 10),
                  _buildTranslation("多少钱?", 0.55, 16, FontWeight.w400),
                  const SizedBox(height: 10),
                  _buildTranslation("Bao nhiêu?", 0.35, 15, FontWeight.w400),
                  const SizedBox(height: 10),
                  _buildTranslation("เท่าไหร่?", 0.2, 14, FontWeight.w400),
                  const SizedBox(height: 10),
                  _buildTranslation(
                    "¿Cuánto cuesta?",
                    0.08,
                    13,
                    FontWeight.w400,
                  ),
                ],
              ),
            ),

            // Footer
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Powered by Q",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslation(
    String text,
    double opacity,
    double size,
    FontWeight weight,
  ) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        color: const Color(0xFF2C2C2E).withValues(alpha: opacity),
        fontWeight: weight,
      ),
    );
  }
}
