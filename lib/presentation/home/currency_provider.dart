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
        'JPY', // 일본
        'VND', // 베트남
        'THB', // 태국
        'USD', // 미국
        'CNY', // 중국
        'IDR', // 인도네시아
        'PHP', // 필리핀
        'SGD', // 싱가포르
        'TWD', // 대만
        'HKD', // 홍콩
      ]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('favorite_currencies');
    if (stored != null && stored.isNotEmpty) {
      state = stored;
    }
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
    if (state.contains(code)) {
      state = [code, ...state.where((item) => item != code)];
      _saveFavorites();
    }
  }

  // TODO: Add persistence (SharedPreferences)
}
