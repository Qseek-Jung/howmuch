import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../home/currency_provider.dart';
import 'split_provider.dart';
import '../../providers/settings_provider.dart';
import 'split_report_screen.dart';
import '../../core/split_logic.dart';
import '../../data/models/split_bill_model.dart';
import '../../data/models/currency_model.dart';
import '../../features/ledger/providers/ledger_provider.dart';
import '../../features/ledger/presentation/expense_add_sheet.dart';
import '../../core/design_system.dart';
import '../widgets/horizontal_dial_picker.dart';

class SplitHomeScreen extends ConsumerStatefulWidget {
  const SplitHomeScreen({super.key});

  @override
  ConsumerState<SplitHomeScreen> createState() => _SplitHomeScreenState();
}

class _SplitHomeScreenState extends ConsumerState<SplitHomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  int _peopleCount = 2;
  int _selectedUnit = 1000;
  bool _isKrwInput = true;
  bool _isSplitInLocal = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reset input when navigating away (index 1 is SplitHomeScreen)
    ref.listen<int>(mainNavigationProvider, (previous, next) {
      if (previous == 1 && next != 1) {
        _amountController.clear();
      }
    });

    final history = ref.watch(splitHistoryProvider);
    final currencyList = ref.watch(currencyListProvider).value ?? [];
    final favoriteCodes = ref.watch(favoriteCurrenciesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine target currency from shared provider or fallback to first favorite
    final selectedId = ref.watch(selectedCurrencyIdProvider);
    final targetCurrency = (selectedId != null)
        ? currencyList.where((c) => c.uniqueId == selectedId).firstOrNull
        : (favoriteCodes.isNotEmpty
              ? currencyList
                    .where((c) => c.uniqueId == favoriteCodes[0])
                    .firstOrNull
              : null);
    final targetCode = targetCurrency?.code ?? 'USD';

    final favorites = favoriteCodes.map((key) {
      return currencyList.firstWhere(
        (c) => c.uniqueId == key,
        orElse: () {
          final parts = key.split(':');
          // New format: Name:Code. parts[0] is Name, parts[1] is Code.
          String name = parts[0];
          String code = parts.length > 1 ? parts[1] : parts[0];
          // Support migration/fallback if needed
          if (parts.length > 1 && RegExp(r'^[A-Z]{3}$').hasMatch(parts[0])) {
            code = parts[0];
            name = parts[1];
          }
          return Currency(
            code: code,
            name: name,
            rateToKrw: 0,
            updatedAt: DateTime.now(),
          );
        },
      );
    }).toList();

    final f = NumberFormat('#,###');
    final settings = ref.watch(settingsProvider);

    // Calculate mirror value
    double inputVal = 0;
    try {
      inputVal = double.parse(_amountController.text.replaceAll(',', ''));
    } catch (_) {}

    String mirrorValue = "";
    if (inputVal > 0 && targetCurrency != null) {
      double rate = targetCurrency.rateToKrw;
      if (settings.isExchangeCorrectionEnabled) {
        rate = rate * (1 + (settings.exchangeCorrectionPercentage / 100));
      }

      if (_isKrwInput) {
        double localVal = inputVal / rate;
        mirrorValue = "${f.format(localVal.toInt())} $targetCode";
      } else {
        double krwVal = inputVal * rate;
        mirrorValue = "${f.format(krwVal.toInt())} KRW";
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Input Header (Clean White Style)
                  SliverToBoxAdapter(
                    child: Container(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "정산할 총 금액",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : CupertinoColors.secondaryLabel,
                                ),
                              ),
                              _buildCurrencySegmentedControl(
                                targetCode,
                                favorites,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAmountInput(targetCode),
                          // Fix height to prevent layout shift
                          SizedBox(
                            height: 28,
                            child: (mirrorValue.isNotEmpty && !_isKrwInput)
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "≈ $mirrorValue",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.activeBlue,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Settings Section (iOS List Style)
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFC6C6C8),
                            width: 0.5,
                          ),
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFC6C6C8),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 1. People Count Picker
                          _buildPickerSection(
                            label: "정산 인원",
                            content: HorizontalDialPicker<int>(
                              items: List.generate(49, (i) => i + 2),
                              selectedValue: _peopleCount,
                              onChanged: (val) =>
                                  setState(() => _peopleCount = val),
                              viewportFraction: 0.22,
                              itemBuilder: (context, val, opacity, scale) =>
                                  Text(
                                    "$val",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: scale > 1.1
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: opacity),
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                            ),
                          ),
                          const Divider(height: 4, color: Colors.transparent),

                          // 2. Rounding Unit Picker
                          _buildPickerSection(
                            label: "올림 단위",
                            content: HorizontalDialPicker<int>(
                              items: const [
                                1,
                                10,
                                100,
                                1000,
                                10000,
                                100000,
                                1000000,
                              ],
                              selectedValue: _selectedUnit,
                              onChanged: (val) =>
                                  setState(() => _selectedUnit = val),
                              viewportFraction: 0.35,
                              itemBuilder: (context, val, opacity, scale) {
                                final f = NumberFormat('#,###');
                                return Text(
                                  f.format(val),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: scale > 1.1
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: opacity),
                                    letterSpacing: -0.5,
                                  ),
                                );
                              },
                            ),
                          ),

                          const Divider(height: 4, color: Colors.transparent),
                          _buildListRow(
                            label: "현지 통화로 정산",
                            trailing: CupertinoSwitch(
                              value: _isSplitInLocal,
                              onChanged: (val) =>
                                  setState(() => _isSplitInLocal = val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. History Header
                  if (history.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Text(
                          "최근 정산 기록",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : CupertinoColors.secondaryLabel,
                            textBaseline: TextBaseline.alphabetic,
                          ),
                        ),
                      ),
                    ),

                  // 5. History List (iOS Style Cells)
                  if (history.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final split = history[index];
                        final isLast = index == history.length - 1;
                        return _buildHistoryCell(split, isLast);
                      }, childCount: history.length),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),

            // Fixed Bottom Action Button
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withValues(alpha: 0.05),
                    width: 0.5,
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: AppDesign.primaryGradientDecoration(isDark),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _handleCalculate(targetCurrency),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "정산 결과 보기",
                        style: AppDesign.buttonTextStyle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListRow({
    required String label,
    required Widget trailing,
    bool isColumn = false,
    Widget? content,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : CupertinoColors.label,
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing,
            ],
          ),
          if (isColumn && content != null) ...[
            const SizedBox(height: 12),
            content,
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencySegmentedControl(
    String targetCode,
    List<Currency> favorites,
  ) {
    return SizedBox(
      width: 150, // Slightly wider to avoid overlap
      child: CupertinoSlidingSegmentedControl<bool>(
        groupValue: _isKrwInput,
        children: {
          true: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_isKrwInput) {
                // Already KRW, do nothing or show something?
                // User specifically asked for the "other" currency picker
              } else {
                setState(() => _isKrwInput = true);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "KRW",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _isKrwInput ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          false: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_isKrwInput) {
                // Already on Target currency, open picker!
                _showCurrencyPicker(favorites);
              } else {
                setState(() => _isKrwInput = false);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                targetCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: !_isKrwInput
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        },
        onValueChanged: (val) {
          // Standard selection logic handled by GestureDetector for "repeat" support
        },
      ),
    );
  }

  void _showCurrencyPicker(List<Currency> favorites) {
    if (favorites.isEmpty) return;

    // Filter out KRW
    final items = favorites.where((c) => c.code != 'KRW').toList();
    if (items.isEmpty) return;

    final selectedId = ref.read(selectedCurrencyIdProvider);
    int tempIndex = items.indexWhere((c) => c.uniqueId == selectedId);
    if (tempIndex == -1) tempIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text(
                      "관리",
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(
                        '/currency_manage',
                        extra: {'isSelectionMode': false},
                      );
                    },
                  ),
                  const Text(
                    "국가(통화) 선택",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      color: Colors.grey,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text(
                      "확인",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final selected = items[tempIndex];
                      ref
                          .read(selectedCurrencyIdProvider.notifier)
                          .setSelectedId(selected.uniqueId);
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
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                onSelectedItemChanged: (index) => tempIndex = index,
                children: items
                    .map(
                      (c) => Center(
                        child: Text(
                          "${c.name} (${c.code})",
                          style: TextStyle(
                            fontSize: 20,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
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

  // Wheel pickers implemented at the bottom of the file

  Widget _buildAmountInput(String targetCode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return TextField(
                controller: _amountController,
                onChanged: (val) => setState(() {}), // Update mirror value
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : CupertinoColors.label,
                  letterSpacing: -1.5,
                ),
                cursorColor: CupertinoColors.activeBlue,
                decoration: InputDecoration(
                  hintText: "0",
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white24
                        : CupertinoColors.placeholderText.withValues(
                            alpha: 0.3,
                          ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                  ThousandsSeparatorInputFormatter(),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Clear button box (Fixed width to prevent shifting)
            SizedBox(
              width: 32,
              child: _amountController.text.isNotEmpty
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          setState(() => _amountController.clear()),
                      child: const Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: Colors.grey,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            Text(
              _isKrwInput ? "KRW" : targetCode,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerSection({required String label, required Widget content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: content,
        ),
      ],
    );
  }

  void _handleCalculate(dynamic targetCurrency) {
    String cleanText = _amountController.text.replaceAll(',', '');
    double? inputAmount = double.tryParse(cleanText);
    if (inputAmount == null || inputAmount <= 0) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("알림"),
          content: const Text("금액을 정확히 입력해주세요."),
          actions: [
            CupertinoDialogAction(
              child: const Text("확인"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    // Apply exchange rate correction if enabled
    final settings = ref.read(settingsProvider);
    double? rate = targetCurrency?.rateToKrw;

    if (!_isKrwInput && (rate == null || rate == 0)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("알림"),
          content: const Text("환율 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요."),
          actions: [
            CupertinoDialogAction(
              child: const Text("확인"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    double finalRate = rate ?? 1.0;
    if (settings.isExchangeCorrectionEnabled && targetCurrency != null) {
      finalRate =
          finalRate * (1 + (settings.exchangeCorrectionPercentage / 100));
    }

    double krwAmount = inputAmount;
    if (!_isKrwInput && targetCurrency != null) {
      krwAmount = inputAmount * finalRate;
    }

    // Determine splitting amount based on _isSplitInLocal
    final String targetCode = targetCurrency?.code ?? 'USD';
    final double amountToSplit = _isSplitInLocal ? inputAmount : krwAmount;
    final String currencyToSplit = _isSplitInLocal
        ? (_isKrwInput ? "KRW" : targetCode)
        : "KRW";

    final result = SplitCalculator.calculateSplit(
      totalAmount: amountToSplit,
      peopleCount: _peopleCount,
      roundUnit: _selectedUnit,
    );

    // Auto-save to history
    final newSplit = SplitBill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: DateFormat('MM.dd HH:mm').format(DateTime.now()),
      date: DateTime.now(),
      totalAmount: amountToSplit, // Save the actual amount used for split
      currency: currencyToSplit, // Save the currency used for split
      peopleCount: _peopleCount,
      perPersonAmount: result.perPersonRounded,
      surplus: result.surplus,
      roundUnit: _selectedUnit,
      originalAmount: inputAmount,
      originalCurrency: _isKrwInput ? "KRW" : targetCode,
      rateToKrw: rate,
    );
    ref.read(splitHistoryProvider.notifier).addSplit(newSplit);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SplitReportScreen(
          totalAmount: krwAmount, // Pass KRW for history/reference
          originalAmount: inputAmount,
          originalCurrency: _isKrwInput ? "KRW" : targetCode,
          peopleCount: _peopleCount,
          roundUnit: _selectedUnit,
          result: result,
          splitCurrency: currencyToSplit,
          rateToKrw: targetCurrency?.rateToKrw ?? 1.0,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.doc_plaintext,
            size: 48,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            "최근 정산 내역이 없습니다",
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey[400],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCell(SplitBill split, bool isLast) {
    final f = NumberFormat('#,###');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Slidable(
          key: Key(split.id),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _showDeleteConfirm(split),
                backgroundColor: const Color(0xFFFE3B30),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.trash,
                label: '삭제',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _showProjectPickerForSplit(split),
                backgroundColor: const Color(0xFF34C759), // Green
                foregroundColor: Colors.white,
                icon: CupertinoIcons.book_fill,
                label: '여계부 등록',
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Reconstruct result for report screen
                final result = SplitCalculator.calculateSplit(
                  totalAmount: split.totalAmount,
                  peopleCount: split.peopleCount,
                  roundUnit: split.roundUnit,
                );
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => SplitReportScreen(
                      totalAmount:
                          (split.originalAmount ?? split.totalAmount) *
                          (split.rateToKrw ?? 1.0),
                      originalAmount: split.originalAmount ?? split.totalAmount,
                      originalCurrency:
                          split.originalCurrency ?? split.currency,
                      peopleCount: split.peopleCount,
                      roundUnit: split.roundUnit,
                      result: result,
                      splitCurrency: split.currency,
                      rateToKrw: split.rateToKrw ?? 1.0,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('MM.dd HH:mm').format(split.date),
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "총 ${f.format(split.totalAmount.toInt())}${split.currency == 'KRW' ? '원' : split.currency}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "1/N : ${f.format(split.perPersonAmount)}${split.currency == 'KRW' ? '원' : split.currency} / ${split.peopleCount}명",
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_forward,
                      size: 16,
                      color: Colors.grey,
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

  void _showProjectPickerForSplit(SplitBill split) {
    final projects = ref.read(ledgerProvider);

    // CRITICAL: Filter projects by split currency (matches split_report_screen.dart)
    final relevantProjects = projects.where((p) {
      return p.defaultCurrency == split.currency ||
          p.countries.contains(split.currency);
    }).toList();

    if (relevantProjects.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("해당 통화 프로젝트 없음"),
          content: Text(
            "${split.currency} 통화를 사용하는 여행 프로젝트가 여계부에 없습니다.\n여계부에서 프로젝트를 먼저 생성하거나 통화 정보를 확인해주세요.",
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("확인"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("여계부 등록"),
        message: Text("정산 내역을 등록할 ${split.currency} 여행을 선택하세요."),
        actions: relevantProjects.map((project) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showLedgerAddSheet(project.id, split);
            },
            child: Text(project.title),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
      ),
    );
  }

  void _showLedgerAddSheet(String projectId, SplitBill split) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseAddSheet(
        projectId: projectId,
        initialAmount: split.totalAmount,
        initialCurrency: split.currency,
        initialDate: split.date,
        initialTitle: "정산: ${split.title}",
      ),
    );
  }

  void _showDeleteConfirm(SplitBill split) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("내역 삭제"),
        content: const Text("이 정산 내역을 삭제하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("삭제"),
            onPressed: () {
              ref.read(splitHistoryProvider.notifier).deleteSplit(split.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ',';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newValueText = newValue.text.replaceAll(separator, '');

    if (newValueText.contains('.')) {
      List<String> parts = newValueText.split('.');
      if (parts.length > 2) return oldValue;

      String integerPart = parts[0];
      String decimalPart = parts[1];

      String formattedInteger = _formatInteger(integerPart);
      String newText = '$formattedInteger.$decimalPart';

      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    String formattedText = _formatInteger(newValueText);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _formatInteger(String text) {
    if (text.isEmpty) return "";
    double? number = double.tryParse(text);
    if (number == null) return text;
    final formatter = NumberFormat('#,###');
    return formatter.format(number.toInt());
  }
}

// Local class _HorizontalDialPicker removed. Use lib/presentation/widgets/horizontal_dial_picker.dart instead.
