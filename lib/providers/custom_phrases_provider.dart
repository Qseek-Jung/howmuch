import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_phrase.dart';
import '../core/shopping_phrases.dart';
import '../services/translation_service.dart';

const _storageKey = 'custom_phrases';
const _seededKey =
    'has_seeded_defaults_v4'; // Incremented to v4 to force re-seed/merge logic

/// Provider for custom phrases
final customPhrasesProvider =
    StateNotifierProvider.family<
      CustomPhrasesNotifier,
      List<CustomPhrase>,
      String
    >((ref, uniqueId) {
      return CustomPhrasesNotifier(uniqueId);
    });

class CustomPhrasesNotifier extends StateNotifier<List<CustomPhrase>> {
  final _uuid = const Uuid();
  final String uniqueId;

  CustomPhrasesNotifier(this.uniqueId) : super([]) {
    _loadPhrases();
  }

  Future<void> _loadPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = "${_storageKey}_$uniqueId";
    final jsonString = prefs.getString(storageKey);
    List<CustomPhrase> currentPhrases = [];
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        currentPhrases = CustomPhrase.decodeList(jsonString);
      } catch (e) {
        print('Error loading custom phrases for $uniqueId: $e');
        currentPhrases = [];
      }
    }

    // Check if defaults are already seeded for this uniqueId
    final seededKey = "${_seededKey}_$uniqueId";
    final bool hasSeeded = prefs.getBool(seededKey) ?? false;

    if (!hasSeeded) {
      // Create/Update phrases from default ShoppingPhrases
      final List<CustomPhrase> updatedPhrases = List.from(currentPhrases);

      for (int i = 0; i < ShoppingPhrases.koreanPhrases.length; i++) {
        final koreanText = ShoppingPhrases.koreanPhrases[i];
        final Map<String, String> translations = {};

        // Populate translations from ShoppingPhrases.translations
        ShoppingPhrases.translations.forEach((langCode, list) {
          if (i < list.length) {
            translations[langCode] = list[i];
          }
        });

        // Find existing phrase with same Korean text
        final existingIndex = updatedPhrases.indexWhere(
          (p) => p.koreanText == koreanText,
        );

        if (existingIndex != -1) {
          // Update translations for existing default phrase
          updatedPhrases[existingIndex] = updatedPhrases[existingIndex]
              .copyWith(
                translations: {
                  ...updatedPhrases[existingIndex].translations,
                  ...translations,
                },
              );
        } else {
          // Add as new default phrase
          updatedPhrases.insert(
            i < updatedPhrases.length ? i : updatedPhrases.length,
            CustomPhrase(
              id: _uuid.v4(),
              koreanText: koreanText,
              translations: translations,
            ),
          );
        }
      }

      state = updatedPhrases;
      await _savePhrases();
      await prefs.setBool(seededKey, true);
    } else {
      state = currentPhrases;
    }
  }

  Future<void> _savePhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = "${_storageKey}_$uniqueId";
    await prefs.setString(storageKey, CustomPhrase.encodeList(state));
  }

  /// Add a new custom phrase with background auto-translation
  Future<void> addPhrase(String koreanText) async {
    final phraseId = _uuid.v4();
    final phrase = CustomPhrase(
      id: phraseId,
      koreanText: koreanText,
      translations: {},
    );

    // Add instantly to UI
    state = [...state, phrase];
    await _savePhrases();

    // Start background translation without awaiting it here to prevent ANR
    _translateInBackground(phraseId, koreanText);
  }

  Future<void> _translateInBackground(
    String phraseId,
    String koreanText,
  ) async {
    final translationService = TranslationService();

    // 1. Identify current language for this uniqueId (Priority)
    final currentLangKey = ShoppingPhrases.getLanguageCode(uniqueId);
    final allKeys = TranslationService.phraseKeyToLanguage.keys.toList();

    // 2. Put current language first to ensure it's translated even if download is needed
    final List<String> priorityKeys = [];
    if (allKeys.contains(currentLangKey)) priorityKeys.add(currentLangKey);
    priorityKeys.addAll(allKeys.where((k) => k != currentLangKey));

    for (final langCodeKey in priorityKeys) {
      // Check if phrase still exists
      final index = state.indexWhere((p) => p.id == phraseId);
      if (index == -1) return;

      try {
        // For the current priority language, we allow download.
        // For others, we skip if not downloaded to avoid massive zip downloads.
        final isCurrent = langCodeKey == currentLangKey;

        // Skip translation if it's already present (unlikely for new phrase, but good for safety)
        if (state[index].translations.containsKey(langCodeKey)) continue;

        final translation = await translationService.translateToLanguage(
          koreanText,
          langCodeKey,
          forceDownload: isCurrent,
        );

        if (translation != koreanText) {
          // Update state incrementally
          state = state.map((p) {
            if (p.id == phraseId) {
              final newTranslations = Map<String, String>.from(p.translations);
              newTranslations[langCodeKey] = translation;
              return p.copyWith(translations: newTranslations);
            }
            return p;
          }).toList();
        }

        // yield to keep UI responsive
        await Future.delayed(const Duration(milliseconds: 30));
      } catch (e) {
        print('Background translation error for $langCodeKey: $e');
      }
    }

    // Save final results to disk
    await _savePhrases();
  }

  /// Remove a phrase by ID
  Future<void> removePhrase(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _savePhrases();
  }

  /// Update a single translation for a phrase
  Future<void> updateTranslation(
    String id,
    String langCode,
    String translation,
  ) async {
    state = state.map((p) {
      if (p.id == id) {
        final newTranslations = Map<String, String>.from(p.translations);
        newTranslations[langCode] = translation;
        return p.copyWith(translations: newTranslations);
      }
      return p;
    }).toList();
    await _savePhrases();
  }

  /// Reorder phrases
  Future<void> reorderPhrases(int oldIndex, int newIndex) async {
    final List<CustomPhrase> list = List.from(state);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    await _savePhrases();
  }
}
