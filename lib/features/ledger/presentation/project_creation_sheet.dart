import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/currency_data.dart';
import '../../../presentation/home/currency_provider.dart';
import '../../../presentation/currency_manage_screen.dart';
import '../providers/ledger_provider.dart';
import '../models/ledger_project.dart';

class ProjectCreationSheet extends ConsumerStatefulWidget {
  const ProjectCreationSheet({super.key});

  @override
  ConsumerState<ProjectCreationSheet> createState() =>
      _ProjectCreationSheetState();
}

class _ProjectCreationSheetState extends ConsumerState<ProjectCreationSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();

  // Date Range
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 4)),
  );

  final List<String> _members = ["나"];

  // Country & Currency pair
  String? _selectedCountryName;
  String _selectedCurrencyCode = "KRW"; // Default fallback
  final List<String> _selectedCurrencies = ["KRW"];

  void _addMember() {
    if (_memberController.text.isNotEmpty) {
      setState(() {
        _members.add(_memberController.text);
        _memberController.clear();
      });
    }
  }

  void _createProject() {
    if (_titleController.text.isEmpty) return;

    final newProject = LedgerProject(
      id: const Uuid().v4(),
      title: _titleController.text,
      startDate: _selectedDateRange.start,
      endDate: _selectedDateRange.end,
      countries: _selectedCurrencies,
      members: _members,
      defaultCurrency: _selectedCurrencyCode,
      expenses: [],
      subProjects: [],
    );

    ref.read(ledgerProvider.notifier).createProject(newProject);
    Navigator.pop(context);
  }

  void _showCurrencyPicker() {
    final favoriteCodes = ref.read(favoriteCurrenciesProvider);

    if (favoriteCodes.isEmpty) {
      _showNoFavoritesDialog();
      return;
    }

    // Create list of {name, code}
    final items = favoriteCodes.map((code) {
      final name = CurrencyData.getCountryName(code);
      return {'name': name, 'code': code};
    }).toList();

    int tempIndex = 0;
    // Try to find current selection index
    final currentIndex = items.indexWhere(
      (i) => i['code'] == _selectedCurrencyCode,
    );
    if (currentIndex >= 0) tempIndex = currentIndex;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
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
                      _navigateToManage();
                    },
                  ),
                  const Text(
                    "국가 선택",
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
                      setState(() {
                        _selectedCountryName = selected['name']!;
                        _selectedCurrencyCode = selected['code']!;
                        _selectedCurrencies.clear();
                        _selectedCurrencies.add(_selectedCurrencyCode);

                        // Auto-fill title if empty
                        if (_titleController.text.isEmpty) {
                          _titleController.text = "$_selectedCountryName 여행";
                        }
                      });
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
                children: items.map((item) {
                  return Center(
                    child: Text(
                      "${item['name']} (${item['code']})",
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoFavoritesDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("즐겨찾기 없음"),
        content: const Text("선택할 수 있는 국가가 없습니다.\n관리 화면에서 국가를 추가해주세요."),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("관리 페이지로 이동"),
            onPressed: () {
              Navigator.pop(context);
              _navigateToManage();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToManage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CurrencyManageScreen(isSelectionMode: true),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedCountryName = result['name'];
        _selectedCurrencyCode = result['currency'];
        _selectedCurrencies.clear();
        _selectedCurrencies.add(_selectedCurrencyCode);

        // Auto-fill title if empty
        if (_titleController.text.isEmpty) {
          _titleController.text = "$_selectedCountryName 여행";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final f = DateFormat('yyyy.MM.dd');

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "새 여행 시작하기",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Colors.grey,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title Input
          CupertinoTextField(
            controller: _titleController,
            placeholder: "여행 이름 (예: 이탈리아 여행)",
            padding: const EdgeInsets.all(16),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // Date Selection (Range Picker)
          GestureDetector(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: _selectedDateRange,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: isDark ? ThemeData.dark() : ThemeData.light(),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDateRange = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "여행 기간",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  Text(
                    "${f.format(_selectedDateRange.start)} ~ ${f.format(_selectedDateRange.end)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Country Selection
          GestureDetector(
            onTap: _showCurrencyPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "여행할 국가",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _selectedCountryName ?? "국가 선택",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedCountryName == null
                              ? CupertinoColors.systemBlue
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Show currency if selected
          if (_selectedCountryName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Text(
                "사용 통화: $_selectedCurrencyCode",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 20),

          // Members
          Text(
            "동행자",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ..._members.map(
                (m) => Chip(
                  label: Text(m),
                  onDeleted: m == "나"
                      ? null
                      : () {
                          setState(() {
                            _members.remove(m);
                          });
                        },
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  deleteIconColor: Colors.grey,
                ),
              ),
              ActionChip(
                label: const Icon(Icons.add, size: 16),
                onPressed: _showAddMemberDialog,
                backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Create Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _createProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "여계부 생성",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("동행자 추가"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: _memberController,
            placeholder: "이름 입력",
            autofocus: true,
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
              _addMember();
              Navigator.pop(context);
            },
            child: const Text("추가"),
          ),
        ],
      ),
    );
  }
}
