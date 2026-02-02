import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              header: const Text("정산 계좌 정보 (자동 완성용)"),
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
