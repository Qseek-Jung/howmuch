import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';
import '../providers/ledger_provider.dart';
import '../../../presentation/home/currency_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/ad_settings_provider.dart';
import '../../../services/admob_service.dart';
import 'widgets/share_report_options_sheet.dart';
import '../services/excel_service.dart';
import 'widgets/excel_export_options_sheet.dart';
import '../../../presentation/widgets/global_banner_ad.dart';

class LedgerReportScreen extends ConsumerStatefulWidget {
  final String projectId;
  const LedgerReportScreen({super.key, required this.projectId});

  @override
  ConsumerState<LedgerReportScreen> createState() => _LedgerReportScreenState();
}

class _LedgerReportScreenState extends ConsumerState<LedgerReportScreen> {
  int _touchedIndex = -1;
  final GlobalKey _categoryChartKey = GlobalKey();
  final GlobalKey _dailyChartKey = GlobalKey();
  final GlobalKey _settlementChartKey = GlobalKey();

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

    final currencyList = ref.watch(currencyListProvider).value ?? [];

    // Determine Target Currency (Main Local Currency)
    final targetCurrencyCode = project.defaultCurrency;
    final isDomestic = targetCurrencyCode == 'KRW';

    double targetRate = 1.0;
    if (!isDomestic) {
      final currency = currencyList.firstWhere(
        (c) => c.code == targetCurrencyCode,
        orElse: () =>
            currencyList.firstWhere((c) => c.code == 'USD'), // Fallback
      );
      targetRate = currency.rateToKrw;
    }

