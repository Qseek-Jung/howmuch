---
description: How to restore the "How Much" screen layout for HowMuchScreen
---

If the layout or design of `HowMuchScreen` is ruined during edits, follow these steps to restore it to the "Golden Version" saved below.

### Restoration Steps

1. Copy the code from the "Golden Version" section below.
2. Replace the entire content of `d:/Ai-APP/Flutter_APP/Exchange_for_tour/exchange_flutter/lib/presentation/how_much_screen.dart` with the copied code.
3. Run the app to verify the layout is restored.

### Golden Version (Last Updated: 2026-01-26)

```dart
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

class HowMuchScreen extends ConsumerStatefulWidget {
  const HowMuchScreen({super.key});

  @override
  ConsumerState<HowMuchScreen> createState() => _HowMuchScreenState();
}

class _HowMuchScreenState extends ConsumerState<HowMuchScreen> {
  String _inputAmount = "0";
  bool _isReverseCalculation = false;
  // Page Navigation
  late final PageController _pageController;
  int _currentPage = 1; // Default to Keypad (index 1)
  bool _showOnboarding = false;

  // Speech
  final SttPttController _sttController =
      SttPttController(); // Changed controller type
  String _voiceError = "";
  bool _isVoicePressed = false;

  // Calculator
  Timer? _debounceTimer;
  int _tipPercentage = 10; // Default tip

  final Color _primaryColor = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _sttController.init();
    _loadTipPercentage();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seen_swipe_onboarding_v2') != true) {
      setState(() => _showOnboarding = true);
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showOnboarding = false);
          prefs.setBool('seen_swipe_onboarding_v2', true);
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pageController.dispose();
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

      final operators = ['+', '-', 'x', '/'];
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
    int tempIndex = (_tipPercentage ~/ 5) - 1;
    if (tempIndex < 0) tempIndex = 0;
    if (tempIndex > 9) tempIndex = 9;

    final tipOptions = List.generate(10, (i) => (i + 1) * 5); // 5, 10, ..., 50

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

        return Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                _buildDisplayArea(currentCurrency, favorites),
                _buildInteractionNav(),
                Expanded(child: _buildInteractionArea()),
              ],
            ),
            if (_showOnboarding) _buildOnboardingGuide(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildOnboardingGuide() {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "좌우로 스와이프하여 모드 전환",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: const Icon(
                  Icons.swap_vert,
                  color: Colors.grey,
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
                    color: isBase ? _primaryColor : Colors.black87,
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

  Widget _buildInteractionArea() {
    return PageView(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentPage = i),
      children: [
        const Center(child: Text("Scan Mode Coming Soon")),
        _buildKeypad(),
        _buildVoiceMode(),
      ],
    );
  }

  Widget _buildInteractionNav() {
    return Container(
      height: 36, // Height shrunk per user request
      margin: const EdgeInsets.symmetric(
        horizontal: 50,
        vertical: 8,
      ), // More compact horizontally
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navBtn(Icons.camera_alt, 0),
          _navBtn(Icons.grid_view, 1),
          _navBtn(Icons.mic, 2),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, int index) {
    bool active = (_currentPage % 3) == index;
    return InkWell(
      onTap: () => _pageController.animateToPage(
        _currentPage + (index - (_currentPage % 3)),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: Container(
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
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
          color: active ? _primaryColor : Colors.grey[500],
          size: 16, // Icon size shrunk per user request
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _keyRow(['C', '⌫', '/'], isTop: true),
        _keyRow(['7', '8', '9', 'x']),
        _keyRow(['4', '5', '6', '-']),
        _keyRow(['1', '2', '3', '+']),
        _keyRow(['.', '0', '000', '=']),
      ],
    );
  }

  Widget _keyRow(List<String> keys, {bool isTop = false}) {
    return Expanded(
      child: Row(
        children: [
          if (isTop) _buildTipButton(),
          ...keys.map((k) => _buildKey(k)),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    bool isOperator = ['/', 'x', '-', '+', '='].contains(label);
    return Expanded(
      child: InkWell(
        onTap: () => _onKeyPress(label),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: label == '=' ? _primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, color: Colors.red[400], size: 18)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: label == '='
                        ? Colors.white
                        : (isOperator ? Colors.blue : Colors.black87),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTipButton() {
    return Expanded(
      child: InkWell(
        onTap: _applyTip,
        onLongPress: _showTipPicker,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "+$_tipPercentage%",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMode() {
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
          onTapUp: (_) {
            setState(() => _isVoicePressed = false);
            _processVoiceResult(); // Now handles stop and wait internally
          },
          onTapCancel: () {
            setState(() => _isVoicePressed = false);
            _sttController.stopAndGetFinal();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isVoicePressed ? Colors.black : Colors.white,
              border: Border.all(color: _primaryColor, width: 2),
              boxShadow: [
                BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: Icon(
              Icons.mic,
              size: 36,
              color: _isVoicePressed ? Colors.white : _primaryColor,
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

  void _processVoiceResult() async {
    final transcript = await _sttController.stopAndGetFinal();
    final sanitized = AmountParser.sanitize(transcript);
    final value = AmountParser.parseAmount(transcript);

    // [Debug Logs per user request]
    print("STT Final Transcript: \"$transcript\"");
    print("Sanitized Text: \"$sanitized\"");
    print("Parsed Result: $value");

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
```
