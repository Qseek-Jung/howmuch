import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/shopping_phrases.dart';
import '../models/custom_phrase.dart';
import '../providers/custom_phrases_provider.dart';
import '../services/translation_service.dart';
import '../services/admob_service.dart';
import '../providers/settings_provider.dart';
import '../providers/ad_settings_provider.dart';
import '../core/design_system.dart';

class ShoppingHelperMode extends ConsumerStatefulWidget {
  final String uniqueId; // e.g., '일본:JPY', '미국:USD'

  const ShoppingHelperMode({super.key, required this.uniqueId});

  @override
  ConsumerState<ShoppingHelperMode> createState() => _ShoppingHelperModeState();
}

class _ShoppingHelperModeState extends ConsumerState<ShoppingHelperMode> {
  final FlutterTts _flutterTts = FlutterTts();
  final TranslationService _translationService = TranslationService();
  String? _currentLocaleId;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void didUpdateWidget(covariant ShoppingHelperMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uniqueId != widget.uniqueId) {
      _updateTtsLanguage();
      _translateAllForCurrentLanguage();
    }
  }

  bool _isTtsSupported = true;

  void _updateTtsLanguage() {
    final locale = ShoppingPhrases.getTTSLocale(widget.uniqueId);

    setState(() {
      _isTtsSupported = true;
      _currentLocaleId = locale;
    });

    if (_isTtsSupported) {
      _flutterTts.setLanguage(_currentLocaleId!);
      _updateTtsVoice();
    }
  }

  Future<void> _updateTtsVoice() async {
    final gender = ref.read(settingsProvider).ttsGender; // 'male' or 'female'

    try {
      final voices = await _flutterTts.getVoices;
      print("TTS: Available voices for $_currentLocaleId: $voices");

      if (voices is List && voices.isNotEmpty) {
        Map<String, dynamic>? bestVoice;
        int maxScore = -1;

        for (final voice in voices) {
          int score = 0;
          final Map<dynamic, dynamic> vMap = voice as Map;
          final vLocale = vMap['locale']?.toString().replaceAll('_', '-');
          final vName = vMap['name']?.toString().toLowerCase() ?? "";
          final vGender = vMap['gender']?.toString().toLowerCase();

          // 1. Locale Match (Critical)
          if (vLocale != _currentLocaleId) continue;
          score += 100;

          // 2. Gender Match
          bool genderMatched = false;
          // Check explicit property
          if (vGender == gender) {
            score += 50;
            genderMatched = true;
          }
          // Check name heuristic if property missing or mismatch
          if (!genderMatched) {
            if (gender == 'male') {
              if (vName.contains('male') || vName.contains('man')) score += 30;
              // Penalty for wrong gender in name
              if (vName.contains('female') || vName.contains('woman'))
                score -= 50;
            } else {
              // female
              if (vName.contains('female') || vName.contains('woman'))
                score += 30;
              if (vName.contains('male') || vName.contains('man')) score -= 50;
            }
          }

          // 3. Network vs Local (Quality preference)
          // Network voices are usually better, but require internet.
          // Let's slightly prefer network if available, but gender is more important.
          if (vName.contains('network')) score += 10;

          // Debug log
          // print("Voice candidate: $vName, score: $score");

          if (score > maxScore) {
            maxScore = score;
            bestVoice = Map<String, dynamic>.from(vMap);
          }
        }

        if (bestVoice != null) {
          await _flutterTts.setVoice({
            "name": bestVoice["name"],
            "locale": bestVoice["locale"],
          });
          print("TTS Voice Set to: ${bestVoice["name"]} (Score: $maxScore)");

          if (mounted) {
            // Optional: Show snackbar if gender changed? No, too noisy.
          }
        } else {
          print("TTS: No matching voice found for $_currentLocaleId");
        }
      }
    } catch (e) {
      print("Error updating TTS voice: $e");
    }
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
    _translateAllForCurrentLanguage();
  }

  Future<void> _translateAllForCurrentLanguage() async {
    final langCode = ShoppingPhrases.getLanguageCode(widget.uniqueId);
    final phrases = ref.read(customPhrasesProvider(widget.uniqueId));
    final notifier = ref.read(customPhrasesProvider(widget.uniqueId).notifier);

    for (final phrase in phrases) {
      if (!phrase.translations.containsKey(langCode)) {
        // Extract code for translation service fallback
        final parts = widget.uniqueId.split(':');
        final code = parts.length > 1 ? parts[1] : parts[0];

        final translation = await _translationService.translate(
          phrase.koreanText,
          code,
        );
        await notifier.updateTranslation(phrase.id, langCode, translation);
      }
    }
  }

  Future<void> _speak(String text) async {
    HapticFeedback.lightImpact();
    await _flutterTts.stop();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _speakCustomPhrase(CustomPhrase phrase) async {
    final langCode = ShoppingPhrases.getLanguageCode(widget.uniqueId);
    var translation = phrase.translations[langCode];

    if (translation == null) {
      // Extract code for translation service fallback if needed
      final parts = widget.uniqueId.split(':');
      final code = parts.length > 1 ? parts[1] : parts[0];

      translation = await _translationService.translate(
        phrase.koreanText,
        code,
      );
      await ref
          .read(customPhrasesProvider(widget.uniqueId).notifier)
          .updateTranslation(phrase.id, langCode, translation);
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
    final customPhrases = ref.watch(customPhrasesProvider(widget.uniqueId));

    ref.listen(settingsProvider.select((s) => s.ttsGender), (prev, next) {
      if (prev != next) {
        _updateTtsVoice();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPhraseDialog(context, isDark),
        backgroundColor: AppColors.getPrimary(isDark),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final phrase = customPhrases[index];
                  final langCode = ShoppingPhrases.getLanguageCode(
                    widget.uniqueId,
                  );
                  final translation = phrase.translations[langCode] ?? "";

                  return _ExpressionTile(
                    text: phrase.koreanText,
                    translation: translation,
                    onTap: () {
                      if (_isTtsSupported) {
                        _speakCustomPhrase(phrase);
                      } else {
                        HapticFeedback.vibrate();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("이 국가는 아직 TTS 기능을 지원하지 않습니다."),
                          ),
                        );
                      }
                    },
                    onLongPress: () =>
                        _showDeleteConfirmDialog(context, phrase, isDark),
                    isDark: isDark,
                  );
                }, childCount: customPhrases.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          if (_isTranslating)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        "문장 추가 중...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
              cursorColor: AppColors.getPrimary(isDark),
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
                Navigator.pop(context);
                final adSettings = ref.read(adSettingsProvider.notifier);
                if (adSettings.shouldShowAd()) {
                  _addPhraseWithLoading(text);
                  AdMobService.instance.showInterstitialAd(
                    onAdDismissed: () {},
                  );
                } else {
                  _addPhraseWithLoading(text);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addPhraseWithLoading(String text) async {
    setState(() => _isTranslating = true);
    try {
      await ref
          .read(customPhrasesProvider(widget.uniqueId).notifier)
          .addPhrase(text);
      HapticFeedback.mediumImpact();
    } catch (e) {
      print("Error adding phrase: $e");
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
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
              ref
                  .read(customPhrasesProvider(widget.uniqueId).notifier)
                  .removePhrase(phrase.id);
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
  final String translation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDark;

  const _ExpressionTile({
    required this.text,
    required this.translation,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (translation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      translation,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: isDark ? Colors.white70 : Colors.black54,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.speaker_2_fill,
                color: AppColors.getPrimary(isDark),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
