import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: "환영합니다!",
      description: "여행의 모든 순간, '얼마야?'와 함께\n정확하고 편리하게 기록하세요.",
      imagePath: 'assets/images/howmuch-icon_600.png',
      isIcon: true,
    ),
    OnboardingSlide(
      title: "실시간 환율 계산",
      description: "키패드, 음성, 카메라로 가장 빠르고\n정확하게 계산해 드립니다.\n쇼핑헬퍼로 통역기능도 활용해 보세요.",
      icon: CupertinoIcons.money_dollar_circle,
    ),
    OnboardingSlide(
      title: "편리한 1/N 정산",
      description: "원화뿐만 아니라 외화도 가능하고\n총무뽀찌도 챙겨보세요!",
      icon: CupertinoIcons.person_2_fill,
    ),
    OnboardingSlide(
      title: "똑똑한 여계부",
      description: "지출 내역부터 영수증 보관까지\n리포트를 친구들과 공유해보세요.",
      icon: CupertinoIcons.doc_text_fill,
    ),
    OnboardingSlide(
      title: "즐겨찾기 국가 설정",
      description:
          "앱 시작 후 설정에서 즐겨찾기 국가를 꼭 설정해보세요.\n모든 기능이 즐겨찾기 국가로 관리되어\n더욱 편리하게 활용할 수 있습니다.",
      icon: CupertinoIcons.heart_circle_fill,
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding_v1', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // PageView
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildStandardSlide(_slides[index], isDark);
              },
            ),

            // Top-right Skip Button
            Positioned(
              top: 10,
              right: 10,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  "건너뛰기",
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Bottom UI
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : (isDark ? Colors.white12 : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Premium Pill Button
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: AppDesign.primaryGradientDecoration(isDark),
                      alignment: Alignment.center,
                      child: Text(
                        _currentPage == _slides.length - 1 ? "시작하기" : "다음",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardSlide(OnboardingSlide slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic Area
          if (slide.isIcon)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(slide.imagePath!, fit: BoxFit.cover),
              ),
            )
          else if (slide.icon != null)
            Icon(slide.icon, size: 100, color: AppColors.primary),
          const SizedBox(height: 60),

          // Text Area
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.grey[600],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 100), // Space for bottom UI
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final String? imagePath;
  final IconData? icon;
  final bool isIcon;
  final bool isLast;

  OnboardingSlide({
    required this.title,
    required this.description,
    this.imagePath,
    this.icon,
    this.isIcon = false,
    this.isLast = false,
  });
}
