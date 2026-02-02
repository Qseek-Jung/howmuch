import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ledger_project.dart';
import '../../models/ledger_expense.dart';
import '../../../../core/split_logic.dart';
import '../../../../presentation/widgets/horizontal_dial_picker.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/ad_settings_provider.dart';
import '../../../../services/admob_service.dart';
import '../../../../core/design_system.dart';

class ShareReportOptionsSheet extends ConsumerStatefulWidget {
  final LedgerProject project;
  final double totalSpentKrw;
  final Map<ExpenseCategory, double> categorySums;
  final String targetCurrencyCode;
  final double targetRate;
  final bool isDomestic;
  final UserSettings settings;

  const ShareReportOptionsSheet({
    super.key,
    required this.project,
    required this.totalSpentKrw,
    required this.categorySums,
    required this.targetCurrencyCode,
    required this.targetRate,
    required this.isDomestic,
    required this.settings,
  });

  @override
  ConsumerState<ShareReportOptionsSheet> createState() =>
      _ShareReportOptionsSheetState();
}

class _ShareReportOptionsSheetState
    extends ConsumerState<ShareReportOptionsSheet> {
  // Share Options State (All Default True)
  bool _includeOverview = true;
  bool _includeTotal = true;
  bool _includeCategory = true;
  bool _includePaymentMethod = true;
  bool _includeSettlement = true;
  bool _includeBankInfo = true;
  bool _includeMessage = true;

  // Configuration State
  late int _selectedCurrencyOption; // 0: Both, 1: Local, 2: KRW
  int _selectedRoundUnit = 1000;
  late Set<String> _selectedMembers;

  late TextEditingController _messageController;
  final FocusNode _messageFocusNode = FocusNode();
  final String _defaultMessage = "본인금액을 확인하신 후 입금 부탁드립니다. 감사합니다.";

  @override
  void initState() {
    super.initState();
    _selectedCurrencyOption = widget.isDomestic ? 2 : 0;
    // Default: Select all members
    _selectedMembers = widget.project.members.toSet();

    _messageController = TextEditingController(text: _defaultMessage);

    // Focus listener to clear default text
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        if (_messageController.text == _defaultMessage) {
          _messageController.clear();
        }
      } else {
        // Optional: Restore if empty? User requirement didn't specify restore,
        // but implied "if not changed, send default".
        // If user clears and leaves, maybe they want no message?
        // But the checkbox controls inclusion.
        // We'll leave it empty if cleared.
        if (_messageController.text.trim().isEmpty) {
          _messageController.text = _defaultMessage;
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _generateAndShare() {
    final buffer = StringBuffer();
    final f = NumberFormat('#,###');

    // 1. Overview
    if (_includeOverview) {
      buffer.writeln("[여계부 리포트]");
      buffer.writeln("여행: ${widget.project.title}");
      buffer.writeln(
        "기간: ${DateFormat('yyyy.MM.dd').format(widget.project.startDate)} ~ ${DateFormat('yyyy.MM.dd').format(widget.project.endDate)}",
      );
    }

    // 2. Total Spend
    if (_includeTotal) {
      double totalLocal = widget.totalSpentKrw / widget.targetRate;
      String totalStr = "";
      if (_selectedCurrencyOption == 0) {
        totalStr =
            "${f.format(totalLocal.round())} ${widget.targetCurrencyCode}\n   (≈ ${f.format(widget.totalSpentKrw.round())}원)";
      } else if (_selectedCurrencyOption == 1) {
        totalStr =
            "${f.format(totalLocal.round())} ${widget.targetCurrencyCode}";
      } else {
        totalStr = "${f.format(widget.totalSpentKrw.round())}원";
      }
      buffer.writeln("총 지출: $totalStr");
    }

    // 3. Category Breakdown
    if (_includeCategory) {
      buffer.writeln("\n<카테고리별 지출>");
      for (var entry in widget.categorySums.entries) {
        final amountKrw = entry.value;
        final percentage = widget.totalSpentKrw > 0
            ? (amountKrw / widget.totalSpentKrw * 100).toStringAsFixed(1)
            : "0";

        String amountStr = "";
        if (_selectedCurrencyOption == 0) {
          double amountLocal = amountKrw / widget.targetRate;
          amountStr =
              "${f.format(amountLocal.round())} ${widget.targetCurrencyCode}\n   (≈ ${f.format(amountKrw.round())}원)";
        } else if (_selectedCurrencyOption == 1) {
          double amountLocal = amountKrw / widget.targetRate;
          amountStr =
              "${f.format(amountLocal.round())} ${widget.targetCurrencyCode}";
        } else {
          amountStr = "${f.format(amountKrw.round())}원";
        }

        buffer.writeln(
          "- ${_getCategoryLabel(entry.key)}: $amountStr ($percentage%)",
        );
      }
    }

    // 3.5 Payment Method Breakdown
    if (_includePaymentMethod) {
      buffer.writeln("\n<결제수단별 지출>");
      final methodSums = _calculatePaymentMethodSums(widget.project.expenses);
      for (var entry in methodSums.entries) {
        final amountKrw = entry.value;
        final percentage = widget.totalSpentKrw > 0
            ? (amountKrw / widget.totalSpentKrw * 100).toStringAsFixed(1)
            : "0";

        String amountStr = "";
        if (_selectedCurrencyOption == 0) {
          double amountLocal = amountKrw / widget.targetRate;
          amountStr =
              "${f.format(amountLocal.round())} ${widget.targetCurrencyCode}\n   (≈ ${f.format(amountKrw.round())}원)";
        } else if (_selectedCurrencyOption == 1) {
          double amountLocal = amountKrw / widget.targetRate;
          amountStr =
              "${f.format(amountLocal.round())} ${widget.targetCurrencyCode}";
        } else {
          amountStr = "${f.format(amountKrw.round())}원";
        }

        buffer.writeln(
          "- ${_getPaymentMethodLabel(entry.key)}: $amountStr ($percentage%)",
        );
      }
    }

    // 4. Settlement (N/1)
    // Dependency: Must be checked AND have members selected
    if (_includeSettlement) {
      buffer.writeln("\n<정산 (1/N)>");
      buffer.writeln("* 올림단위: ${f.format(_selectedRoundUnit)}원 적용");

      double totalCollectedKrw = 0;

      for (var m in widget.project.members) {
        // Skip if member not selected
        if (!_selectedMembers.contains(m)) continue;

        double myShareKrw = 0;
        for (var e in widget.project.expenses) {
          if (e.payers.contains(m)) {
            myShareKrw += e.amountKrw / e.payers.length;
          }
        }

        String shareStr = "";
        if (_selectedCurrencyOption == 2 || _selectedCurrencyOption == 0) {
          final splitResult = SplitCalculator.calculateSplit(
            totalAmount: myShareKrw,
            peopleCount: 1,
            roundUnit: _selectedRoundUnit,
          );
          double roundedKrw = splitResult.perPersonRounded;
          totalCollectedKrw += roundedKrw;

          if (_selectedCurrencyOption == 2) {
            shareStr = "${f.format(roundedKrw)}원";
          } else {
            double roundedLocal = (roundedKrw / widget.targetRate);
            shareStr =
                "${f.format(roundedLocal.toInt())} ${widget.targetCurrencyCode}\n   (≈ ${f.format(roundedKrw)}원)";
          }
        } else if (_selectedCurrencyOption == 1) {
          double myShareLocal = myShareKrw / widget.targetRate;
          double roundedLocal =
              (myShareLocal / _selectedRoundUnit).ceil() *
              _selectedRoundUnit.toDouble();
          shareStr = "${f.format(roundedLocal)} ${widget.targetCurrencyCode}";
        }

        buffer.writeln("- $m: $shareStr");
      }

      // Surplus (Bo-zzi)
      if ((_selectedCurrencyOption == 2 || _selectedCurrencyOption == 0)) {
        double selectedMembersExactShare = 0;
        for (var m in widget.project.members) {
          if (!_selectedMembers.contains(m)) continue;
          for (var e in widget.project.expenses) {
            if (e.payers.contains(m)) {
              selectedMembersExactShare += e.amountKrw / e.payers.length;
            }
          }
        }

        if (totalCollectedKrw > selectedMembersExactShare) {
          double surplus = totalCollectedKrw - selectedMembersExactShare;
          buffer.writeln("\n총무뽀찌: ${f.format(surplus)}원 (올림으로 인한 차액)");
        }
      }
    }

    // 5. Bank Info
    if (_includeBankInfo && !widget.settings.isEmpty) {
      buffer.writeln("\n<입금계좌>");
      if (widget.settings.bankName.isNotEmpty) {
        buffer.writeln(widget.settings.bankName);
      }
      if (widget.settings.accountNumber.isNotEmpty) {
        buffer.writeln(widget.settings.accountNumber);
      }
      if (widget.settings.accountHolder.isNotEmpty) {
        buffer.writeln("예금주: ${widget.settings.accountHolder}");
      }
    }

    // 6. Additional Message
    // Logic: Include if checked AND text is not empty.
    if (_includeMessage && _messageController.text.isNotEmpty) {
      buffer.writeln("\n${_messageController.text}");
    }

    // Show ad before sharing
    final adSettings = ref.read(adSettingsProvider.notifier);
    if (adSettings.shouldShowAd()) {
      AdMobService.instance.showInterstitialAd(
        onAdDismissed: () {
          Share.share(buffer.toString());
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );
    } else {
      Share.share(buffer.toString());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // iOS System Background Colors
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final sectionColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 20),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 2. Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "공유 옵션",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                // Share Button moved to bottom for better reachability and standard "Action Sheet" feel
                // Keeping "Cancel" or "Close" button here effectively via swipe or tap outside
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader("포함할 항목", isDark),
                _buildSectionContainer(
                  color: sectionColor,
                  isDark: isDark,
                  children: [
                    _buildSwitchRow(
                      "여행 개요",
                      _includeOverview,
                      (v) => setState(() => _includeOverview = v),
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchRow(
                      "총 사용 금액",
                      _includeTotal,
                      (v) => setState(() => _includeTotal = v),
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchRow(
                      "카테고리별 지출",
                      _includeCategory,
                      (v) => setState(() => _includeCategory = v),
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchRow(
                      "결제수단별 지출",
                      _includePaymentMethod,
                      (v) => setState(() => _includePaymentMethod = v),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionHeader("표시 설정", isDark),
                _buildSectionContainer(
                  color: sectionColor,
                  isDark: isDark,
                  children: [
                    if (!widget.isDomestic) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "표시 통화",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CupertinoSlidingSegmentedControl<int>(
                              groupValue: _selectedCurrencyOption,
                              children: {
                                0: Text(
                                  "${widget.targetCurrencyCode} + KRW",
                                  style: const TextStyle(fontSize: 13),
                                ),
                                1: Text(
                                  widget.targetCurrencyCode,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                2: const Text(
                                  "KRW",
                                  style: TextStyle(fontSize: 13),
                                ),
                              },
                              onValueChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedCurrencyOption = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildDivider(isDark),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "정산 올림 단위",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          HorizontalDialPicker<int>(
                            viewportFraction: 0.35,
                            items: const [1, 10, 100, 1000, 10000],
                            selectedValue: _selectedRoundUnit,
                            onChanged: (val) =>
                                setState(() => _selectedRoundUnit = val),
                            itemBuilder: (context, val, opacity, scale) {
                              final f = NumberFormat('#,###');
                              return Text(
                                f.format(val),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: scale > 1.1
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: opacity),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionHeader("정산 및 인원", isDark),
                _buildSectionContainer(
                  color: sectionColor,
                  isDark: isDark,
                  children: [
                    _buildSwitchRow(
                      "정산 (1/N)",
                      _includeSettlement,
                      (v) => setState(() => _includeSettlement = v),
                      isDark,
                    ),
                    // Dependency: Only show member list if Settlement is checked
                    if (_includeSettlement) ...[
                      _buildDivider(isDark),
                      // Expandable Member List with Smooth Animation
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: widget.project.members.map((m) {
                            final isSelected = _selectedMembers.contains(m);
                            return _buildMemberRow(m, isSelected, isDark);
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionHeader("추가 정보", isDark),
                _buildSectionContainer(
                  color: sectionColor,
                  isDark: isDark,
                  children: [
                    if (!widget.settings.isEmpty) ...[
                      _buildSwitchRow(
                        "입금 계좌 포함",
                        _includeBankInfo,
                        (v) => setState(() => _includeBankInfo = v),
                        isDark,
                      ),
                      _buildDivider(isDark),
                    ],
                    _buildSwitchRow(
                      "메세지 포함",
                      _includeMessage,
                      (v) => setState(() => _includeMessage = v),
                      isDark,
                    ),
                    if (_includeMessage) ...[
                      _buildDivider(isDark),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          maxLines: 4,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "메세지를 입력하세요",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF2F2F7),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF34C759),
                                width: 1,
                              ), // Focus Color
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Extra padding for bottom button integration
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 4. Pinned Bottom Action Button with SafeArea
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _generateAndShare,
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1A1A1A,
                        ), // Dark premium color or Brand Color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) =>
                              AppColors.getPrimary(isDark), // Use Green tone
                        ),
                      ),
                  child: const Text(
                    "공유하기",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white54 : Colors.grey[600],
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required Color color,
    required bool isDark,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17, // Standard iOS Body
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.4,
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: const Color(0xFF34C759), // Apple Green
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow(String name, bool isSelected, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMembers.remove(name);
            } else {
              _selectedMembers.add(name);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: isSelected
                    ? const Color(0xFF34C759)
                    : (isDark ? Colors.white38 : Colors.grey[400]),
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 17,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white38 : Colors.grey),
                  decoration: isSelected ? null : TextDecoration.lineThrough,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: isDark ? Colors.white12 : Colors.grey[300],
      indent: 16,
      endIndent: 0,
    );
  }

  String _getCategoryLabel(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.food:
        return "식비";
      case ExpenseCategory.lodging:
        return "숙박";
      case ExpenseCategory.transport:
        return "교통";
      case ExpenseCategory.shopping:
        return "쇼핑";
      case ExpenseCategory.tour:
        return "관광";
      case ExpenseCategory.golf:
        return "골프";
      case ExpenseCategory.activity:
        return "액티비티";
      case ExpenseCategory.medical:
        return "의료비";
      case ExpenseCategory.etc:
        return "기타";
    }
  }

  Map<PaymentMethod, double> _calculatePaymentMethodSums(
    List<LedgerExpense> expenses,
  ) {
    final Map<PaymentMethod, double> sums = {};
    for (var e in expenses) {
      sums[e.paymentMethod] = (sums[e.paymentMethod] ?? 0) + e.amountKrw;
    }
    return sums;
  }

  String _getPaymentMethodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return "현금";
      case PaymentMethod.card:
        return "카드";
      case PaymentMethod.appPay:
        return "앱페이";
      case PaymentMethod.etc:
        return "기타";
    }
  }
}
