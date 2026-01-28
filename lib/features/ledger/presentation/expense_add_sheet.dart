import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';
import '../providers/ledger_provider.dart';
import '../../../presentation/currency_manage_screen.dart';

class ExpenseAddSheet extends ConsumerStatefulWidget {
  final String projectId;
  final LedgerExpense? expenseToEdit; // If provided, Edit Mode

  const ExpenseAddSheet({
    super.key,
    required this.projectId,
    this.expenseToEdit,
  });

  @override
  ConsumerState<ExpenseAddSheet> createState() => _ExpenseAddSheetState();
}

class _ExpenseAddSheetState extends ConsumerState<ExpenseAddSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.food;

  // Logic for currency
  String _selectedCurrency = "KRW";
  double _exchangeRate = 1.0;

  List<String> _selectedPayers = [];

  // Receipt Image
  XFile? _receiptImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final project = ref
          .read(ledgerProvider)
          .firstWhere((p) => p.id == widget.projectId);

      if (widget.expenseToEdit != null) {
        // Edit Mode: Pre-fill
        final e = widget.expenseToEdit!;
        _titleController.text = e.title;

        // Amount Logic: Display Local if foreign, else KRW
        double displayAmount = e.currencyCode == "KRW"
            ? e.amountKrw
            : e.amountLocal;
        // Format effectively triggers UI update if we want formatted,
        // but controller expects raw string for editing usually, or simple number.
        // Let's strip decimals if .0
        _amountController.text = displayAmount.remainder(1) == 0
            ? displayAmount.toInt().toString()
            : displayAmount.toString();

        setState(() {
          _selectedDate = e.date;
          _selectedCategory = e.category;
          _selectedCurrency = e.currencyCode;
          _exchangeRate = e.exchangeRate;
          _selectedPayers = List.from(e.payers);
          if (e.receiptPath != null) {
            _receiptImage = XFile(e.receiptPath!);
          }
        });
      } else {
        // Add Mode: Defaults
        setState(() {
          _selectedPayers = List.from(project.members);
          _selectedCurrency = project.defaultCurrency;
          _setDefaultExchangeRate();
        });
      }
    });
  }

  void _setDefaultExchangeRate() {
    if (_selectedCurrency == "EUR")
      _exchangeRate = 1450.0;
    else if (_selectedCurrency == "USD")
      _exchangeRate = 1350.0;
    else if (_selectedCurrency == "JPY")
      _exchangeRate = 9.0;
    else
      _exchangeRate = 1.0;
  }

  Future<void> _pickReceiptImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _receiptImage = photo;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _saveExpense() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;

    // Remove commas
    final cleanAmount = _amountController.text.replaceAll(',', '');
    final amountLocal = double.tryParse(cleanAmount) ?? 0;

    // Calculate KRW
    double amountKrw = 0;
    if (_selectedCurrency == "KRW") {
      amountKrw = amountLocal;
      _exchangeRate = 1.0;
    } else {
      amountKrw = amountLocal * _exchangeRate;
    }

    if (widget.expenseToEdit != null) {
      // Update
      final updatedExpense = LedgerExpense(
        id: widget.expenseToEdit!.id, // Keep ID
        date: _selectedDate,
        category: _selectedCategory,
        title: _titleController.text,
        amountLocal: _selectedCurrency == "KRW" ? 0 : amountLocal,
        currencyCode: _selectedCurrency,
        exchangeRate: _exchangeRate,
        amountKrw: amountKrw,
        paymentMethod: widget.expenseToEdit!.paymentMethod,
        payers: _selectedPayers,
        receiptPath: _receiptImage?.path,
      );
      ref
          .read(ledgerProvider.notifier)
          .updateExpense(widget.projectId, updatedExpense);
    } else {
      // Create
      final newExpense = LedgerExpense(
        id: const Uuid().v4(),
        date: _selectedDate,
        category: _selectedCategory,
        title: _titleController.text,
        amountLocal: _selectedCurrency == "KRW" ? 0 : amountLocal,
        currencyCode: _selectedCurrency,
        exchangeRate: _exchangeRate,
        amountKrw: amountKrw,
        paymentMethod: PaymentMethod.cash,
        payers: _selectedPayers,
        receiptPath: _receiptImage?.path,
      );
      ref
          .read(ledgerProvider.notifier)
          .addExpense(widget.projectId, newExpense);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final project = ref
        .watch(ledgerProvider)
        .firstWhere(
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              Text(
                widget.expenseToEdit != null ? "지출 수정" : "지출 기록",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              TextButton(
                onPressed: _saveExpense,
                child: const Text(
                  "저장",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Amount Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                      // Currency Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CurrencyManageScreen(
                                  isSelectionMode: true,
                                ),
                              ),
                            );
                            if (result != null && result is Map) {
                              setState(() {
                                _selectedCurrency = result['currency'];
                                _setDefaultExchangeRate();
                              });
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedCurrency,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Sub-info for KRW conversion
                  if (_selectedCurrency != "KRW")
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          "환율 1$_selectedCurrency = $_exchangeRate원 적용",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Title
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: "지출 내용 (예: 점심 식사)",
                    padding: const EdgeInsets.all(16),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Grid
                  Text(
                    "카테고리",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ExpenseCategory.values.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1A237E)
                                        : (isDark
                                              ? Colors.white10
                                              : Colors.grey[200]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(cat),
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black54),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getCategoryLabel(cat),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? const Color(0xFF1A237E)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: isDark ? ThemeData.dark() : ThemeData.light(),
                          child: child!,
                        ),
                      );
                      if (picked != null)
                        setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("날짜"),
                          Text(
                            DateFormat(
                              'yyyy.MM.dd (E)',
                              'ko_KR',
                            ).format(_selectedDate),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Receipt Photo
                  GestureDetector(
                    onTap: _pickReceiptImage,
                    child: Container(
                      height: 120, // Height for image preview
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        image: _receiptImage != null
                            ? DecorationImage(
                                image: FileImage(File(_receiptImage!.path)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _receiptImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  "영수증 사진 찍기",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payers (1/N)
                  Text(
                    "함께한 사람 (비용 정산)",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: project.members.map((m) {
                      final isSelected = _selectedPayers.contains(m);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (_selectedPayers.length > 1) {
                                _selectedPayers.remove(m); // At least one
                              }
                            } else {
                              _selectedPayers.add(m);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1A237E)
                                : (isDark ? Colors.white10 : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            m,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.lodging:
        return Icons.hotel;
      case ExpenseCategory.transport:
        return Icons.directions_bus;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.tour:
        return Icons.camera_alt;
      case ExpenseCategory.etc:
        return Icons.more_horiz;
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
}
