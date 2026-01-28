import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final ThemeMode themeMode;
  final List<String> favoriteCountries;

  UserSettings({
    this.bankName = '',
    this.accountNumber = '',
    this.accountHolder = '',
    this.themeMode = ThemeMode.system,
    this.favoriteCountries = const [],
  });

  UserSettings copyWith({
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    ThemeMode? themeMode,
    List<String>? favoriteCountries,
  }) {
    return UserSettings(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      themeMode: themeMode ?? this.themeMode,
      favoriteCountries: favoriteCountries ?? this.favoriteCountries,
    );
  }

  bool get isEmpty => bankName.isEmpty && accountNumber.isEmpty;

  String get displayString => bankName.isNotEmpty
      ? "$bankName $accountNumber $accountHolder".trim()
      : accountNumber;
}

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(UserSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;

    state = UserSettings(
      bankName: prefs.getString('bank_name') ?? '',
      accountNumber: prefs.getString('account_number') ?? '',
      accountHolder: prefs.getString('account_holder') ?? '',
      themeMode: ThemeMode.values[themeIndex],
      favoriteCountries: prefs.getStringList('favorite_countries') ?? [],
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updateBankName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bank_name', value);
    state = state.copyWith(bankName: value);
  }

  Future<void> updateAccountNumber(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_number', value);
    state = state.copyWith(accountNumber: value);
  }

  Future<void> updateAccountHolder(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_holder', value);
    state = state.copyWith(accountHolder: value);
  }

  Future<bool> toggleFavoriteCountry(String countryName) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFavorites = List<String>.from(state.favoriteCountries);

    if (currentFavorites.contains(countryName)) {
      currentFavorites.remove(countryName);
    } else {
      if (currentFavorites.length >= 5) {
        return false; // Limit reached
      }
      currentFavorites.add(countryName);
    }

    await prefs.setStringList('favorite_countries', currentFavorites);
    state = state.copyWith(favoriteCountries: currentFavorites);
    return true; // Success
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((
  ref,
) {
  return SettingsNotifier();
});
