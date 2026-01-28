import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'home/currency_provider.dart';
import '../data/models/currency_model.dart';
import '../core/currency_data.dart';
import '../core/amount_recognizer.dart';
import '../core/stt_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shopping_helper_mode.dart';

class HowMuchScreen extends ConsumerStatefulWidget {
  const HowMuchScreen({super.key});

  @override
  ConsumerState<HowMuchScreen> createState() => _HowMuchScreenState();
}

class _HowMuchScreenState extends ConsumerState<HowMuchScreen>
    with TickerProviderStateMixin {
  String _inputAmount = "0";
  bool _isReverseCalculation = false;
  // Page Navigation
  late final PageController _pageController;
  int _currentPage = 1; // Default to Keypad (index 1)
  bool _showOnboarding = false;
  Timer? _hideOnboardingTimer;
  late AnimationController _fingerAnimationController;

  // Speech
  final SttPttController _sttController =
      SttPttController(); // Changed controller type
  String _voiceError = "";
  bool _isVoicePressed = false;
  bool _isSttLoading = false; // Added loading state

  // Calculator
  Timer? _debounceTimer;
  int _tipPercentage = 10; // Default tip

  final Color _primaryColor = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    print("HowMuchScreen: initState");
    _pageController = PageController(initialPage: 1);

    _fingerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fingerAnimationController.repeat(reverse: true);

    // Listen for user swipes to hide onboarding immediately
    // _pageController.addListener(_onPageControllerChange);

    _sttController.init();
    _loadTipPercentage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  Future<void> _checkOnboarding() async {
    // User Request: Always show Onboarding on launch
    if (true) {
      if (!mounted) return;
      setState(() {
        _showOnboarding = true;
      });

      Future.delayed(const Duration(milliseconds: 200), () async {
        // Wait for PageController to have clients
        int retries = 0;
        while ((!_pageController.hasClients) && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }

        if (!mounted || !_pageController.hasClients || !_showOnboarding) {
          // If still no clients after retry, just hide onboarding
          if (mounted && _showOnboarding) {
            setState(() => _showOnboarding = false);
          }
          return;
        }
        final width = MediaQuery.of(context).size.width;

        try {
          // 1. Peek Left (width * 0.7) - Finger moves Right
          await _pageController.position.animateTo(
            width * 0.7,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          if (!mounted || !_showOnboarding) return;

          // 2. Peek Right (width * 1.3) - Finger moves Left
          await _pageController.position.animateTo(
            width * 1.3,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          if (!mounted || !_showOnboarding) return;

          // 3. Back to Center - Finger moves Right
          await _pageController.position.animateTo(
            width,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );

          // 5. Disappear immediately after sequence
          if (mounted && _showOnboarding) {
            setState(() => _showOnboarding = false);
          }
        } catch (e) {
          // Animation interrupted (user swiped)
          if (mounted && _showOnboarding) {
            setState(() => _showOnboarding = false);
          }
          print("Onboarding animation interrupted: $e");
        }
      });
    }
  }

  Future<void> _loadTipPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tipPercentage = prefs.getInt('tip_percentage') ?? 10;
    });
  }

  Future<void> _saveTipPercentage(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tip_percentage', val);
  }

  String? _lastCurrencyCode;

  void _checkAndSyncTip(String code) {
    if (_lastCurrencyCode == code) return;
    _lastCurrencyCode = code;
    _updateTipForCurrency(code);
  }

  void _updateTipForCurrency(String code) {
    final defaultTip = CurrencyData.getDefaultTip(code);
    setState(() {
      _tipPercentage = defaultTip;
    });
    _saveTipPercentage(defaultTip);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideOnboardingTimer?.cancel();
    // _pageController.removeListener(_onPageControllerChange); // Listener removed
    _pageController.dispose();
    _fingerAnimationController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    _debounceTimer?.cancel();

    setState(() {
      if (key == 'C') {
        _inputAmount = "0";
        return;
      }

      if (key == '⌫') {
        if (_inputAmount.length > 1) {
          _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
        } else {
          _inputAmount = "0";
        }
        _startAutoEvaluateTimer();
        return;
      }

      if (key == '=') {
        _evaluateImmediately();
        return;
      }

      final operators = ['+', '-', 'x', '/', '*'];
      final isLastOperator =
          _inputAmount.isNotEmpty &&
          operators.contains(_inputAmount[_inputAmount.length - 1]);

      if (operators.contains(key)) {
        if (_inputAmount == "0") return; // Cannot start with operator
        if (isLastOperator) {
          // Replace last operator
          _inputAmount =
              _inputAmount.substring(0, _inputAmount.length - 1) + key;
        } else {
          // Evaluate current if any, then append
          _evaluateImmediately(keepOperator: key);
        }
        return;
      }

      // Digits and Dot
      if (key == '000') {
        if (_inputAmount == "0" || isLastOperator) {
          _inputAmount = (_inputAmount == "0" ? "" : _inputAmount) + "1000";
        } else {
          _inputAmount += "000";
        }
      } else if (_inputAmount == "0" && key != '.') {
        _inputAmount = key;
      } else {
        // Prevent multiple dots in same segment
        if (key == '.') {
          final segments = _inputAmount.split(RegExp(r'[+\-x/]'));
          if (segments.last.contains('.')) return;
        }
        _inputAmount += key;
      }
    });

    _startAutoEvaluateTimer();
  }

  void _startAutoEvaluateTimer() {
    _debounceTimer?.cancel();
    // Only set timer if there's an operator and a second operand
    final hasOperator = _inputAmount.contains(RegExp(r'[+\-x/]'));
    if (!hasOperator) return;

    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _evaluateImmediately();
    });
  }

  void _evaluateImmediately({String? keepOperator}) {
    _debounceTimer?.cancel();
    final result = _calculateExpression(_inputAmount);
    setState(() {
      // Format to avoid extra .0
      String resStr = result.toString().replaceAll(RegExp(r'\.0$'), '');
      if (keepOperator != null) {
        _inputAmount = resStr + keepOperator;
      } else {
        _inputAmount = resStr;
      }
    });
  }

  double _calculateExpression(String expr) {
    try {
      // Basic sequential evaluation: 35+25-10 => (35+25)-10
      // Find the first operator and its position
      final match = RegExp(r'([+\-x/])').firstMatch(expr);
      if (match == null) return double.tryParse(expr) ?? 0;

      final op = match.group(0)!;
      final parts = expr.split(op);
      if (parts.length < 2 || parts[1].isEmpty)
        return double.tryParse(parts[0]) ?? 0;

      double left = double.tryParse(parts[0]) ?? 0;
      double right = double.tryParse(parts[1]) ?? 0;

      double res = 0;
      switch (op) {
        case '+':
          res = left + right;
          break;
        case '-':
          res = left - right;
          break;
        case 'x':
        case '*':
          res = left * right;
          break;
        case '/':
          res = right != 0 ? left / right : 0;
          break;
      }
      return res;
    } catch (_) {
      return 0;
    }
  }

  void _applyTip() {
    _evaluateImmediately(); // Ensure expression is solved first
    double? amt = double.tryParse(_inputAmount.replaceAll(',', ''));
    if (amt != null) {
      double result = amt * (1 + _tipPercentage / 100);
      setState(() {
        _inputAmount = result
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.00$'), '');
      });
    }
  }

  void _showTipPicker() {
    int tempIndex = _tipPercentage;
    if (tempIndex < 0) tempIndex = 0;
    if (tempIndex > 30) tempIndex = 30;

    final tipOptions = List.generate(31, (i) => i); // 0, 1, 2, ..., 30

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text(
                      "취소",
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "팁(Tip) 설정",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text(
                      "확인",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      final selected = tipOptions[tempIndex];
                      setState(() => _tipPercentage = selected);
                      _saveTipPercentage(selected);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: tempIndex,
                ),
                itemExtent: 44,
                backgroundColor: Colors.white,
                onSelectedItemChanged: (index) => tempIndex = index,
                children: tipOptions
                    .map(
                      (p) => Center(
                        child: Text(
                          "$p%",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDisplay(String value, {bool isKrw = false}) {
    if (value.isEmpty || value == "0") return "0";

    // If it's an expression (contains operator), don't format with commas normally, just return as is
    if (value.contains(RegExp(r'[+\-x/]'))) return value;

    if (isKrw) {
      double? amt = double.tryParse(value.replaceAll(',', ''));
      if (amt == null) return "0";
      return NumberFormat('#,###').format(amt.toInt());
    }
    if (value.contains('.')) {
      final parts = value.split('.');
      final formattedInt = NumberFormat(
        '#,###',
      ).format(int.tryParse(parts[0]) ?? 0);
      return "$formattedInt.${parts[1]}";
    }
    return NumberFormat('#,###').format(double.tryParse(value) ?? 0);
  }

  String _calculateResult(double rate) {
    // For conversion, evaluate the expression first to get the numeric value
    double inputVal = _calculateExpression(_inputAmount);

    double res = _isReverseCalculation ? inputVal / rate : inputVal * rate;
    if (_isReverseCalculation) {
      return _formatDisplay(res.toStringAsFixed(2));
    } else {
      return _formatDisplay(res.toStringAsFixed(0), isKrw: true);
    }
  }

  void _showCurrencyPicker(List<Currency> favorites) {
    if (favorites.isEmpty) return;
    int tempIndex = 0;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text(
                      "취소",
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "통화 선택",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text(
                      "확인",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      final selected = favorites[tempIndex];
                      ref
                          .read(favoriteCurrenciesProvider.notifier)
                          .moveToTop(selected.code);
                      _updateTipForCurrency(selected.code);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                backgroundColor: Colors.white,
                onSelectedItemChanged: (index) => tempIndex = index,
                children: favorites
                    .map(
                      (c) => Center(
                        child: Text(
                          "${c.name} (${c.code})",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyList = ref.watch(currencyListProvider);
    final favoriteCodes = ref.watch(favoriteCurrenciesProvider);

    return currencyList.when(
      data: (currencies) {
        final favorites = favoriteCodes.map((code) {
          return currencies.firstWhere(
            (c) => c.code == code,
            orElse: () => Currency(
              code: code,
              rateToKrw: 0,
              name: CurrencyData.getCountryName(code),
              updatedAt: DateTime.now(),
            ),
          );
        }).toList();

        if (favorites.isEmpty)
          return const Center(child: Text("Favorite is empty"));
        final currentCurrency = favorites[0];

        // Sync tip rate if currency changed from external source (e.g. Provider)
        // or on first build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndSyncTip(currentCurrency.code);
        });

        return Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                _buildDisplayArea(currentCurrency, favorites),
                _buildInteractionNav(),
                Expanded(child: _buildInteractionArea(currentCurrency.code)),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildOnboardingGuide() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(
            0.35,
          ), // Dimmer background only on keypad
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Swipe Hand Animation linked to PageController
                AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double offset = 0;
                    try {
                      if (_pageController.hasClients &&
                          _pageController.position.hasContentDimensions) {
                        final width = MediaQuery.of(context).size.width;
                        offset = (width - _pageController.offset);
                      }
                    } catch (_) {
                      offset = 0;
                    }
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.swipe,
                            color: Colors.white.withOpacity(0.95),
                            size: 80,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Text(
                    "좌우로 밀어서 모드 전환!",
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A237E),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(height: 16), // MainScaffold handles AppBar-like space
    );
  }

  Widget _buildDisplayArea(Currency target, List<Currency> favorites) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              _displayRowHorizontal(
                label: _isReverseCalculation ? "대한민국" : target.name,
                code: _isReverseCalculation ? "KRW" : target.code,
                value: _formatDisplay(
                  _inputAmount,
                  isKrw: _isReverseCalculation,
                ),
                isBase: true,
                onTap: _isReverseCalculation
                    ? null
                    : () => _showCurrencyPicker(favorites),
              ),
              const SizedBox(height: 8),
              _displayRowHorizontal(
                label: _isReverseCalculation ? target.name : "대한민국",
                code: _isReverseCalculation ? target.code : "KRW",
                value: _calculateResult(target.rateToKrw),
                isBase: false,
                onTap: _isReverseCalculation
                    ? () => _showCurrencyPicker(favorites)
                    : null,
              ),
            ],
          ),
          Positioned(
            child: GestureDetector(
              onTap: () => setState(
                () => _isReverseCalculation = !_isReverseCalculation,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[100]!,
                  ),
                ),
                child: Icon(
                  Icons.swap_vert,
                  color: isDark ? Colors.white70 : Colors.grey,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayRowHorizontal({
    required String label,
    required String code,
    required String value,
    required bool isBase,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                        size: 14,
                      ),
                  ],
                ),
                Text(
                  code,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerRight,
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: isBase
                        ? (isDark ? Colors.blue[300] : _primaryColor)
                        : (isDark ? Colors.white : Colors.black87),
                    letterSpacing: -1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionArea(String currencyCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (_showOnboarding) {
              print("User swipe detected! Hiding onboarding.");
              _hideOnboardingTimer?.cancel();
              setState(() => _showOnboarding = false);
              SharedPreferences.getInstance().then((prefs) {
                prefs.setBool('seen_swipe_onboarding_v8', true);
              });
            }
            return false;
          },
          child: PageView(
            controller: _pageController,
            physics: _isVoicePressed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              const Center(child: Text("Scan Mode Coming Soon")),
              Container(
                color: isDark ? Colors.transparent : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: _buildKeypad(),
              ),
              _buildVoiceMode(),
              ShoppingHelperMode(currencyCode: currencyCode),
            ],
          ),
        ),
        if (_showOnboarding) _buildOnboardingGuide(),
      ],
    );
  }

  Widget _buildInteractionNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 36, // Height shrunk per user request
      margin: const EdgeInsets.symmetric(
        horizontal: 50,
        vertical: 8,
      ), // More compact horizontally
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navBtn(Icons.camera_alt, 0),
          _navBtn(Icons.grid_view, 1),
          _navBtn(Icons.mic, 2),
          _navBtn(Icons.record_voice_over, 3), // Shopping Helper
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool active = (_currentPage % 4) == index;
    return InkWell(
      onTap: () {
        setState(() => _inputAmount = "0");
        _pageController.animateToPage(
          _currentPage + (index - (_currentPage % 4)),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: active
              ? (isDark ? Colors.blue[300] : _primaryColor)
              : Colors.grey[500],
          size: 16, // Icon size shrunk per user request
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildKey('/'),
              _buildTipButton(),
              _buildKey('C'),
              _buildKey('⌫'),
            ],
          ),
        ),
        _keyRow(['*', '7', '8', '9']),
        _keyRow(['-', '4', '5', '6']),
        _keyRow(['+', '1', '2', '3']),
        _keyRow(['=', '.', '0', '000']),
      ],
    );
  }

  Widget _keyRow(List<String> keys) {
    return Expanded(
      child: Row(children: keys.map((k) => _buildKey(k)).toList()),
    );
  }

  Widget _buildKey(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operators = ['/', 'x', '*', '-', '+', '='];
    final functions = ['C', '⌫'];
    bool isOperator = operators.contains(label);
    bool isFunction = functions.contains(label);

    Color bgColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA); // Numbers
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (isOperator) {
      bgColor = isDark ? Colors.orange[700]! : Colors.orange[400]!;
      textColor = Colors.white;
    } else if (isFunction) {
      bgColor = isDark
          ? const Color(0xFF3A3A3C)
          : const Color(0xFFD1D1D6); // Functions
      textColor = isDark ? Colors.white70 : Colors.black87;
    }

    return Expanded(
      child: InkWell(
        onTap: () => _onKeyPress(label),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, color: textColor, size: 20)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTipButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: _applyTip,
        onLongPress: _showTipPicker,
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "TIP",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              Text(
                "+$_tipPercentage%",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceMode() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "금액을 말씀해 주세요",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _isVoicePressed = true);
            _sttController.start(localeId: 'ko-KR');
          },
          onTapUp: (_) async {
            setState(() {
              _isVoicePressed = false;
              _isSttLoading = true;
            });
            await _processVoiceResult(); // Wait for result
            if (mounted) setState(() => _isSttLoading = false);
          },
          onTapCancel: () async {
            setState(() {
              _isVoicePressed = false;
              _isSttLoading = true;
            });
            // Even if cancelled (dragged out), we should process what we heard
            await _processVoiceResult();
            if (mounted) setState(() => _isSttLoading = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isVoicePressed
                  ? (isDark ? Colors.white12 : Colors.black.withOpacity(0.1))
                  : (_isSttLoading
                        ? (isDark ? Colors.white10 : Colors.grey[100])
                        : (isDark ? const Color(0xFF1C1C1E) : Colors.white)),
              border: Border.all(
                color: _isVoicePressed ? Colors.black : _primaryColor,
                width: 2,
              ),
              boxShadow: [
                if (_isVoicePressed)
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                if (!_isVoicePressed)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: _isSttLoading
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A237E),
                      ),
                    ),
                  )
                : Icon(
                    Icons.mic,
                    size: 36,
                    color: _isVoicePressed ? Colors.black : _primaryColor,
                  ),
          ),
        ),
        if (_isSttLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              "인식 중...",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          _isVoicePressed ? "듣고 있어요..." : "눌러서 말하기",
          style: TextStyle(
            color: _isVoicePressed ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
        if (_voiceError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _voiceError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Future<void> _processVoiceResult() async {
    final transcript = await _sttController.stopAndGetFinal();
    final sanitized = AmountParser.sanitize(transcript);
    final value = AmountParser.parseAmount(transcript);

    // [Debug Logs per user request]
    print("STT Final Transcript: \"$transcript\"");
    print("Sanitized Text: \"$sanitized\"");
    print("Parsed Result: $value");

    if (!mounted) return;

    if (value != null) {
      setState(() {
        _inputAmount = value.toString().replaceAll(RegExp(r'\.0$'), '');
        _voiceError = "";
      });
    } else {
      setState(
        () =>
            _voiceError = "인식 실패: \"$transcript\"\n금액만 말씀해 주세요 (예: 이천육백 / 2.6)",
      );
    }
  }
}
