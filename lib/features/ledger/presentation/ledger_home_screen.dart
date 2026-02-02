import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/ledger_provider.dart';
import '../../../presentation/home/currency_provider.dart';
import '../models/ledger_project.dart';
import 'project_creation_sheet.dart';
import 'ledger_detail_screen.dart';
import '../../../core/design_system.dart';
// For now, placeholder navigation.

class LedgerHomeScreen extends ConsumerStatefulWidget {
  const LedgerHomeScreen({super.key});

  @override
  ConsumerState<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends ConsumerState<LedgerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Logic for auto-entry will be here
    // However, since we are in a tab view, pushing immediately might be abrupt if not handled carefully.
    // Let's do it in PostFrameCallback if needed.
    // For now, let's just show the list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoEnter();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkAutoEnter() {
    final ledgerNotifier = ref.read(ledgerProvider.notifier);
    final activeProject = ledgerNotifier.getActiveProjectForDate(
      DateTime.now(),
    );

    if (activeProject != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LedgerDetailScreen(project: activeProject),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(ledgerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Filter
    final filtered = projects.where((p) {
      return p.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. SMART SORT: Active trips first, then by date proximity
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    filtered.sort((a, b) {
      // Check if projects are active (today is within date range)
      final aStart = DateTime(
        a.startDate.year,
        a.startDate.month,
        a.startDate.day,
      );
      final aEnd = DateTime(a.endDate.year, a.endDate.month, a.endDate.day);
      final aIsActive = !today.isBefore(aStart) && !today.isAfter(aEnd);

      final bStart = DateTime(
        b.startDate.year,
        b.startDate.month,
        b.startDate.day,
      );
      final bEnd = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
      final bIsActive = !today.isBefore(bStart) && !today.isAfter(bEnd);

      // Active projects come first
      if (aIsActive && !bIsActive) return -1;
      if (!aIsActive && bIsActive) return 1;

      // If both active or both inactive, sort by date proximity
      // Calculate distance from today
      int aDistance = _getDateDistance(today, a.startDate, a.endDate);
      int bDistance = _getDateDistance(today, b.startDate, b.endDate);

      return aDistance.compareTo(bDistance);
    });

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          "여계부",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.add,
              color: isDark ? Colors.white : AppColors.primary,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ProjectCreationSheet(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: "여행 검색",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              itemColor: isDark
                  ? Colors.white54
                  : CupertinoColors.secondaryLabel,
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(filtered[index], isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Calculate distance from today to the nearest date in the project range
  /// Returns absolute days difference
  int _getDateDistance(DateTime today, DateTime startDate, DateTime endDate) {
    // If today is within range, distance is 0
    if (!today.isBefore(startDate) && !today.isAfter(endDate)) {
      return 0;
    }

    // If today is before start, return days until start
    if (today.isBefore(startDate)) {
      return startDate.difference(today).inDays;
    }

    // If today is after end, return days since end
    return today.difference(endDate).inDays;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text_search,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "등록된 여행이 없습니다",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ProjectCreationSheet(),
              );
            },
            child: const Text("새 여행 시작하기"),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(LedgerProject project, bool isDark) {
    final f = DateFormat('yyyy.MM.dd');
    final currencyFormat = NumberFormat('#,###');

    // Check if project is active (today is within date range)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pStart = DateTime(
      project.startDate.year,
      project.startDate.month,
      project.startDate.day,
    );
    final pEnd = DateTime(
      project.endDate.year,
      project.endDate.month,
      project.endDate.day,
    );
    final isActive = !today.isBefore(pStart) && !today.isAfter(pEnd);

    // Calculate total spend (simple sum of converted KRW for preview)
    double totalSpent = 0;
    for (var e in project.expenses) {
      totalSpent += e.amountKrw;
    }

    return Slidable(
      key: ValueKey(project.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _confirmDeleteProject(project),
            backgroundColor: CupertinoColors.destructiveRed,
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
            onPressed: (context) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    ProjectCreationSheet(projectToEdit: project),
              );
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.pencil,
            label: '수정',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LedgerDetailScreen(project: project),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDesign.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Active indicator badge
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '진행중',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            project.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: isActive
                                  ? FontWeight.w900
                                  : FontWeight.w700, // Bold if active
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (project.countries.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        project.countries.join(", "),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${f.format(project.startDate)} ~ ${f.format(project.endDate)}",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${project.members.length}인 ${project.tripPurpose}", // "1인 여행", "2인 출장" 등
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                  Text(
                    "총 ${currencyFormat.format(totalSpent.round())}원",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextGreen(isDark), // Brand Green
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteProject(LedgerProject project) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("여행 삭제"),
        content: Text("'${project.title}' 여행의 모든 기록이 삭제됩니다. 계속하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("삭제"),
            onPressed: () {
              ref.read(ledgerProvider.notifier).deleteProject(project.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
