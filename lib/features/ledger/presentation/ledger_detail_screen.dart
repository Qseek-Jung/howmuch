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
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          project.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.trash,
              color: isDark ? Colors.white : Colors.red,
            ),
            onPressed: () => _deleteProject(context, project.id),
          ),
          IconButton(
            icon: Icon(
              CupertinoIcons.settings,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => _showMemberSettings(context, project),
          ),
          IconButton(
            icon: Icon(
              CupertinoIcons.chart_pie_fill,
              color: isDark ? Colors.white : const Color(0xFF1A237E),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LedgerReportScreen(projectId: project.id),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTotalHeader(totalSpentKrw, isDark),
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
                        project.id, // Need projectId for actions
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text(
          "지출 추가",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A237E)
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "전체",
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          final date = exactDates[index - 1];
          final isSelected =
              _selectedDateFilter != null &&
              DateFormat('yyyyMMdd').format(_selectedDateFilter!) ==
                  DateFormat('yyyyMMdd').format(date);

          return GestureDetector(
            onTap: () => setState(() => _selectedDateFilter = date),
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A237E)
                    : (isDark ? Colors.white10 : Colors.grey[200]),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MM.dd').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  Text(
                    DateFormat('E', 'ko_KR').format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.bold,
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

  Widget _buildTotalHeader(double total, bool isDark) {
    final currencyFormat = NumberFormat('#,###');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "총 지출",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${currencyFormat.format(total.round())}원",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
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

    double dailyTotal = expenses.fold(0, (sum, e) => sum + e.amountKrw);

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
              Text(
                "${NumberFormat('#,###').format(dailyTotal.round())}원",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
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
            backgroundColor: const Color(0xFF0A84FF), // iOS Blue
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
        subtitle: expense.amountLocal > 0 && expense.currencyCode != "KRW"
            ? Text(
                "${NumberFormat('#,###.##').format(expense.amountLocal)} ${expense.currencyCode}",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 13,
                ),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${NumberFormat('#,###').format(expense.amountKrw.round())}원",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (expense.receiptPath != null)
              const Icon(Icons.receipt, size: 12, color: Colors.grey),
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
      case ExpenseCategory.etc:
        icon = Icons.more_horiz;
        break;
    }
    return Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87);
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

  void _deleteProject(BuildContext context, String projectId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("여행 삭제"),
        content: const Text("정말로 이 여행을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다."),
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

  void _showMemberSettings(BuildContext context, LedgerProject project) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Text(
              "동행자 관리",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: project.members.length,
                itemBuilder: (context, index) {
                  final member = project.members[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(member[0])),
                    title: Text(member),
                    trailing: TextButton.icon(
                      icon: const Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        size: 16,
                      ),
                      label: const Text("카카오톡 연결"),
                      onPressed: () {
                        // Mock Kakao Connection
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("$member 님에게 카카오톡 초대 메시지를 보냈습니다."),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showMemberActionSheet(context, member);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberActionSheet(BuildContext context, String member) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text("$member 설정"),
        actions: [
          CupertinoActionSheetAction(
            child: const Text("수동 입력 (현재 상태)"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoActionSheetAction(
            child: const Text("카카오톡으로 초대/연결"),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("카카오톡 연결 요청을 보냈습니다.")),
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text("취소"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
