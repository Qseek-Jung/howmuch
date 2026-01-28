import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';
import '../providers/ledger_provider.dart';

class LedgerReportScreen extends ConsumerStatefulWidget {
  final String projectId;
  const LedgerReportScreen({super.key, required this.projectId});

  @override
  ConsumerState<LedgerReportScreen> createState() => _LedgerReportScreenState();
}

class _LedgerReportScreenState extends ConsumerState<LedgerReportScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Watch provider to get the latest project state
    final projects = ref.watch(ledgerProvider);
    final project = projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => LedgerProject(
        id: "",
        title: "",
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        countries: [],
        members: [],
        defaultCurrency: "KRW",
        expenses: [],
      ),
    );

    if (project.id.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSpentKrw = project.expenses.fold(
      0.0,
      (sum, e) => sum + e.amountKrw,
    );
    final categorySums = _calculateCategorySums(project.expenses);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          "리포트",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Total Spend Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "총 사용 금액",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${NumberFormat('#,###').format(totalSpentKrw.round())}원",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pie Chart Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "카테고리별 지출",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: _showingSections(
                          categorySums,
                          totalSpentKrw,
                          isDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legend List
                  ...categorySums.entries.map((e) {
                    final category = e.key;
                    final amount = e.value;
                    final percentage = totalSpentKrw > 0
                        ? (amount / totalSpentKrw * 100).toStringAsFixed(1)
                        : "0";

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getCategoryColor(category),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getCategoryLabel(category),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${NumberFormat('#,###').format(amount.round())}원 ($percentage%)",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settlement Section (Simple 1/N)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "정산 (1/N 단순계산)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...project.members.map((m) {
                    // Calculate share: Sum of (expenseAmount / payersCount) for expenses where user is a payer
                    double myShare = 0;
                    for (var e in project.expenses) {
                      if (e.payers.contains(m)) {
                        myShare += e.amountKrw / e.payers.length;
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            "${NumberFormat('#,###').format(myShare.round())}원",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Kakao Share Button
            CupertinoButton(
              color: const Color(0xFFFEE500), // Kakao Yellow
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: BorderRadius.circular(12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.share, color: Colors.black87, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "카카오톡으로 리포트 공유",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              onPressed: () {
                _shareReport(project, totalSpentKrw, categorySums);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Map<ExpenseCategory, double> _calculateCategorySums(
    List<LedgerExpense> expenses,
  ) {
    final Map<ExpenseCategory, double> sums = {};
    for (var e in expenses) {
      sums[e.category] = (sums[e.category] ?? 0) + e.amountKrw;
    }
    // Sort keys by amount descending for chart consistency
    final sortedEntries = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  List<PieChartSectionData> _showingSections(
    Map<ExpenseCategory, double> sums,
    double total,
    bool isDark,
  ) {
    return sums.entries.map((entry) {
      final isTouched = sums.keys.toList().indexOf(entry.key) == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final value = entry.value;
      final percentage = total > 0 ? (value / total * 100) : 0;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.food:
        return const Color(0xFFFF9F0A); // Orange
      case ExpenseCategory.lodging:
        return const Color(0xFF5E5CE6); // Indigo
      case ExpenseCategory.transport:
        return const Color(0xFF30D158); // Green
      case ExpenseCategory.shopping:
        return const Color(0xFFBF5AF2); // Purple
      case ExpenseCategory.tour:
        return const Color(0xFF0A84FF); // Blue
      case ExpenseCategory.etc:
        return const Color(0xFF8E8E93); // Grey
    }
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
      case ExpenseCategory.etc:
        return "기타";
    }
  }

  void _shareReport(
    LedgerProject project,
    double total,
    Map<ExpenseCategory, double> sums,
  ) {
    final buffer = StringBuffer();
    buffer.writeln("[여계부 리포트]");
    buffer.writeln("여행: ${project.title}");
    buffer.writeln(
      "기간: ${DateFormat('yyyy.MM.dd').format(project.startDate)} ~ ${DateFormat('yyyy.MM.dd').format(project.endDate)}",
    );
    buffer.writeln("총 지출: ${NumberFormat('#,###').format(total.round())}원");
    buffer.writeln("\n<카테고리별 지출>");
    for (var entry in sums.entries) {
      final percentage = total > 0
          ? (entry.value / total * 100).toStringAsFixed(1)
          : "0";
      buffer.writeln(
        "- ${_getCategoryLabel(entry.key)}: ${NumberFormat('#,###').format(entry.value.round())}원 ($percentage%)",
      );
    }

    buffer.writeln("\n<정산 (1/N)>");
    for (var m in project.members) {
      double myShare = 0;
      for (var e in project.expenses) {
        if (e.payers.contains(m)) {
          myShare += e.amountKrw / e.payers.length;
        }
      }
      buffer.writeln("- $m: ${NumberFormat('#,###').format(myShare.round())}원");
    }

    Share.share(buffer.toString());
  }
}
