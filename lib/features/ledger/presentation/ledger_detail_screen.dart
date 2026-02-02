import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';
import '../providers/ledger_provider.dart';
import 'expense_add_sheet.dart';
import 'ledger_report_screen.dart';
import '../../../core/design_system.dart';
import 'widgets/report_icon_painter.dart';
import '../../../presentation/widgets/global_banner_ad.dart';

class LedgerDetailScreen extends ConsumerStatefulWidget {
  final LedgerProject project;

  const LedgerDetailScreen({super.key, required this.project});

  @override
  ConsumerState<LedgerDetailScreen> createState() => _LedgerDetailScreenState();
}

class _LedgerDetailScreenState extends ConsumerState<LedgerDetailScreen> {
  // Group expenses by date (yyyyMMdd string key)
  Map<String, List<LedgerExpense>> _groupExpensesByDate(
    List<LedgerExpense> expenses,
  ) {
    if (expenses.isEmpty) return {};

    // Sort by date descending (newest first)
    expenses.sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<LedgerExpense>> grouped = {};
    for (var e in expenses) {
      final key = DateFormat('yyyyMMdd').format(e.date);
      if (grouped[key] == null) grouped[key] = [];
      grouped[key]!.add(e);
    }
    return grouped;
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseAddSheet(projectId: widget.project.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to get real-time updates for this specific project
    final projects = ref.watch(ledgerProvider);
    // Find the current version of this project from the list
    final project = projects.firstWhere(
      (p) => p.id == widget.project.id,
      orElse: () => widget
          .project, // Fallback if deleted (though screen should handle pop)
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupedExpenses = _groupExpensesByDate(project.expenses);
    final sortedKeys = groupedExpenses.keys
        .toList(); // Already sorted descending by logic above? No, map keys not guaranteed.
    // Let's sort keys descending
    sortedKeys.sort((a, b) => b.compareTo(a));

    double totalSpentKrw = project.expenses.fold(
      0,
      (sum, e) => sum + e.amountKrw,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          project.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LedgerReportScreen(projectId: project.id),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 32,
              height: 32,
              child: CustomPaint(painter: ReportIconPainter(isDark: isDark)),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black,
            ),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteProject(context, project.id);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('여행 삭제', style: TextStyle(color: Colors.red)),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTotalHeader(project, totalSpentKrw, isDark),
          _buildDateFilter(project, isDark), // New Date Filter
          Expanded(
            child: project.expenses.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      // Filter logic
                      if (_selectedDateFilter != null) {
                        final filterKey = DateFormat(
                          'yyyyMMdd',
                        ).format(_selectedDateFilter!);
                        if (dateKey != filterKey)
                          return const SizedBox.shrink();
                      }

                      final expenses = groupedExpenses[dateKey]!;
                      return _buildDailySection(
                        dateKey,
                        expenses,
                        project.startDate,
                        isDark,
                        project.id,
                        project.defaultCurrency,
                      );
                    },
                  ),
          ),
          const GlobalBannerAd(),
        ],
      ),
      floatingActionButton: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () => _showAddExpenseSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: AppDesign.primaryGradientDecoration(isDark),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.add, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "지출 추가",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // State for filter
  DateTime? _selectedDateFilter;

  Widget _buildDateFilter(LedgerProject project, bool isDark) {
    // Generate dates: Start to End (plus 7 days buffer or based on actual expenses)
    // Minimal range: Project Start ~ End.
    // If expenses exist outside, include them? The user requested "Include dates if expenses exist before/after".

    DateTime minDate = project.startDate;
    DateTime maxDate = project.endDate;

    if (project.expenses.isNotEmpty) {
      final expensesStart = project.expenses
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final expensesEnd = project.expenses
          .map((e) => e.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (expensesStart.isBefore(minDate)) minDate = expensesStart;
      if (expensesEnd.isAfter(maxDate)) maxDate = expensesEnd;
    }

    final daysCovers = maxDate.difference(minDate).inDays + 1;
    final exactDates = List.generate(
      daysCovers,
      (i) => minDate.add(Duration(days: i)),
    );

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: exactDates.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" button
            final isSelected = _selectedDateFilter == null;
            return GestureDetector(
              onTap: () => setState(() => _selectedDateFilter = null),
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: AppDesign.selectionDecoration(
                  isSelected: isSelected,
                  isDark: isDark,
                ),
                child: Text(
                  "전체",
                  style: AppDesign.selectionTextStyle(
                    isSelected: isSelected,
                    isDark: isDark,
                  ),
                ),
              ),
            );
          }
          final date = exactDates[index - 1];
          final dateStr = DateFormat('yyyyMMdd').format(date);
          final isSelected =
              _selectedDateFilter != null &&
              DateFormat('yyyyMMdd').format(_selectedDateFilter!) == dateStr;

          final hasExpense = project.expenses.any(
            (e) => DateFormat('yyyyMMdd').format(e.date) == dateStr,
          );

          return GestureDetector(
            onTap: () => setState(() => _selectedDateFilter = date),
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration:
                  AppDesign.selectionDecoration(
                    isSelected: isSelected,
                    isDark: isDark,
                  ).copyWith(
                    border: hasExpense && !isSelected
                        ? Border.all(
                            color: isDark
                                ? AppColors.getPrimary(isDark).withOpacity(0.3)
                                : AppColors.getPrimary(isDark).withOpacity(0.2),
                            width: 1,
                          )
                        : null,
                  ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MM.dd').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: hasExpense
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.getPrimary(isDark).withOpacity(0.6)
                          : (hasExpense
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : Colors.grey),
                    ),
                  ),
                  Text(
                    DateFormat('E', 'ko_KR').format(date),
                    style:
                        AppDesign.selectionTextStyle(
                          isSelected: isSelected,
                          isDark: isDark,
                        ).copyWith(
                          fontSize: 13,
                          fontWeight: isSelected || hasExpense
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                  if (hasExpense)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.getPrimary(isDark)
                            : AppColors.getPrimary(isDark).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalHeader(
    LedgerProject project,
    double totalKrw,
    bool isDark,
  ) {
    final currencyFormat = NumberFormat('#,###');
    final localCurrencyFormat = NumberFormat('#,###.##');

    double totalLocal = project.expenses.fold(0.0, (sum, e) {
      if (e.currencyCode == project.defaultCurrency) {
        return sum + e.amountLocal;
      }
      return sum; // Skip or handle multiple currencies if needed
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "총 지출",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (project.defaultCurrency != "KRW" && totalLocal > 0) ...[
            Text(
              "${localCurrencyFormat.format(totalLocal)} ${project.defaultCurrency}",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "≈ ${currencyFormat.format(totalKrw.round())}원",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.getTextGreen(isDark)
                    : AppColors.getTextGreen(isDark),
              ),
            ),
          ] else
            Text(
              "${currencyFormat.format(totalKrw.round())}원",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -1.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailySection(
    String dateKey,
    List<LedgerExpense> expenses,
    DateTime projectStart,
    bool isDark,
    String projectId,
    String defaultCurrency,
  ) {
    final date = DateTime.parse(dateKey);
    final diff =
        date
            .difference(
              DateTime(projectStart.year, projectStart.month, projectStart.day),
            )
            .inDays +
        1;
    final dayLabel = "Day $diff";
    final f = DateFormat('MM.dd (E)', 'ko_KR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f.format(date),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: expenses
                .map((e) => _buildExpenseItem(e, isDark, projectId))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(
    LedgerExpense expense,
    bool isDark,
    String projectId,
  ) {
    return Slidable(
      key: Key(expense.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) =>
                _deleteWithConfirmation(context, projectId, expense.id),
            backgroundColor: const Color(0xFFFE3B30), // iOS Red
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _updateExpense(expense),
            backgroundColor: AppColors.primary, // iOS Blue replaced with Green
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '수정',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: _getCategoryIcon(expense.category, isDark),
        ),
        title: Text(
          expense.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: _buildSubtitle(expense, isDark),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${NumberFormat('#,###').format(expense.amountKrw.round())}원",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w900, // Extra bold for KRW total as requested
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (expense.receiptPaths.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.receipt, size: 10, color: Colors.grey),
              ),
          ],
        ),
        onTap: () => _updateExpense(expense),
      ),
    );
  }

  void _deleteWithConfirmation(
    BuildContext context,
    String projectId,
    String expenseId,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("지출 삭제"),
        content: const Text("이 내역을 삭제하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("삭제"),
            onPressed: () {
              ref
                  .read(ledgerProvider.notifier)
                  .deleteExpense(projectId, expenseId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _updateExpense(LedgerExpense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ExpenseAddSheet(projectId: widget.project.id, expenseToEdit: expense),
    );
  }

  Widget _getCategoryIcon(ExpenseCategory category, bool isDark) {
    IconData icon;
    switch (category) {
      case ExpenseCategory.food:
        icon = Icons.restaurant;
        break;
      case ExpenseCategory.lodging:
        icon = Icons.hotel;
        break;
      case ExpenseCategory.transport:
        icon = Icons.directions_bus;
        break;
      case ExpenseCategory.shopping:
        icon = Icons.shopping_bag;
        break;
      case ExpenseCategory.tour:
        icon = Icons.camera_alt;
        break;
      case ExpenseCategory.golf:
        icon = Icons.golf_course;
        break;
      case ExpenseCategory.activity:
        icon = Icons.surfing;
        break;
      case ExpenseCategory.medical:
        icon = Icons.medical_services;
        break;
      case ExpenseCategory.etc:
        icon = Icons.more_horiz;
        break;
    }
    return Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87);
  }

  Widget? _buildSubtitle(LedgerExpense expense, bool isDark) {
    final hasForeignAmount =
        expense.amountLocal > 0 && expense.currencyCode != "KRW";
    final hasMemo = expense.memo != null && expense.memo!.isNotEmpty;

    // Get payment method label
    String methodLabel = "";
    switch (expense.paymentMethod) {
      case PaymentMethod.cash:
        methodLabel = "현금";
        break;
      case PaymentMethod.card:
        methodLabel = "카드";
        break;
      case PaymentMethod.appPay:
        methodLabel = "앱페이";
        break;
      case PaymentMethod.etc:
        methodLabel = "기타";
        break;
    }

    String text = "";
    if (hasForeignAmount) {
      text +=
          "${NumberFormat('#,###.##').format(expense.amountLocal)} ${expense.currencyCode}";
    }

    if (text.isNotEmpty) {
      text += " • $methodLabel";
    } else {
      text = methodLabel;
    }

    if (hasMemo) {
      text += " | ${expense.memo}";
    }

    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white54 : Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.w500,
        overflow: TextOverflow.ellipsis,
      ),
      maxLines: 1,
    );
  }

  void _confirmDeleteProject(BuildContext context, String projectId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("여행 삭제"),
        content: const Text("정말로 이 여행 기록을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다."),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("삭제"),
            onPressed: () {
              ref.read(ledgerProvider.notifier).deleteProject(projectId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.money_dollar_circle,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "아직 지출 내역이 없습니다",
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
