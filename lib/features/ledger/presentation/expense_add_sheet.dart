import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ledger_project.dart';
import '../models/ledger_expense.dart';
import '../providers/ledger_provider.dart';
import '../services/ledger_image_service.dart';
import '../../../providers/settings_provider.dart';

import '../../../presentation/home/currency_provider.dart';
import '../../../core/design_system.dart';
import '../../../core/currency_data.dart';

class ExpenseAddSheet extends ConsumerStatefulWidget {
  final String projectId;
  final LedgerExpense? expenseToEdit; // If provided, Edit Mode
  final double? initialAmount;
  final String? initialCurrency;
  final DateTime? initialDate;
  final String? initialTitle;
  final double? initialExchangeRate;

  const ExpenseAddSheet({
    super.key,
    required this.projectId,
    this.expenseToEdit,
    this.initialAmount,
    this.initialCurrency,
    this.initialDate,
    this.initialTitle,
    this.initialExchangeRate,
  });

  @override
  ConsumerState<ExpenseAddSheet> createState() => _ExpenseAddSheetState();
}

class _ExpenseAddSheetState extends ConsumerState<ExpenseAddSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Added scroll controller

  // For Real-time Conversion Display
  double _calculatedKrw = 0;

  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.food;

  // Logic for currency
  String _selectedCurrency = "KRW";
  double _exchangeRate = 1.0;

  List<String> _selectedPayers = [];
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  // Receipt Images
  List<XFile> _receiptImages = [];
  final ImagePicker _picker = ImagePicker();
  final LedgerImageService _imageService = LedgerImageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // CRITICAL: Wrap entire initialization in try-catch to prevent ANR
      try {
        if (!mounted) return;

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

          // Format on load
          if (e.currencyCode == "KRW") {
            _amountController.text = NumberFormat(
              "#,###",
            ).format(displayAmount.toInt());
          } else if (displayAmount.remainder(1) == 0) {
            _amountController.text = NumberFormat(
              "#,###",
            ).format(displayAmount);
          } else {
            _amountController.text = NumberFormat(
              "#,###.##",
            ).format(displayAmount);
          }

          // SAFE: Validate receipt paths before creating XFiles
          final validReceiptPaths = <XFile>[];
          for (final path in e.receiptPaths) {
            try {
              final file = await _imageService.getPermanentFile(path);
              if (file != null) {
                validReceiptPaths.add(XFile(file.path));
              } else {
                debugPrint('Receipt image color not found/resolved: $path');
              }
            } catch (error) {
              debugPrint('Error loading receipt: $path - $error');
            }
          }

          if (mounted) {
            setState(() {
              _selectedDate = e.date;
              _selectedCategory = e.category;
              _selectedCurrency = e.currencyCode;
              _exchangeRate = e.exchangeRate;
              _selectedPayers = List.from(e.payers);
              _selectedPaymentMethod = e.paymentMethod;
              _memoController.text = e.memo ?? "";
              _receiptImages = validReceiptPaths; // Use validated list
            });
          }
        } else {
          // Add Mode: Defaults
          if (mounted) {
            setState(() {
              _selectedPayers = List.from(project.members);
              _selectedCurrency =
                  widget.initialCurrency ?? project.defaultCurrency;
              _selectedDate = widget.initialDate ?? DateTime.now();
              _titleController.text = widget.initialTitle ?? "";
              if (widget.initialAmount != null) {
                double rawVal = widget.initialAmount!;
                if (_selectedCurrency == "KRW") {
                  _amountController.text = NumberFormat(
                    "#,###",
                  ).format(rawVal.toInt());
                } else if (rawVal.remainder(1) == 0) {
                  _amountController.text = NumberFormat("#,###").format(rawVal);
                } else {
                  _amountController.text = NumberFormat(
                    "#,###.##",
                  ).format(rawVal);
                }
              }
              _setDefaultExchangeRate();
            });
          }
        }

        if (mounted) {
          _calculateKrw();
        }
      } catch (error, stackTrace) {
        debugPrint('CRITICAL ERROR in ExpenseAddSheet.initState: $error');
        debugPrint('Stack trace: $stackTrace');
        // Gracefully handle by using defaults
        if (mounted) {
          setState(() {
            _selectedPayers = [];
            _selectedCurrency = "KRW";
            _exchangeRate = 1.0;
          });
        }
      }
    });

    _amountController.addListener(_calculateKrw);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateKrw);
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _scrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }

  void _calculateKrw() {
    // CRITICAL: Check if widget is still mounted before setState
    if (!mounted) return;

    if (_selectedCurrency == "KRW") {
      if (_calculatedKrw != 0) setState(() => _calculatedKrw = 0);
      return;
    }

    final clean = _amountController.text.replaceAll(',', '');
    final amountLocal = double.tryParse(clean) ?? 0;

    // Safe ref access with null check
    try {
      final settings = ref.read(settingsProvider);
      double effectiveRate = _exchangeRate;
      if (settings.isExchangeCorrectionEnabled) {
        effectiveRate =
            _exchangeRate * (1 + (settings.exchangeCorrectionPercentage / 100));
      }

      if (mounted) {
        setState(() {
          _calculatedKrw = amountLocal * effectiveRate;
        });
      }
    } catch (e) {
      // Gracefully handle any provider access errors
      debugPrint('Error in _calculateKrw: $e');
    }
  }

  void _onAmountChanged(String value) {
    if (value.isEmpty) return;
    String cleanNumber = value.replaceAll(',', '');

    // Check multiple dots
    if ('.'.allMatches(cleanNumber).length > 1) return;
    if (cleanNumber.endsWith('.')) return;

    final number = double.tryParse(cleanNumber);
    if (number == null) return;

    final formatted = _selectedCurrency == "KRW"
        ? NumberFormat("#,###").format(number.toInt())
        : NumberFormat("#,###.##").format(number);

    // If user typed "12.", format is "12". We want to keep "12."
    if (_selectedCurrency != "KRW" &&
        value.endsWith('.') &&
        !formatted.contains('.'))
      return;

    if (_amountController.text != formatted) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _setDefaultExchangeRate() {
    final curList = ref.read(currencyListProvider).value ?? [];
    final target = curList
        .where((c) => c.code == _selectedCurrency)
        .firstOrNull;

    if (widget.initialExchangeRate != null) {
      _exchangeRate = widget.initialExchangeRate!;
    } else if (target != null) {
      _exchangeRate = target.rateToKrw;
    } else {
      // Fallback defaults
      if (_selectedCurrency == "EUR") {
        _exchangeRate = 1450.0;
      } else if (_selectedCurrency == "USD") {
        _exchangeRate = 1350.0;
      } else if (_selectedCurrency == "JPY") {
        _exchangeRate = 9.0;
      } else {
        _exchangeRate = 1.0;
      }
    }
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null && mounted) {
        // Immediately copy to permanent storage
        final permanentFileName = await _imageService.copyToPermanent(photo);
        if (permanentFileName != null) {
          final permanentFile = await _imageService.getPermanentFile(
            permanentFileName,
          );
          if (permanentFile != null && mounted) {
            setState(() {
              _receiptImages.add(XFile(permanentFile.path));
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('영수증 이미지 추가'),
        message: const Text('이미지를 가져올 방법을 선택하세요.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickReceiptImage(ImageSource.camera);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera),
                SizedBox(width: 8),
                Text('카메라로 촬영'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickReceiptImage(ImageSource.gallery);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo),
                SizedBox(width: 8),
                Text('앨범에서 선택'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ),
    );
  }

  void _removeReceiptImage(int index) {
    if (mounted) {
      setState(() {
        _receiptImages.removeAt(index);
      });
    }
  }

  void _saveExpense() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지출 내용을 입력해주세요.')));
      return;
    }
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('금액을 입력해주세요.')));
      return;
    }

    // Remove commas
    final cleanAmount = _amountController.text.replaceAll(',', '');
    final amountLocal = double.tryParse(cleanAmount) ?? 0;

    // Calculate KRW
    double amountKrw = 0;
    final settings = ref.read(settingsProvider);
    double effectiveRate = _exchangeRate;

    if (_selectedCurrency != "KRW" && settings.isExchangeCorrectionEnabled) {
      effectiveRate =
          _exchangeRate * (1 + (settings.exchangeCorrectionPercentage / 100));
    }

    if (_selectedCurrency == "KRW") {
      amountKrw = amountLocal;
      _exchangeRate = 1.0;
    } else {
      amountKrw = amountLocal * effectiveRate;
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
        paymentMethod: _selectedPaymentMethod,
        payers: _selectedPayers,
        memo: _memoController.text,
        receiptPaths: _receiptImages.map((img) {
          final fileName = p.basename(img.path);
          if (_imageService.isRelative(fileName)) {
            return fileName;
          }
          return img.path;
        }).toList(),
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
        paymentMethod: _selectedPaymentMethod,
        payers: _selectedPayers,
        memo: _memoController.text,
        receiptPaths: _receiptImages.map((img) {
          final fileName = p.basename(img.path);
          if (_imageService.isRelative(fileName)) {
            return fileName;
          }
          return img.path;
        }).toList(),
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

    return Material(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDesign.cardRadius),
            ),
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // Header
                // Header
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Title
                      Text(
                        widget.expenseToEdit != null ? "지출 수정" : "지출 기록",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      // Left & Right Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "취소",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          // Currency Toggle (Small) - Hide if Default is KRW
                          if (project.defaultCurrency != "KRW")
                            Container(
                              height: 26, // Reduced from 32 (approx 20%)
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCurrencyToggleBtn(
                                    project.defaultCurrency,
                                    isDark,
                                  ),
                                  _buildCurrencyToggleBtn("KRW", isDark),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController, // Attach controller
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.end,
                                onChanged: _onAmountChanged,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getPrimary(isDark),
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "0",
                                  hintStyle: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getPrimary(
                                      isDark,
                                    ), // Match active color
                                  ),
                                  // Use suffix widget to always show currency
                                  suffix: Text(
                                    " $_selectedCurrency",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Sub-info for KRW conversion
                        if (_selectedCurrency != "KRW")
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Center(
                              child: Text(
                                "≈ ${NumberFormat('#,###').format(_calculatedKrw.round())}원",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.grey,
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
                            color: isDark
                                ? Colors.black26
                                : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(
                              AppDesign.inputRadius,
                            ),
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
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          child: _HorizontalDialPicker<ExpenseCategory>(
                            items: ExpenseCategory.values,
                            selectedValue: _selectedCategory,
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                            viewportFraction: 0.25,
                            itemBuilder: (context, cat, ratioVal, scaleVal) {
                              // ratioVal is 0.0 ~ 1.0 (1.0 = center)
                              // We interpret this for color interpolation
                              final ratio = (ratioVal as num).toDouble();

                              // Interpolate color: Grey -> Primary
                              final Color inactiveColor = isDark
                                  ? Colors.white38
                                  : Colors.grey;
                              final Color activeColor = AppColors.getPrimary(
                                isDark,
                              );
                              final Color currentColor = Color.lerp(
                                inactiveColor,
                                activeColor,
                                ratio,
                              )!;

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon
                                  Icon(
                                    _getCategoryIcon(cat),
                                    color: currentColor,
                                    size:
                                        32, // Fixed reasonable size, scale handled by Transform
                                  ),
                                  const SizedBox(height: 8),
                                  // Text
                                  Text(
                                    _getCategoryLabel(cat),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: ratio > 0.8
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: currentColor,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Payment Method selection
                        Text(
                          "결제 수단",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildPaymentMethodItem(
                                PaymentMethod.cash,
                                "현금",
                                CupertinoIcons.money_dollar_circle,
                                isDark,
                              ),
                              _buildPaymentMethodItem(
                                PaymentMethod.card,
                                "카드",
                                CupertinoIcons.creditcard,
                                isDark,
                              ),
                              _buildPaymentMethodItem(
                                PaymentMethod.appPay,
                                "앱페이",
                                CupertinoIcons.device_phone_portrait,
                                isDark,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Date Picker
                        GestureDetector(
                          onTap: () async {
                            FocusScope.of(context).unfocus(); // Close keyboard
                            final picked = await showDialog<DateTime>(
                              context: context,
                              builder: (_) => _CustomCalendarDialog(
                                initialDate: _selectedDate,
                                projectStartDate: project.startDate,
                                projectEndDate: project.endDate,
                              ),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                            // Explicitly unfocus again to prevent keyboard from popping up
                            if (mounted) FocusScope.of(context).unfocus();
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

                        // Receipt Photos
                        Text(
                          "영수증 사진",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _receiptImages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _receiptImages.length) {
                                // Add Button
                                return GestureDetector(
                                  onTap: _showImageSourceActionSheet,
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFF2F2F7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "추가 촬영",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Image Preview
                              final img = _receiptImages[index];
                              return Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(img.path),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () => _removeReceiptImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
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
                                      _selectedPayers.remove(m);
                                    }
                                  } else {
                                    _selectedPayers.add(m);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: AppDesign.selectionDecoration(
                                  isSelected: isSelected,
                                  isDark: isDark,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      m,
                                      style: AppDesign.selectionTextStyle(
                                        isSelected: isSelected,
                                        isDark: isDark,
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppColors.getPrimary(isDark),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // Memo
                        CupertinoTextField(
                          controller: _memoController,
                          placeholder: "메모 (선택사항, 정산에 참고 가능)",
                          padding: const EdgeInsets.all(16),
                          maxLines: 3,
                          minLines: 1,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          // Scroll to bottom when tapped to ensure visibility over keyboard
                          onTap: () {
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                            );
                          },
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black26
                                : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(
                              AppDesign.inputRadius,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bottom Save Button
                        GestureDetector(
                          onTap: _saveExpense,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: AppDesign.primaryGradientDecoration(
                              isDark,
                            ),
                            child: Center(
                              child: Text(
                                widget.expenseToEdit != null
                                    ? "수정 완료"
                                    : "지출 저장",
                                style: AppDesign.buttonTextStyle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyToggleBtn(String currencyCode, bool isDark) {
    bool isActive = _selectedCurrency == currencyCode;
    return GestureDetector(
      onTap: () {
        if (currencyCode == 'KRW') {
          setState(() {
            _selectedCurrency = 'KRW';
            _exchangeRate = 1.0;
            _calculateKrw();
          });
        } else {
          // If already active, show picker to change currency
          if (isActive) {
            _showCurrencyPicker();
          } else {
            // Just switch to this currency
            setState(() {
              _selectedCurrency = currencyCode;
              _setDefaultExchangeRate();
              _calculateKrw();
            });
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ), // Reduced vertical padding
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.grey[700] : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          currencyCode,
          style: TextStyle(
            fontSize: 11, // Reduced from 13
            fontWeight: FontWeight.bold,
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white38 : Colors.grey),
          ),
        ),
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
      case ExpenseCategory.golf:
        return Icons.golf_course;
      case ExpenseCategory.activity:
        return Icons.surfing;
      case ExpenseCategory.medical:
        return Icons.medical_services;
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

  Widget _buildPaymentMethodItem(
    PaymentMethod method,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPaymentMethod = method);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.getPrimary(isDark)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white38 : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    final favoriteCodes = ref.read(favoriteCurrenciesProvider);

    // Create list of {name, code}
    // 1. Always add South Korea (KRW) first
    final List<Map<String, String>> items = [
      {'name': '대한민국', 'code': 'KRW'},
    ];

    // 2. Add other favorites (skip KRW if present to avoid duplicate)
    for (var key in favoriteCodes) {
      final parts = key.split(':');
      String name;
      String code;

      if (parts.length > 1) {
        // Standard Name:Code
        if (RegExp(r'^[A-Z]{3}$').hasMatch(parts[1])) {
          name = parts[0];
          code = parts[1];
        } else {
          // Legacy Code:Name
          code = parts[0];
          name = parts[1];
        }
      } else {
        code = parts[0];
        name = CurrencyData.getCountryName(code);
      }

      if (code == 'KRW') continue; // Already added at top

      items.add({'name': name, 'code': code});
    }

    int tempIndex = 0;
    final currentIndex = items.indexWhere(
      (i) => i['code'] == _selectedCurrency,
    );
    if (currentIndex >= 0) tempIndex = currentIndex;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
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
                      context.push(
                        '/currency_manage',
                        extra: {'isSelectionMode': false},
                      );
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
                        _selectedCurrency = selected['code']!;
                        _setDefaultExchangeRate();
                        _calculateKrw();
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
}

class _HorizontalDialPicker<T> extends StatefulWidget {
  final List<T> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final Widget Function(BuildContext, T, double, double) itemBuilder;
  final double viewportFraction;

  const _HorizontalDialPicker({
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.itemBuilder,
    required this.viewportFraction,
  });

  @override
  State<_HorizontalDialPicker<T>> createState() =>
      __HorizontalDialPickerState<T>();
}

class __HorizontalDialPickerState<T> extends State<_HorizontalDialPicker<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Start at selected
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animated: false);
    });
  }

  void _scrollToSelected({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final width = MediaQuery.of(context).size.width - 40; // Parent padding
    final itemWidth = width * widget.viewportFraction;

    final index = widget.items.indexOf(widget.selectedValue);
    if (index == -1) return;

    // Center it:
    // With symmetric padding = (width - itemWidth) / 2
    // Offset 0 means the START of the padding is at viewport 0.
    // The content starts at paddingH.
    // So Item 0 is centered at Offset 0.
    // Item 1 is centered at Offset = itemWidth.

    final targetOffset = index * itemWidth;

    if (animated) {
      if ((_scrollController.offset - targetOffset).abs() < 2.0) return;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  void didUpdateWidget(_HorizontalDialPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fixed Center Highlight (Rounded Pill)
          Container(
            width: 70 * 1.2, // Slightly wider for comfort
            height: 100, // Covers Icon + Text
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.getPrimary(isDark),
                width: 1.5,
              ),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemWidth = width * widget.viewportFraction;
              final paddingH = (width - itemWidth) / 2;

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    final offset = _scrollController.offset;
                    final target = (offset / itemWidth).round();
                    final safeIndex = target.clamp(0, widget.items.length - 1);
                    final snapOffset = safeIndex * itemWidth;

                    if ((snapOffset - offset).abs() > 1.0) {
                      Future.microtask(() {
                        _scrollController.animateTo(
                          snapOffset,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                        widget.onChanged(widget.items[safeIndex]);
                        HapticFeedback.selectionClick();
                      });
                    } else {
                      if (widget.items[safeIndex] != widget.selectedValue) {
                        widget.onChanged(widget.items[safeIndex]);
                        HapticFeedback.selectionClick();
                      }
                    }
                  }
                  return true;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: paddingH),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: itemWidth,
                      child: AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          // Calculate distance from center for smooth color transition
                          double itemCenter = (index * itemWidth);
                          double scrollOffset = 0;
                          if (_scrollController.hasClients) {
                            scrollOffset = _scrollController.offset;
                          }

                          double dist = (itemCenter - scrollOffset).abs();
                          // Normalizing: 0 = center, itemWidth = adjacent center
                          double ratio =
                              1.0 - (dist / (itemWidth * 0.8)).clamp(0.0, 1.0);
                          // ratio is 1.0 at center, 0.0 at edges of "active zone"

                          double scale = 0.8 + (ratio * 0.3); // 0.8 -> 1.1

                          // Pass the ratio as "opacityVal" effectively, or just use it to color
                          // But since we pass it to itemBuilder, let's pass ratio.
                          // Actually, let's just use the builder here directly?
                          // No, we use widget.itemBuilder. Let's pass 'ratio' as the 3rd param (opacityVal).

                          return Transform.scale(
                            scale: scale,
                            child: widget.itemBuilder(
                              context,
                              widget.items[index],
                              ratio, // Passing ratio as intensity (0..1)
                              scale,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CustomCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime projectStartDate;
  final DateTime projectEndDate;

  const _CustomCalendarDialog({
    required this.initialDate,
    required this.projectStartDate,
    required this.projectEndDate,
  });

  @override
  State<_CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInTripRange(DateTime date) {
    final start = DateTime(
      widget.projectStartDate.year,
      widget.projectStartDate.month,
      widget.projectStartDate.day,
    );
    final end = DateTime(
      widget.projectEndDate.year,
      widget.projectEndDate.month,
      widget.projectEndDate.day,
    );
    final target = DateTime(date.year, date.month, date.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);

    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final int offset = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: Icon(
                    Icons.chevron_left,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  DateFormat("yyyy년 MM월").format(_focusedMonth),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["일", "월", "화", "수", "목", "금", "토"]
                  .map(
                    (w) => Text(
                      w,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final dayOffset = index - offset;
                  if (dayOffset < 0 || dayOffset >= daysInMonth) {
                    return const SizedBox();
                  }

                  final currentDay = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    dayOffset + 1,
                  );
                  final isSelected = _isSameDay(currentDay, _selectedDate);
                  final inRange = _isInTripRange(currentDay);
                  final isToday = _isSameDay(currentDay, DateTime.now());

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = currentDay);
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) Navigator.pop(context, currentDay);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (inRange
                                  ? primaryColor.withValues(
                                      alpha: isDark ? 0.3 : 0.15,
                                    )
                                  : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: primaryColor, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${currentDay.day}",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (inRange
                                    ? (isDark ? Colors.white : primaryColor)
                                    : (isDark ? Colors.white70 : Colors.black)),
                          fontWeight: (isSelected || inRange)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
