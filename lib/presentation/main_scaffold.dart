import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'how_much_screen.dart';
import 'package:exchange_flutter/features/ledger/presentation/ledger_home_screen.dart';

import 'split/split_home_screen.dart';
import '../features/exchange_rate/presentation/exchange_rate_screen.dart';
import '../core/design_system.dart';
import '../services/admob_service.dart';
import '../providers/ad_settings_provider.dart';
import 'home/currency_provider.dart';
import 'widgets/global_banner_ad.dart';
import 'widgets/location_auto_selector.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const HowMuchScreen(),
    const SplitHomeScreen(),
    const LedgerHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavigationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch ad settings to trigger rebuild when ad-free mode changes
    ref.watch(adSettingsProvider);
    final shouldShowAd = ref.read(adSettingsProvider.notifier).shouldShowAd();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? Colors.black : Colors.white,
      resizeToAvoidBottomInset: false,
      drawer: _buildDrawer(context),
      body: LocationAutoSelector(
        child: SafeArea(
          child: IndexedStack(index: currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: !shouldShowAd,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolbarItem(3, Icons.menu, "메뉴", currentIndex),
                    _buildToolbarItem(
                      0,
                      Icons.calculate_outlined,
                      "얼마야",
                      currentIndex,
                    ),
                    _buildToolbarItem(
                      1,
                      Icons.people_outline,
                      "1/N",
                      currentIndex,
                    ),
                    _buildToolbarItem(
                      2,
                      Icons.receipt_long_outlined,
                      "여계부",
                      currentIndex,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Global Adaptive Banner
          const GlobalBannerAd(),
        ],
      ),
    );
  }

  // ... (buildDrawer and other methods remain unchanged or slightly updated)

  Widget _buildToolbarItem(
    int index,
    IconData icon,
    String label,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? Colors.white : AppColors.primary)
        : const Color(0xFF6B7280);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 3) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            _navigateToTab(index);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: index == 3
                  ? (isDark ? Colors.white : Colors.black87)
                  : color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: index == 3
                    ? (isDark ? Colors.white : Colors.black87)
                    : color,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    if (index == ref.read(mainNavigationProvider)) return;

    final adSettings = ref.read(adSettingsProvider.notifier);

    if (adSettings.shouldShowAd()) {
      AdMobService.instance.showInterstitialAd(
        onAdDismissed: () {
          if (mounted) {
            ref.read(mainNavigationProvider.notifier).state = index;
          }
        },
      );
    } else {
      ref.read(mainNavigationProvider.notifier).state = index;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF2F2F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Minimal & Elegant
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '얼마야?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  '스마트한 여행의 동반자',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Menu Content - iOS Inset Grouped style feel
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  _buildDrawerTile(
                    icon: CupertinoIcons.star_fill,
                    title: '즐겨찾기 관리',
                    subtitle: '주요 국가 통화 설정',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/currency_manage');
                    },
                  ),
                  _buildDrawerDivider(),
                  _buildDrawerTile(
                    icon: CupertinoIcons.graph_circle_fill,
                    title: '환율 추이',
                    subtitle: '실시간 변동 그래프',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExchangeRateScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDrawerDivider(),
                  _buildDrawerTile(
                    icon: CupertinoIcons.cart_fill,
                    title: '쇼핑헬퍼 설정',
                    subtitle: '표현 추가 및 관리',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/shopping_helper_settings');
                    },
                  ),
                  _buildDrawerDivider(),
                  _buildDrawerTile(
                    icon: CupertinoIcons.settings_solid,
                    title: '설정',
                    subtitle: '테마 및 계좌 정보 설정',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _buildDrawerDivider(),
                  _buildDrawerTile(
                    icon: CupertinoIcons.question_circle_fill,
                    title: '도움말 및 문의',
                    subtitle: '사용 방법과 피드백',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/help');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'v1.2.0 Stable Build',
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerDivider() {
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 16,
      color: Colors.black.withOpacity(0.05),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white38 : Colors.black45,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 14,
        color: isDark ? Colors.white24 : Colors.grey[400],
      ),
    );
  }
}