    final totalSpentLocal = isDomestic
        ? totalSpentKrw
        : totalSpentKrw / targetRate;

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
        actions: [],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                        if (isDomestic)
                          Text(
                            "${NumberFormat('#,###').format(totalSpentKrw.round())}원",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          )
                        else ...[
                          Text(
                            "${NumberFormat('#,###').format(totalSpentLocal.round())} $targetCurrencyCode",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "≈ ${NumberFormat('#,###').format(totalSpentKrw.round())}원",
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.white54 : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pie Chart Section
                  RepaintBoundary(
                    key: _categoryChartKey,
                    child: Container(
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
                            aspectRatio: 1.0, // Force square for perfect circle
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection ==
                                                  null) {
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
                                sectionsSpace: 1, // Slight space for separation
                                centerSpaceRadius: 35,
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
                            final amountKrw = e.value;
                            final percentage = totalSpentKrw > 0
                                ? (amountKrw / totalSpentKrw * 100)
                                      .toStringAsFixed(1)
                                : "0";

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ), // Tighter for capture
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getCategoryColor(category),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getCategoryLabel(category),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "$percentage%",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Daily Trend section
                  RepaintBoundary(
                    key: _dailyChartKey,
                    child: Container(
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
                            "일별 지출 추이 (KRW)",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            padding: const EdgeInsets.only(
                              right: 16,
                              top: 16,
                            ), // Padding for axis labels
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY:
                                    _getMaxDailySum(project.expenses) * 1.2 == 0
                                    ? 1000
                                    : _getMaxDailySum(project.expenses) * 1.2,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final sortedDates = _getSortedDates(
                                          project.expenses,
                                        );
                                        if (value.toInt() < 0 ||
                                            value.toInt() >=
                                                sortedDates.length) {
                                          return const SizedBox();
                                        }
                                        final dateStr =
                                            sortedDates[value.toInt()];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            dateStr.substring(5), // MM-dd
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 45,
                                      getTitlesWidget: (value, meta) {
                                        if (value == 0) return const SizedBox();
                                        String label;
                                        if (value >= 10000) {
                                          label =
                                              '${(value / 10000).toStringAsFixed(0)}만';
                                        } else {
                                          label = NumberFormat.compact().format(
                                            value,
                                          );
                                        }
                                        return Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _getBarGroups(
                                  project.expenses,
                                  isDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          "인원별 지출 현황 (1/N)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "정산 금액의 인원별 비중입니다.",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Settlement Pie Chart (Captured for Excel)
                        RepaintBoundary(
                          key: _settlementChartKey,
                          child: Container(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : Colors.white,
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      1.0, // Force square for perfect circle
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 30,
                                      sections: project.members.map((m) {
                                        double mShare = 0;
                                        for (var e in project.expenses) {
                                          if (e.payers.contains(m))
                                            mShare +=
                                                e.amountKrw / e.payers.length;
                                        }
                                        final pct = totalSpentKrw > 0
                                            ? (mShare / totalSpentKrw * 100)
                                            : 0.0;
                                        final idx = project.members.indexOf(m);

                                        // Green Shades Array
                                        final List<Color> greenShades = [
                                          const Color(0xFF34C759), // Green
                                          const Color(0xFF28A745), // Forest
                                          const Color(0xFF5ED87A), // Mint
                                          const Color(0xFF1D6F42), // Excel Dark
                                          const Color(0xFF89E19B), // Pale Green
                                          const Color(0xFF006400), // Dark Green
                                        ];

                                        return PieChartSectionData(
                                          color:
                                              greenShades[idx %
                                                  greenShades.length],
                                          value: mShare,
                                          title: '${pct.toStringAsFixed(0)}%',
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Mini Legend for Settlement Chart
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: project.members.map((m) {
                                    final idx = project.members.indexOf(m);
                                    final List<Color> greenShades = [
                                      const Color(0xFF34C759),
                                      const Color(0xFF28A745),
                                      const Color(0xFF5ED87A),
                                      const Color(0xFF1D6F42),
                                      const Color(0xFF89E19B),
                                      const Color(0xFF006400),
                                    ];
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          color:
                                              greenShades[idx %
                                                  greenShades.length],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          m,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        ...project.members.map((m) {
                          double myShareKrw = 0;
                          for (var e in project.expenses) {
                            if (e.payers.contains(m)) {
                              myShareKrw += e.amountKrw / e.payers.length;
                            }
                          }
                          final myShareLocal = isDomestic
                              ? myShareKrw
                              : myShareKrw / targetRate;

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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isDomestic
                                          ? "${NumberFormat('#,###').format(myShareKrw.round())}원"
                                          : "${NumberFormat('#,###').format(myShareLocal.round())} $targetCurrencyCode",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    if (!isDomestic)
                                      Text(
                                        "≈ ${NumberFormat('#,###').format(myShareKrw.round())}원",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey,
                                        ),
                                      ),
                                  ],
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
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: const Color(0xFF1D6F42), // Excel Green
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          borderRadius: BorderRadius.circular(12),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.doc_text_fill,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "엑셀 다운",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () => _exportExcel(context, project),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          color: const Color(0xFFFEE500), // Kakao Yellow
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          borderRadius: BorderRadius.circular(12),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.chat_bubble_2_fill,
                                color: Colors.black87,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "카톡 공유",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            _showShareOptionsDialog(
                              context,
                              project,
                              totalSpentKrw,
                              categorySums,
                              targetCurrencyCode,
                              targetRate,
                              isDomestic,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          const GlobalBannerAd(),
        ],
      ),
    );
  }

  void _showShareOptionsDialog(
    BuildContext context,
    LedgerProject project,
    double totalSpentKrw,
    Map<ExpenseCategory, double> categorySums,
    String targetCurrencyCode,
    double targetRate,
    bool isDomestic,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareReportOptionsSheet(
        project: project,
        totalSpentKrw: totalSpentKrw,
        categorySums: categorySums,
        targetCurrencyCode: targetCurrencyCode,
        targetRate: targetRate,
        isDomestic: isDomestic,
        settings: ref.read(settingsProvider),
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
        return const Color(0xFF2E7D32); // Dark Green
      case ExpenseCategory.lodging:
        return const Color(0xFF1B5E20); // Darker Green
      case ExpenseCategory.transport:
        return const Color(0xFF43A047); // Standard Green
      case ExpenseCategory.shopping:
        return const Color(0xFF66BB6A); // Light Green
      case ExpenseCategory.tour:
        return const Color(0xFF81C784); // Lighter Green
      case ExpenseCategory.golf:
        return const Color(0xFF004D40); // Teal Green
      case ExpenseCategory.activity:
        return const Color(0xFF00796B); // Dark Teal
      case ExpenseCategory.medical:
        return const Color(0xFFA5D6A7); // Very Light Green
      case ExpenseCategory.etc:
        return const Color(0xFFC8E6C9); // Pale Green
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

  Future<void> _exportExcel(BuildContext context, LedgerProject project) async {
    try {
      // 1. Show Options Sheet
      final ExcelExportOptions? options =
          await showModalBottomSheet<ExcelExportOptions>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ExcelExportOptionsSheet(project: project),
          );

      if (options == null) return; // User cancelled

      // 2. Show interstitial ad before Excel generation
      if (!context.mounted) return;
      final adSettings = ref.read(adSettingsProvider.notifier);
      final shouldShowAd = adSettings.shouldShowAd();

      if (shouldShowAd) {
        AdMobService.instance.showInterstitialAd(
          onAdDismissed: () => _generateExcelFile(context, project, options),
        );
      } else {
        await _generateExcelFile(context, project, options);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  /// Generate and share Excel file after ad is shown
  Future<void> _generateExcelFile(
    BuildContext context,
    LedgerProject project,
    ExcelExportOptions options,
  ) async {
    try {
      // Show loading
      if (!context.mounted) return;
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CupertinoActivityIndicator()),
      );

      List<int>? catBytes;
      List<int>? dailyBytes;
      List<int>? settlementBytes;
      if (options.includeCharts) {
        catBytes = await _captureChart(_categoryChartKey);
        dailyBytes = await _captureChart(_dailyChartKey);
        settlementBytes = await _captureChart(_settlementChartKey);
      }

      final excelService = ref.read(excelServiceProvider);
      final filePath = await excelService.generateProjectReport(
        project,
        options: options,
        categoryChartBytes: catBytes,
        dailyChartBytes: dailyBytes,
        settlementChartBytes: settlementBytes,
      );

      // Dismiss loading
      Navigator.pop(context);

      // Share File
      await Share.shareXFiles([
        XFile(filePath),
      ], text: "Ledger Report for ${project.title}");
    } catch (e) {
      // Dismiss loading if active (checking if context is valid/can pop is safer but keep simpler)
      // Usually we track loading state. For now, try pop.
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  Future<Uint8List?> _captureChart(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Chart capture error: $e");
      return null;
    }
  }

  double _getMaxDailySum(List<LedgerExpense> expenses) {
    if (expenses.isEmpty) return 0;
    final Map<String, double> sums = {};
    final df = DateFormat('yyyy-MM-dd');
    for (var e in expenses) {
      final d = df.format(e.date);
      sums[d] = (sums[d] ?? 0) + e.amountKrw;
    }
    return sums.values.fold(0, (max, v) => v > max ? v : max);
  }

  List<String> _getSortedDates(List<LedgerExpense> expenses) {
    final df = DateFormat('yyyy-MM-dd');
    final dates = expenses.map((e) => df.format(e.date)).toSet().toList();
    dates.sort();
    return dates;
  }

  List<BarChartGroupData> _getBarGroups(
    List<LedgerExpense> expenses,
    bool isDark,
  ) {
    final sortedDates = _getSortedDates(expenses);
    final Map<String, double> sums = {};
    final df = DateFormat('yyyy-MM-dd');
    for (var e in expenses) {
      final d = df.format(e.date);
      sums[d] = (sums[d] ?? 0) + e.amountKrw;
    }

    return List.generate(sortedDates.length, (index) {
      final d = sortedDates[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: sums[d]!,
            color: const Color(0xFF28A745), // Unified Green
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxDailySum(expenses) * 1.2,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
        ],
      );
    });
  }
}
