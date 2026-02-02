import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/currency_repository.dart';
import '../../data/models/currency_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Repository Provider
final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  return CurrencyRepository(Supabase.instance.client);
});

final currencyListProvider = FutureProvider<List<Currency>>((ref) async {
  final repository = ref.watch(currencyRepositoryProvider);
  return repository.fetchBriefRates();
});

// Current trip/target currency provider
final targetCurrencyProvider = StateProvider<Currency?>((ref) => null);

// Favorites Provider
final favoriteCurrenciesProvider =
    StateNotifierProvider<FavoriteCurrenciesNotifier, List<String>>((ref) {
      return FavoriteCurrenciesNotifier();
    });

class FavoriteCurrenciesNotifier extends StateNotifier<List<String>> {
  FavoriteCurrenciesNotifier()
    : super([
        '일본:JPY',
        '미국:USD',
        '중국:CNY',
        '대만:TWD',
        '홍콩:HKD',
        '태국:THB',
        '필리핀:PHP',
      ]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    // [DEBUG LOG]
    print("[DEBUG] Loading Favorites from 'favorite_currencies'...");
    final List<String>? stored = prefs.getStringList('favorite_currencies');
    print("[DEBUG] Stored List Length: ${stored?.length ?? 'null'}");

    final bool hasResetProvV1 = prefs.getBool('fav_provider_reset_v1') ?? false;
    print("[DEBUG] Has Reset V1: $hasResetProvV1");

    // Default Correct List
    final defaultList = [
      '일본:JPY',
      '미국:USD',
      '중국:CNY',
      '대만:TWD',
      '홍콩:HKD',
      '태국:THB',
      '필리핀:PHP',
    ];

    // Force Reset Logic
    if (!hasResetProvV1 || (stored != null && stored.length > 20)) {
      print(
        "[DEBUG] Triggering Force Reset to Default (Reason: Not Reset yet OR Too many items)",
      );
      state = defaultList;
      await prefs.setStringList('favorite_currencies', defaultList);
      await prefs.setBool('fav_provider_reset_v1', true);
      return;
    }

    if (stored != null && stored.isNotEmpty) {
      // Migration: convert old 'USD' format to 'USD:미국' if colon is missing
      final migrated = stored.map((item) {
        if (!item.contains(':')) {
          // If no name, try to resolve from CurrencyData
          final countryName = _getCountryNameFromCode(item);
          return "$countryName:$item";
        }
        // If it contains ':', check and swap if it's in old format code:name
        final parts = item.split(':');
        if (parts.length == 2 && parts[0].length == 3 && parts[1].length > 0) {
          // Simple heuristic: if first part is 3 chars (likely code), swap
          // This handles transition from JPY:일본 to 일본:JPY
          final maybeCode = parts[0];
          final maybeName = parts[1];
          // If maybeCode is all uppercase and 3 letters, it's likely the old format
          if (RegExp(r'^[A-Z]{3}$').hasMatch(maybeCode)) {
            return "$maybeName:$maybeCode";
          }
        }
        return item;
      }).toList();
      state = migrated;
      if (state.any((e) => !stored.contains(e))) {
        _saveFavorites(); // Persist migration
      }
    }
    print("[DEBUG] Final Favorites State Length: ${state.length}");
  }

  String _getCountryNameFromCode(String code) {
    // Simplified lookup for migration
    const Map<String, String> legacyMap = {
      'USD': '미국',
      'JPY': '일본',
      'EUR': '유럽연합',
      'GBP': '영국',
      'VND': '베트남',
      'THB': '태국',
      'CNY': '중국',
      'IDR': '인도네시아',
      'PHP': '필리핀',
      'SGD': '싱가포르',
      'TWD': '대만',
      'HKD': '홍콩',
      'CHF': '스위스',
      'CAD': '캐나다',
      'AUD': '호주',
      'NZD': '뉴질랜드',
      'MYR': '말레이시아',
      'INR': '인도',
      'TRY': '튀르키예',
      'MXN': '멕시코',
      'BGN': '불가리아',
      'CZK': '체코',
      'DKK': '덴마크',
      'HUF': '헝가리',
      'ILS': '이스라엘',
      'ISK': '아이슬란드',
      'NOK': '노르웨이',
      'PLN': '폴란드',
      'RON': '루마니아',
      'SEK': '스웨덴',
      'BRL': '브라질',
      'ZAR': '남아프리카',
      'KRW': '대한민국',
    };
    return legacyMap[code] ?? code;
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_currencies', state);
  }

  void addFavorite(String code) {
    if (!state.contains(code)) {
      state = [...state, code];
      _saveFavorites();
    }
  }

  void removeFavorite(String code) {
    state = state.where((item) => item != code).toList();
    _saveFavorites();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<String> newState = [...state];
    final String item = newState.removeAt(oldIndex);
    newState.insert(newIndex, item);
    state = newState;
    _saveFavorites();
  }

  void moveToTop(String code) {
    final index = state.indexWhere(
      (item) => item == code || item.startsWith('$code:'),
    );
    if (index != -1) {
      final item = state[index];
      state = [item, ...state.where((e) => e != item)];
      _saveFavorites();
    }
  }

  // TODO: Add persistence (SharedPreferences)
}

final selectedCurrencyIdProvider =
    StateNotifierProvider<SelectedCurrencyIdNotifier, String?>((ref) {
      return SelectedCurrencyIdNotifier(ref);
    });

class SelectedCurrencyIdNotifier extends StateNotifier<String?> {
  final Ref _ref;
  SelectedCurrencyIdNotifier(this._ref) : super(null) {
    _loadSelectedId();
  }

  Future<void> _loadSelectedId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedId = prefs.getString('last_selected_currency_id');

    if (storedId != null) {
      state = storedId;
    } else {
      // Fallback: use first favorite if list is not empty
      final favorites = _ref.read(favoriteCurrenciesProvider);
      if (favorites.isNotEmpty) {
        state = favorites[0];
      }
    }
  }

  Future<void> setSelectedId(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_currency_id', id);
  }
}

// Detected Country Provider (GPS-based)
final detectedCountryProvider = StateProvider<String?>((ref) => null);

// Shared Navigation Provider
final mainNavigationProvider = StateProvider<int>((ref) => 0);
