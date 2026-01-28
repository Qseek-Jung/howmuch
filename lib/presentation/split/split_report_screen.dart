import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/split_logic.dart';
import '../../providers/settings_provider.dart';

class SplitReportScreen extends ConsumerStatefulWidget {
  final double totalAmount; // KRW Total
  final double originalAmount;
  final String originalCurrency;
  final int peopleCount;
  final int roundUnit;
  final SplitResult result;
  final String splitCurrency; // Currency used for splitting (e.g., KRW or THB)
  final double rateToKrw; // Exchange rate to show KRW alternative

  const SplitReportScreen({
    super.key,
    required this.totalAmount,
    required this.originalAmount,
    required this.originalCurrency,
    required this.peopleCount,
    required this.roundUnit,
    required this.result,
    required this.splitCurrency,
    required this.rateToKrw,
  });

  @override
  ConsumerState<SplitReportScreen> createState() => _SplitReportScreenState();
}

class _SplitReportScreenState extends ConsumerState<SplitReportScreen> {
  final TextEditingController _titleController = TextEditingController(
    text: "오늘의 모임",
  );
  final List<Map<String, dynamic>> _extraItems = [];
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          "정산 리포트",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1),
            height: 0.5,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFF0A84FF) : CupertinoColors.activeBlue,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildResultHeader(f, isDark),
            _buildSettingsList(f, isDark),
            _buildExtraItemsSection(f, isDark),
            const SizedBox(height: 140),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(isDark),
    );
  }

  Widget _buildResultHeader(NumberFormat f, bool isDark) {
    // 1. Calculate per-person base (rounded to 1 unit)
    final double perPersonExact = widget.splitCurrency == "KRW"
        ? (widget.totalAmount / widget.peopleCount)
        : (widget.originalAmount / widget.peopleCount);

    final double perPersonBase = perPersonExact.ceilToDouble();
    final double perPersonBbozzi =
        widget.result.perPersonRounded - perPersonBase;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        children: [
          CupertinoTextField(
            controller: _titleController,
            textAlign: TextAlign.center,
            placeholder: "모임 이름 입력",
            cursorColor: isDark
                ? const Color(0xFF0A84FF)
                : CupertinoColors.activeBlue,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
            decoration: null,
          ),
          const SizedBox(height: 32),
          Text(
            widget.splitCurrency == "KRW"
                ? "1인당 보낼 금액"
                : "1인당 보낼 금액 (${widget.splitCurrency})",
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${f.format(widget.result.perPersonRounded)}${widget.splitCurrency == "KRW" ? "원" : " " + widget.splitCurrency}",
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -1.5,
            ),
          ),

          // Calculation transparency
          if (perPersonBbozzi > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "원금액 ${f.format(perPersonBase)} + 뽀찌 ${f.format(perPersonBbozzi)}${widget.splitCurrency == "KRW" ? "원" : ""}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
          ],

          if (widget.splitCurrency != "KRW") ...[
            const SizedBox(height: 8),
            Text(
              "≈ ${f.format((widget.result.perPersonRounded * widget.rateToKrw).round())}원",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF0A84FF)
                    : CupertinoColors.activeBlue,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsList(NumberFormat f, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          _rowItem(
            "실제 총 금액",
            widget.originalCurrency == "KRW"
                ? "${f.format(widget.originalAmount)}원"
                : "${f.format(widget.originalAmount)} ${widget.originalCurrency} (≈ ${f.format(widget.totalAmount.round())}원)",
            true,
          ),
          _rowItem("정산 인원", "${widget.peopleCount}명", true),
          _rowItem(
            "올림 단위",
            "${f.format(widget.roundUnit)}${widget.splitCurrency == "KRW" ? "원" : " " + widget.splitCurrency}",
            true,
          ),
          if (widget.result.surplus > 0)
            _rowItem(
              "총무 뽀찌 (잔돈)",
              "+${f.format(widget.result.surplus)}${widget.splitCurrency == "KRW" ? "원" : " " + widget.splitCurrency}",
              false,
              valueColor: isDark
                  ? const Color(0xFFFF9F0A)
                  : const Color(0xFFFF9500),
            ),
        ],
      ),
    );
  }

  Widget _rowItem(
    String label,
    String value,
    bool showDivider, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : CupertinoColors.secondaryLabel,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        valueColor ??
                        (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : CupertinoColors.label),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Divider(
              height: 0.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05),
              thickness: 0.5,
            ),
          ),
      ],
    );
  }

  Widget _buildExtraItemsSection(NumberFormat f, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_extraItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              "추가 정산 항목",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                ..._extraItems.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final item = entry.value;
                  return _rowItem(
                    item['name'],
                    "${f.format(item['price'])}원",
                    idx < _extraItems.length - 1,
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showAddItemDialog,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF0A84FF)
                      : CupertinoColors.activeBlue.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  "별도 청구 항목 추가",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF0A84FF)
                        : CupertinoColors.activeBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("항목 추가"),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _itemNameController,
                placeholder: "항목 이름 (예: 주류)",
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _itemPriceController,
                placeholder: "금액 (원)",
                padding: const EdgeInsets.all(12),
                keyboardType: TextInputType.number,
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (_itemNameController.text.isNotEmpty &&
                  _itemPriceController.text.isNotEmpty) {
                setState(() {
                  _extraItems.add({
                    'name': _itemNameController.text,
                    'price': double.parse(
                      _itemPriceController.text.replaceAll(',', ''),
                    ),
                  });
                });
                _itemNameController.clear();
                _itemPriceController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("추가"),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFFFEE500),
              borderRadius: BorderRadius.circular(14),
              onPressed: _shareToKakao,
              pressedOpacity: 0.7,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.share_up,
                    color: Colors.black87,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "카톡 공유",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: isDark
                  ? const Color(0xFF0A84FF)
                  : const Color(0xFF007AFF), // System Blue
              borderRadius: BorderRadius.circular(14),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              pressedOpacity: 0.7,
              child: const Text(
                "여계부 등록",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareToKakao() {
    final f = NumberFormat('#,###');
    final String currencySuffix = widget.splitCurrency == "KRW"
        ? "원"
        : " " + widget.splitCurrency;

    // Recalculate transparent logic for share message
    final double perPersonExact = widget.splitCurrency == "KRW"
        ? (widget.totalAmount / widget.peopleCount)
        : (widget.originalAmount / widget.peopleCount);
    final double perPersonBase = perPersonExact.ceilToDouble();
    final double perPersonBbozzi =
        widget.result.perPersonRounded - perPersonBase;

    final bankInfo = ref.read(settingsProvider);

    // Calculate extra items total
    double extraTotal = 0;
    for (var item in _extraItems) {
      extraTotal += (item['price'] as double);
    }
    final double grandTotal = widget.result.perPersonRounded + extraTotal;

    // Build message in user's requested format
    String report = "📢 [${_titleController.text}] 정산 안내\n\n";

    // Total amount
    report += "총액 : ";
    if (widget.originalCurrency != "KRW") {
      report += "${f.format(widget.originalAmount)} ${widget.originalCurrency}";
      report += " (약 ${f.format(widget.totalAmount.round())}원)\n";
    } else {
      report += "${f.format(widget.originalAmount)}원\n";
    }

    // People count
    report += "인원 : ${widget.peopleCount}명\n";
    report += "----------------------------\n";

    // 1/N amount
    report +=
        "1/N : ${f.format(widget.result.perPersonRounded)}$currencySuffix\n";

    // Rounding breakdown
    if (perPersonBbozzi > 0) {
      report +=
          "(${f.format(perPersonBase)}원 + ${f.format(widget.roundUnit)}단위 올림)\n";
      report += "총무뽀찌 : ${f.format(widget.result.surplus)}원\n";
    }

    // KRW conversion if foreign currency
    if (widget.splitCurrency != "KRW") {
      report +=
          "≈ 원화 환산: ${f.format((widget.result.perPersonRounded * widget.rateToKrw).round())}원\n";
    }

    // Extra items
    if (_extraItems.isNotEmpty) {
      report += "\n[별도 청구 항목]\n";
      for (var item in _extraItems) {
        report += "• ${item['name']}: ${f.format(item['price'])}원\n";
      }
    }

    // Thank you message with total
    report += "\n뽀지 감사해요~!\n";
    if (_extraItems.isNotEmpty) {
      report += "총 ${f.format(grandTotal)}원 입금 부탁드려요~!\n";
    } else {
      report += "확인 후 입금 부탁드려요~!\n";
    }
    report += "-----------------------------\n";

    // Bank info
    if (!bankInfo.isEmpty) {
      report += bankInfo.displayString;
    }

    Share.share(report);
  }
}
