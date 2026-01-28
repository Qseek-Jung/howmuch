import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/shopping_phrases.dart';
import '../models/custom_phrase.dart';
import '../providers/custom_phrases_provider.dart';
import '../services/translation_service.dart';

class ShoppingHelperMode extends ConsumerStatefulWidget {
  final String currencyCode; // e.g., 'JPY', 'USD'

  const ShoppingHelperMode({super.key, required this.currencyCode});

  @override
  ConsumerState<ShoppingHelperMode> createState() => _ShoppingHelperModeState();
}

class _ShoppingHelperModeState extends ConsumerState<ShoppingHelperMode> {
  final FlutterTts _flutterTts = FlutterTts();
  final TranslationService _translationService = TranslationService();
  String? _currentLocaleId;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void didUpdateWidget(covariant ShoppingHelperMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currencyCode != widget.currencyCode) {
      _updateTtsLanguage();
    }
  }

  void _updateTtsLanguage() {
    final locale = ShoppingPhrases.ttsLocaleMap[widget.currencyCode] ?? 'en-US';
    _currentLocaleId = locale;
    _flutterTts.setLanguage(locale);
  }

  Future<void> _initTts() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.ambient, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ], IosTextToSpeechAudioMode.voicePrompt);
    _updateTtsLanguage();
  }

  Future<void> _speak(String text) async {
    HapticFeedback.lightImpact();
    print("TTS Speaking ($_currentLocaleId): $text");
    await _flutterTts.stop();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _speakCustomPhrase(CustomPhrase phrase) async {
    // Check if translation exists for current currency
    var translation = phrase.translations[widget.currencyCode];

    if (translation == null) {
      // Translate on the fly and cache
      translation = await _translationService.translate(
        phrase.koreanText,
        widget.currencyCode,
      );
      await ref
          .read(customPhrasesProvider.notifier)
          .updateTranslation(phrase.id, widget.currencyCode, translation);
    }

    await _speak(translation);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customPhrases = ref.watch(customPhrasesProvider);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPhraseDialog(context, isDark),
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final phrase = customPhrases[index];
              return _ExpressionTile(
                text: phrase.koreanText,
                onTap: () => _speakCustomPhrase(phrase),
                onLongPress: () =>
                    _showDeleteConfirmDialog(context, phrase, isDark),
                isDark: isDark,
              );
            }, childCount: customPhrases.length),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _showAddPhraseDialog(BuildContext context, bool isDark) {
    final textController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("표현 추가"),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text("추가할 한국어 문장을 입력하세요."),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: textController,
              placeholder: "예: 이거 얼마인가요?",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              cursorColor: const Color(0xFF1A237E),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("추가"),
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                ref.read(customPhrasesProvider.notifier).addPhrase(text);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    CustomPhrase phrase,
    bool isDark,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("삭제"),
        content: Text("'${phrase.koreanText}' 표현을 삭제하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("삭제"),
            onPressed: () {
              ref.read(customPhrasesProvider.notifier).removePhrase(phrase.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ExpressionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDark;

  const _ExpressionTile({
    required this.text,
    required this.onTap,
    required this.onLongPress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
      highlightColor: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.speaker_2_fill,
                color: Color(0xFF1A237E),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
