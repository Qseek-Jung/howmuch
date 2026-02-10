import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../features/ledger/providers/ledger_provider.dart';
import '../features/ledger/models/ledger_backup.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _bankController;
  late TextEditingController _numberController;
  late TextEditingController _holderController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _bankController = TextEditingController(text: settings.bankName);
    _numberController = TextEditingController(text: settings.accountNumber);
    _holderController = TextEditingController(text: settings.accountHolder);
  }

  @override
  void dispose() {
    _bankController.dispose();
    _numberController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _performRestore(LedgerBackup? data) async {
    final success = await ref
        .read(ledgerProvider.notifier)
        .restoreFromFile(manualData: data);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("데이터가 복구되었습니다."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("복구가 취소되었거나 실패했습니다."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _performManualRestore() async {
    await _performRestore(null);
  }

  Future<void> _showBackupSelectionDialog(List<File> files) async {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("백업 파일 선택"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("저장소에서 백업 파일들을 찾았습니다. 복구할 파일을 선택해 주세요."),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: Material(
                color: Colors.transparent,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final fileName = file.path
                        .split(Platform.pathSeparator)
                        .last;
                    final modified = file.lastModifiedSync();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        fileName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        dateFormat.format(modified),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final data = await ref
                            .read(ledgerProvider.notifier)
                            .loadFromSpecificFile(file);
                        _performRestore(data);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("직접 선택"),
            onPressed: () {
              Navigator.pop(context);
              _performManualRestore();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          "설정",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: CupertinoFormSection.insetGrouped(
              header: const Text("앱 테마 설정"),
              backgroundColor: Colors.transparent,
              children: [
                CupertinoFormRow(
                  prefix: const Row(
                    children: [
                      Icon(CupertinoIcons.brightness, size: 20),
                      SizedBox(width: 12),
                      Text("화면 모드"),
                    ],
                  ),
                  child: CupertinoSlidingSegmentedControl<ThemeMode>(
                    groupValue: settings.themeMode == ThemeMode.system
                        ? (MediaQuery.platformBrightnessOf(context) ==
                                  Brightness.dark
                              ? ThemeMode.dark
                              : ThemeMode.light)
                        : settings.themeMode,
                    children: {
                      ThemeMode.light: _buildSegment("라이트"),
                      ThemeMode.dark: _buildSegment("다크"),
                    },
                    onValueChanged: (mode) {
                      if (mode != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateThemeMode(mode);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: CupertinoFormSection.insetGrouped(
              header: const Text("체감환율 보정"),
              backgroundColor: Colors.transparent,
              children: [
                CupertinoFormRow(
                  prefix: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.arrow_up_right_circle,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text("기본 보정 적용"),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text("체감환율 보정"),
                              content: const Text(
                                "환전 수수료 및 카드 수수료 등을 감안하여 기준 환율보다 높게 설정하면 더욱 정확한 비용 계산이 가능합니다.",
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("확인"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.question_circle,
                          size: 18,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                  child: CupertinoSwitch(
                    value: settings.isExchangeCorrectionEnabled,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateExchangeCorrectionEnabled(value);
                    },
                  ),
                ),
                if (settings.isExchangeCorrectionEnabled)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _HorizontalDialPicker<int>(
                          items: List.generate(31, (i) => i),
                          selectedValue: settings.exchangeCorrectionPercentage
                              .toInt(),
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateExchangeCorrectionPercentage(
                                  val.toDouble(),
                                );
                          },
                          viewportFraction: 0.25,
                          itemBuilder: (context, val, opacity, scale) {
                            return Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Text(
                                  "$val%",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        val ==
                                            settings
                                                .exchangeCorrectionPercentage
                                                .toInt()
                                        ? FontWeight.w900
                                        : FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: CupertinoFormSection.insetGrouped(
              header: const Text("음성 지원(TTS) 설정"),
              backgroundColor: Colors.transparent,
              footer: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "해당기능이 지원이 안되는 언어가 있을 수 있습니다.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              children: [
                CupertinoFormRow(
                  prefix: const Row(
                    children: [
                      Icon(CupertinoIcons.person_alt_circle, size: 20),
                      SizedBox(width: 12),
                      Text("음성 성별"),
                    ],
                  ),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: settings.ttsGender,
                    children: {
                      'female': _buildSegment("여성"),
                      'male': _buildSegment("남성"),
                    },
                    onValueChanged: (gender) {
                      if (gender != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateTtsGender(gender);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: CupertinoFormSection.insetGrouped(
              header: const Text("정산 계좌 정보 (카톡 메세지 자동완성용)"),
              backgroundColor: Colors.transparent,
              footer: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "입력된 정보는 1/N 정산 리포트를 공유할 때 하단에 자동으로 포함됩니다. 비워두시면 계좌 정보 없이 발송됩니다.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              children: [
                _buildFormInput(
                  label: "은행명",
                  placeholder: "예: 하나은행",
                  controller: _bankController,
                  icon: CupertinoIcons.info_circle,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).updateBankName(v),
                ),
                _buildFormInput(
                  label: "계좌번호",
                  placeholder: "'-' 없이 숫자만 입력",
                  controller: _numberController,
                  icon: CupertinoIcons.number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .updateAccountNumber(v),
                ),
                _buildFormInput(
                  label: "예금주",
                  placeholder: "예: 홍길동",
                  controller: _holderController,
                  icon: CupertinoIcons.person_crop_circle,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .updateAccountHolder(v),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: CupertinoFormSection.insetGrouped(
              header: const Text("여계부 데이터 관리"),
              backgroundColor: Colors.transparent,
              footer: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "데이터는 자동으로 파일로 백업됩니다. 앱 재설치 시에도 로컬에 저장된 백업 파일이 있다면 자동으로 복구됩니다. '백업 공유'를 통해 안전한 곳에 별도로 보관하는 것을 권장합니다.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              children: [
                CupertinoFormRow(
                  prefix: const Row(
                    children: [
                      Icon(CupertinoIcons.arrow_up_doc, size: 20),
                      SizedBox(width: 12),
                      Text("데이터 백업 및 공유"),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("공유하기"),
                    onPressed: () async {
                      await ref
                          .read(ledgerProvider.notifier)
                          .saveManualBackup();
                      await ref.read(ledgerProvider.notifier).shareBackup();
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Row(
                    children: [
                      Icon(CupertinoIcons.arrow_down_doc, size: 20),
                      SizedBox(width: 12),
                      Text("파일에서 데이터 복구"),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("복구 실행"),
                    onPressed: () async {
                      // 1. Request Storage Permission (if Android)
                      if (Platform.isAndroid) {
                        // For Android 11+, we need manageExternalStorage to scan for files
                        if (await Permission
                                .manageExternalStorage
                                .isRestricted ||
                            !await Permission.manageExternalStorage.isGranted) {
                          final status = await Permission.manageExternalStorage
                              .request();
                          if (!status.isGranted) {
                            // Fallback to basic storage if possible, or show guidance
                            await Permission.storage.request();
                          }
                        }
                      }

                      // 2. Scan External Storage
                      final externalFiles = await ref
                          .read(ledgerProvider.notifier)
                          .getExternalBackupFiles();

                      if (!mounted) return;

                      if (externalFiles.isNotEmpty) {
                        _showBackupSelectionDialog(externalFiles);
                        return;
                      }

                      // 3. Check for auto-restore data as fallback
                      final autoData = await ref
                          .read(ledgerProvider.notifier)
                          .getAutoRestoreData();

                      if (!mounted) return;

                      if (autoData != null && autoData.projects.isNotEmpty) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text("데이터 복구"),
                            content: const Text(
                              "내부 백업 파일을 찾았습니다. 이 데이터로 복구하시겠습니까?\n(현재 데이터가 덮어씌워질 수 있습니다.)",
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text("취소"),
                                onPressed: () => Navigator.pop(context),
                              ),
                              CupertinoDialogAction(
                                child: const Text("직접 선택"),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  _performManualRestore();
                                },
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text("자동 복구"),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  _performRestore(autoData);
                                },
                              ),
                            ],
                          ),
                        );
                      } else {
                        _performManualRestore();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSegment(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildFormInput({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoFormRow(
      prefix: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: TextAlign.end,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: null,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
        placeholderStyle: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white24 : Colors.grey[400],
        ),
      ),
    );
  }
}

class _HorizontalDialPicker<T> extends StatefulWidget {
  final List<T> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final Widget Function(BuildContext, T, double opacity, double scale)
  itemBuilder;
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
  late PageController _controller;
  late double _currentPage;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.items.indexOf(widget.selectedValue);
    _currentPage = initialIndex.toDouble();
    _controller = PageController(
      initialPage: initialIndex,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HorizontalDialPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      final newIndex = widget.items.indexOf(widget.selectedValue);
      if (newIndex != _controller.page?.round()) {
        _controller.jumpToPage(newIndex);
        setState(() {
          _currentPage = newIndex.toDouble();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _currentPage = _controller.page ?? 0;
                });
              }
              if (notification is ScrollEndNotification) {
                final int newIndex = _controller.page!.round();
                if (widget.items[newIndex] != widget.selectedValue) {
                  HapticFeedback.lightImpact();
                  widget.onChanged(widget.items[newIndex]);
                }
              }
              return true;
            },
            child: PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final double difference = (index - _currentPage).abs();
                final double opacity = (1 - (difference * 0.5)).clamp(0.2, 1.0);
                final double scale = (1.2 - (difference * 0.2)).clamp(0.8, 1.2);

                return Center(
                  child: widget.itemBuilder(
                    context,
                    widget.items[index],
                    opacity,
                    scale,
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF2C2C2E),
                            const Color(0xFF2C2C2E).withValues(alpha: 0),
                            const Color(0xFF2C2C2E).withValues(alpha: 0),
                            const Color(0xFF2C2C2E),
                          ]
                        : [
                            Colors.white,
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0),
                            Colors.white,
                          ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            child: IgnorePointer(
              child: Icon(
                CupertinoIcons.chevron_left,
                size: 20,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: IgnorePointer(
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 20,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_controller.page! > 0) {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                const Spacer(flex: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_controller.page! < widget.items.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
