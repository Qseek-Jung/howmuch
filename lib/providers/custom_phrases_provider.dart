import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_phrase.dart';

import '../core/shopping_phrases.dart';

const _storageKey = 'custom_phrases';
const _seededKey =
    'has_seeded_defaults_v2'; // Changed key to force re-seed if needed, or simply use a new key.

/// Provider for custom phrases
final customPhrasesProvider =
    StateNotifierProvider<CustomPhrasesNotifier, List<CustomPhrase>>((ref) {
      return CustomPhrasesNotifier();
    });

class CustomPhrasesNotifier extends StateNotifier<List<CustomPhrase>> {
  CustomPhrasesNotifier() : super([]) {
    _loadPhrases();
  }

  final _uuid = const Uuid();

  Future<void> _loadPhrases() async {
    final prefs = await SharedPreferences.getInstance();

    // Load existing custom phrases
    List<CustomPhrase> currentPhrases = [];
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        currentPhrases = CustomPhrase.decodeList(jsonString);
      } catch (e) {
        print('Error loading custom phrases: $e');
        currentPhrases = [];
      }
    }

    // Check if defaults are already seeded
    final bool hasSeeded = prefs.getBool(_seededKey) ?? false;

    if (!hasSeeded) {
      // Create CustomPhrase objects from default ShoppingPhrases
      final List<CustomPhrase> defaultPhrases = [];

      for (int i = 0; i < ShoppingPhrases.koreanPhrases.length; i++) {
        final koreanText = ShoppingPhrases.koreanPhrases[i];
        final Map<String, String> translations = {};

        // Populate translations from ShoppingPhrases.translations
        ShoppingPhrases.translations.forEach((langCode, list) {
          if (i < list.length) {
            translations[langCode] = list[i];
          }
        });

        defaultPhrases.add(
          CustomPhrase(
            id: _uuid.v4(),
            koreanText: koreanText,
            translations: translations,
          ),
        );
      }

      // Merge: Defaults first, then existing custom phrases
      // Check for duplicates to avoid double adding if user manually added same text
      final existingTexts = currentPhrases.map((p) => p.koreanText).toSet();
      final newDefaults = defaultPhrases
          .where((p) => !existingTexts.contains(p.koreanText))
          .toList();

      currentPhrases = [...newDefaults, ...currentPhrases];

      // Save merged list
      state = currentPhrases;
      await _savePhrases();
      await prefs.setBool(_seededKey, true);
    } else {
      state = currentPhrases;
    }
  }

  Future<void> _savePhrases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, CustomPhrase.encodeList(state));
  }

  /// Add a new custom phrase
  Future<void> addPhrase(
    String koreanText, {
    Map<String, String>? translations,
  }) async {
    final phrase = CustomPhrase(
      id: _uuid.v4(),
      koreanText: koreanText,
      translations: translations,
    );
    state = [...state, phrase];
    await _savePhrases();
  }

  /// Remove a phrase by ID
  Future<void> removePhrase(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _savePhrases();
  }

  /// Reorder phrases
  Future<void> reorderPhrases(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final phrases = List<CustomPhrase>.from(state);
    final item = phrases.removeAt(oldIndex);
    phrases.insert(newIndex, item);
    state = phrases;
    await _savePhrases();
  }

  /// Update translation for a phrase
  Future<void> updateTranslation(
    String id,
    String currencyCode,
    String translatedText,
  ) async {
    state = state.map((p) {
      if (p.id == id) {
        return p.withTranslation(currencyCode, translatedText);
      }
      return p;
    }).toList();
    await _savePhrases();
  }

  /// Get phrase by ID
  CustomPhrase? getPhrase(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
