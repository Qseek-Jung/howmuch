import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_phrase.dart';
import '../providers/custom_phrases_provider.dart';
import '../providers/ad_settings_provider.dart';
import '../services/admob_service.dart';
import '../core/design_system.dart';
import 'home/currency_provider.dart'; // selectedCurrencyIdProvider가 여기에 있음

class ShoppingHelperSettingsScreen extends ConsumerStatefulWidget {
  const ShoppingHelperSettingsScreen({super.key});

  @override
  ConsumerState<ShoppingHelperSettingsScreen> createState() =>
      _ShoppingHelperSettingsScreenState();
}

class _ShoppingHelperSettingsScreenState
    extends ConsumerState<ShoppingHelperSettingsScreen> {
  bool _isTranslating = false;

  Future<void> _showAddPhraseDialog() async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("문장 추가"),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: "한국어로 입력하세요",
            autofocus: true,
            maxLines: 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.extraLightBackgroundGray,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("추가"),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context);
                final adSettings = ref.read(adSettingsProvider.notifier);
                if (adSettings.shouldShowAd()) {
                  _addCustomPhrase(text);
                  AdMobService.instance.showInterstitialAd(
                    onAdDismissed: () {},
                  );
                } else {
                  _addCustomPhrase(text);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );

    // Unified logic inside onPressed to handle ads correctly
  }

  Future<void> _addCustomPhrase(String koreanText) async {
    setState(() => _isTranslating = true);

    final uniqueId = ref.read(selectedCurrencyIdProvider) ?? '일본:JPY';
    try {
      await ref
          .read(customPhrasesProvider(uniqueId).notifier)
          .addPhrase(koreanText);
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error adding phrase: $e');
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _showEditDialog(CustomPhrase phrase) async {
    final controller = TextEditingController(text: phrase.koreanText);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("문장 수정"),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.extraLightBackgroundGray,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("저장"),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && text != phrase.koreanText) {
                Navigator.pop(context);
                final adSettings = ref.read(adSettingsProvider.notifier);
                if (adSettings.shouldShowAd()) {
                  _deletePhrase(phrase.id).then((_) => _addCustomPhrase(text));
                  AdMobService.instance.showInterstitialAd(
                    onAdDismissed: () {},
                  );
                } else {
                  _deletePhrase(phrase.id).then((_) => _addCustomPhrase(text));
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );

    // Unified logic inside onPressed
  }

  Future<void> _deletePhrase(String id) async {
    final uniqueId = ref.read(selectedCurrencyIdProvider) ?? '일본:JPY';
    HapticFeedback.lightImpact();
    await ref.read(customPhrasesProvider(uniqueId).notifier).removePhrase(id);
  }

  Future<void> _confirmDelete(CustomPhrase phrase) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("삭제 확인"),
        content: Text("'${phrase.koreanText}'를 삭제하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("삭제"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePhrase(phrase.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uniqueId = ref.watch(selectedCurrencyIdProvider) ?? '일본:JPY';
    final customPhrases = ref.watch(customPhrasesProvider(uniqueId));

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          "쇼핑헬퍼 설정",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: CupertinoColors.activeBlue),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (customPhrases.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.text_bubble,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "등록된 표현이 없습니다",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.white38
                                : CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "아래 + 버튼을 눌러 추가하세요",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverReorderableList(
                  itemCount: customPhrases.length,
                  onReorder: (oldIndex, newIndex) {
                    HapticFeedback.lightImpact();
                    final uniqueId =
                        ref.read(selectedCurrencyIdProvider) ?? '일본:JPY';
                    ref
                        .read(customPhrasesProvider(uniqueId).notifier)
                        .reorderPhrases(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final phrase = customPhrases[index];
                    return Container(
                      key: ValueKey(phrase.id),
                      margin: EdgeInsets.fromLTRB(
                        16,
                        index == 0 ? 16 : 0,
                        16,
                        index == customPhrases.length - 1 ? 0 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(index == 0 ? 12 : 0),
                          topRight: Radius.circular(index == 0 ? 12 : 0),
                          bottomLeft: Radius.circular(
                            index == customPhrases.length - 1 ? 12 : 0,
                          ),
                          bottomRight: Radius.circular(
                            index == customPhrases.length - 1 ? 12 : 0,
                          ),
                        ),
                        border: Border(
                          bottom: (index < customPhrases.length - 1)
                              ? BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withOpacity(0.05),
                                  width: 0.5,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: _CustomPhraseTile(
                        phrase: phrase,
                        index: index,
                        onEdit: () => _showEditDialog(phrase),
                        onDelete: () => _confirmDelete(phrase),
                        isDark: isDark,
                      ),
                    );
                  },
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Loading overlay
          if (_isTranslating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "번역 중...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPhraseDialog,
        backgroundColor: AppColors.getPrimary(isDark),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CustomPhraseTile extends StatelessWidget {
  final CustomPhrase phrase;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDark;

  const _CustomPhraseTile({
    required this.phrase,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(phrase.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
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
            onPressed: (context) => onEdit(),
            backgroundColor: CupertinoColors.activeBlue,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.pencil,
            label: '수정',
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: isDark ? Colors.white38 : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                phrase.koreanText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
