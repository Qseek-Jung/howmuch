import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'how_much_screen.dart';
import 'package:exchange_flutter/features/ledger/presentation/ledger_home_screen.dart';

import 'split/split_home_screen.dart';
import '../features/exchange_rate/presentation/exchange_rate_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const HowMuchScreen(),
    const SplitHomeScreen(),
    const LedgerHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? Colors.black : Colors.white,
      resizeToAvoidBottomInset: false,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed AdMob Banner (Top)
            Container(
              height: 50,
              width: double.infinity,
              color: isDark
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFFF3F4F6), // Slight difference from white
              alignment: Alignment.center,
              child: const Text(
                "AdMob Test Banner",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),

            // 2. Expanded Content Area
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),

            // 3. Bottom Toolbar (Strict Minimal Mode)
            Container(
              height: 56, // Fixed height per specs (48-56)
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolbarItem(
                    3, // Index 3 for Menu
                    Icons.menu,
                    "메뉴",
                  ),
                  _buildToolbarItem(
                    0,
                    Icons.calculate_outlined,
                    "얼마야",
                  ), // Using Calculate for "How Much" calculator feel
                  _buildToolbarItem(1, Icons.people_outline, "1/N"),
                  _buildToolbarItem(2, Icons.receipt_long_outlined, "여계부"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A237E).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.infinite,
                    color: Colors.white,
                    size: 32,
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
                    icon: CupertinoIcons.clock_fill,
                    title: '최근 계산 기록',
                    subtitle: '이전 환산 결과 확인',
                    onTap: () {},
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
                    onTap: () {},
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
          color: isDark ? Colors.white : const Color(0xFF1A237E),
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

  Widget _buildToolbarItem(int index, IconData icon, String label) {
    // Determine Color
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? Colors.white : const Color(0xFF1A237E))
        : const Color(0xFF6B7280);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 3) {
            // Menu Logic
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => _currentIndex = index);
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
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87)
                  : color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: index == 3
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87)
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
}
