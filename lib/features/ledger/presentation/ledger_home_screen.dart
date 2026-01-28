import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/ledger_provider.dart';
import '../models/ledger_project.dart';
import 'project_creation_sheet.dart';
import 'ledger_detail_screen.dart';
// For now, placeholder navigation.

class LedgerHomeScreen extends ConsumerStatefulWidget {
  const LedgerHomeScreen({super.key});

  @override
  ConsumerState<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends ConsumerState<LedgerHomeScreen> {
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
        backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.add,
              color: isDark ? Colors.white : CupertinoColors.activeBlue,
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
      body: projects.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return _buildProjectCard(projects[index], isDark);
              },
            ),
    );
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
          CupertinoButton(
            child: const Text("새 여행 시작하기"),
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
    );
  }

  Widget _buildProjectCard(LedgerProject project, bool isDark) {
    final f = DateFormat('yyyy.MM.dd');
    final currencyFormat = NumberFormat('#,###');

    // Calculate total spend (simple sum of converted KRW for preview)
    double totalSpent = 0;
    for (var e in project.expenses) {
      totalSpent += e.amountKrw;
    }

    return GestureDetector(
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
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  child: Text(
                    project.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
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
                  "${project.members.length}명 함께",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
                Text(
                  "총 ${currencyFormat.format(totalSpent.round())}원",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A237E), // Brand Blue
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
