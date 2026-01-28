import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
