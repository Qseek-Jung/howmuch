import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ledger_project.dart';
import '../../../../presentation/widgets/horizontal_dial_picker.dart';
import '../../services/excel_service.dart';

class ExcelExportOptionsSheet extends StatefulWidget {
  final LedgerProject project;

  const ExcelExportOptionsSheet({super.key, required this.project});

  @override
  State<ExcelExportOptionsSheet> createState() =>
      _ExcelExportOptionsSheetState();
}

class _ExcelExportOptionsSheetState extends State<ExcelExportOptionsSheet> {
  bool _includeReceipts = true;
  bool _includeSettlement = true;
  bool _includeCharts = true;
  int _selectedRoundUnit = 1000;
  String? _selectedManager;

  @override
  void initState() {
    super.initState();
    if (widget.project.members.isNotEmpty) {
      _selectedManager = widget.project.members.first;
    }
  }

  void _export() {
    final options = ExcelExportOptions(
      includeReceipts: _includeReceipts,
      includeSettlement: _includeSettlement,
      includeCharts: _includeCharts,
      roundingUnit: _selectedRoundUnit,
      managerName: _selectedManager,
    );
    Navigator.pop(context, options);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          // 1. Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 20),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
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
                  "엑셀 다운로드 옵션",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Scrollable Content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              children: [
                _buildSectionContainer(
                  color: sectionColor,
                  isDark: isDark,
                  children: [
                    _buildSwitchRow(
                      "사진 첨부",
                      _includeReceipts,
                      (v) => setState(() => _includeReceipts = v),
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchRow(
                      "1/N 정산",
                      _includeSettlement,
                      (v) => setState(() => _includeSettlement = v),
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchRow(
                      "그래프 추가",
                      _includeCharts,
                      (v) => setState(() => _includeCharts = v),
                      isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_includeSettlement) ...[
                  _buildSectionHeader("정산 상세 설정", isDark),
                  _buildSectionContainer(
                    color: sectionColor,
                    isDark: isDark,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "총무 (뽀찌 수령)",
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black26
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedManager,
                                  isExpanded: true,
                                  dropdownColor: sectionColor,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                  ), // Explicit icon
                                  items: widget.project.members.map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _selectedManager = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDivider(isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withOpacity(opacity),
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
                ],

                // Margin for safe area
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 4. Action Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _export,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D6F42), // Excel Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "다운로드",
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
                  fontSize: 17,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.4,
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: const Color(0xFF34C759),
                onChanged: onChanged,
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
}
