import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_phrase.dart';
import '../core/shopping_phrases.dart';
import '../services/translation_service.dart';
import '../presentation/home/currency_provider.dart';

/// Global storage key for phrases
const _globalStorageKey = 'custom_phrases_global';
const _seededKey = 'has_seeded_defaults_v5'; // v5 for global merge

/// Unified provider for all custom phrases
final customPhrasesProvider =
    StateNotifierProvider<CustomPhrasesNotifier, List<CustomPhrase>>((ref) {
      return CustomPhrasesNotifier(ref);
    });

class CustomPhrasesNotifier extends StateNotifier<List<CustomPhrase>> {
  final Ref _ref;
  final _uuid = const Uuid();

  CustomPhrasesNotifier(this._ref) : super([]) {
    _loadPhrases();
  }

  Future<void> _loadPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_globalStorageKey);
    List<CustomPhrase> currentPhrases = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        currentPhrases = CustomPhrase.decodeList(jsonString);
      } catch (e) {
        print('Error loading global custom phrases: $e');
      }
    }

    // Migration logic: If global is empty, try to pull from current selected currency
    if (currentPhrases.isEmpty) {
      final lastId = prefs.getString('last_selected_currency_id');
      if (lastId != null) {
        final legacyKey = "custom_phrases_$lastId";
        final legacyJson = prefs.getString(legacyKey);
        if (legacyJson != null && legacyJson.isNotEmpty) {
          try {
            currentPhrases = CustomPhrase.decodeList(legacyJson);
            print('Migrated phrases from $lastId to global storage');
          } catch (_) {}
        }
      }
    }

    final bool hasSeeded = prefs.getBool(_seededKey) ?? false;

    if (!hasSeeded) {
      final List<CustomPhrase> updatedPhrases = List.from(currentPhrases);

      for (int i = 0; i < ShoppingPhrases.koreanPhrases.length; i++) {
        final koreanText = ShoppingPhrases.koreanPhrases[i];
        final Map<String, String> translations = {};

        ShoppingPhrases.translations.forEach((langCode, list) {
          if (i < list.length) translations[langCode] = list[i];
        });

        final existingIndex = updatedPhrases.indexWhere(
          (p) => p.koreanText == koreanText,
        );
        if (existingIndex != -1) {
          updatedPhrases[existingIndex] = updatedPhrases[existingIndex]
              .copyWith(
                translations: {
                  ...updatedPhrases[existingIndex].translations,
                  ...translations,
                },
              );
        } else {
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
      await prefs.setBool(_seededKey, true);
    } else {
      state = currentPhrases;
    }
  }

  Future<void> _savePhrases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalStorageKey, CustomPhrase.encodeList(state));
  }

  Future<void> addPhrase(String koreanText) async {
    final phraseId = _uuid.v4();
    final phrase = CustomPhrase(
      id: phraseId,
      koreanText: koreanText,
      translations: {},
    );
    state = [...state, phrase];
    await _savePhrases();
    _translateInBackground(phraseId, koreanText);
  }

  Future<void> _translateInBackground(
    String phraseId,
    String koreanText,
  ) async {
    final translationService = TranslationService();

    // 1. Get Priority Languages: Current + Favorites
    final selectedId = _ref.read(selectedCurrencyIdProvider);
    final favorites = _ref.read(favoriteCurrenciesProvider);

    final Set<String> priorityLangKeys = {};
    if (selectedId != null) {
      priorityLangKeys.add(ShoppingPhrases.getLanguageCode(selectedId));
    }
    for (final favId in favorites) {
      priorityLangKeys.add(ShoppingPhrases.getLanguageCode(favId));
    }

    // 2. Translate only for priority languages to save data/models
    for (final langCodeKey in priorityLangKeys) {
      final index = state.indexWhere((p) => p.id == phraseId);
      if (index == -1) return;

      try {
        if (state[index].translations.containsKey(langCodeKey)) continue;

        // Force download for these priority languages
        final translation = await translationService.translateToLanguage(
          koreanText,
          langCodeKey,
          forceDownload: true,
        );

        if (translation != koreanText) {
          state = state.map((p) {
            if (p.id == phraseId) {
              final newTranslations = Map<String, String>.from(p.translations);
              newTranslations[langCodeKey] = translation;
              return p.copyWith(translations: newTranslations);
            }
            return p;
          }).toList();
        }
        await Future.delayed(const Duration(milliseconds: 30));
      } catch (e) {
        print('Background translation error for $langCodeKey: $e');
      }
    }
    await _savePhrases();
  }

  Future<void> removePhrase(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _savePhrases();
  }

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

  Future<void> reorderPhrases(int oldIndex, int newIndex) async {
    final List<CustomPhrase> list = List.from(state);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    await _savePhrases();
  }
}
