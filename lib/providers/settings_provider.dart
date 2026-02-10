import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final ThemeMode themeMode;
  final List<String> favoriteCountries;
  final bool isExchangeCorrectionEnabled;
  final double exchangeCorrectionPercentage;
  final String ttsGender; // 'female' or 'male'

  UserSettings({
    this.bankName = '',
    this.accountNumber = '',
    this.accountHolder = '',
    this.themeMode = ThemeMode.system,
    this.favoriteCountries = const [],
    this.isExchangeCorrectionEnabled = false,
    this.exchangeCorrectionPercentage = 0.0,
    this.ttsGender = 'female',
  });

  UserSettings copyWith({
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    ThemeMode? themeMode,
    List<String>? favoriteCountries,
    bool? isExchangeCorrectionEnabled,
    double? exchangeCorrectionPercentage,
    String? ttsGender,
  }) {
    return UserSettings(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      themeMode: themeMode ?? this.themeMode,
      favoriteCountries: favoriteCountries ?? this.favoriteCountries,
      isExchangeCorrectionEnabled:
          isExchangeCorrectionEnabled ?? this.isExchangeCorrectionEnabled,
      exchangeCorrectionPercentage:
          exchangeCorrectionPercentage ?? this.exchangeCorrectionPercentage,
      ttsGender: ttsGender ?? this.ttsGender,
    );
  }

  bool get isEmpty => bankName.isEmpty && accountNumber.isEmpty;

  String get displayString => bankName.isNotEmpty
      ? "$bankName $accountNumber $accountHolder".trim()
      : accountNumber;
}

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(UserSettings()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;

    state = UserSettings(
      bankName: prefs.getString('bank_name') ?? '',
      accountNumber: prefs.getString('account_number') ?? '',
      accountHolder: prefs.getString('account_holder') ?? '',
      themeMode: ThemeMode.values[themeIndex],
      favoriteCountries: _validateFavorites(
        prefs.getStringList('favorite_countries'),
        prefs, // Pass prefs to save reset flag
      ),
      isExchangeCorrectionEnabled:
          prefs.getBool('is_exchange_correction_enabled') ?? false,
      exchangeCorrectionPercentage:
          prefs.getDouble('exchange_correction_percentage') ?? 0.0,
      ttsGender: prefs.getString('tts_gender') ?? 'female',
    );
  }

  static List<String> _validateFavorites(
    List<String>? current,
    SharedPreferences prefs,
  ) {
    const defaultList = ['JPY', 'USD', 'CNY', 'TWD', 'HKD', 'THB', 'PHP'];
    final bool hasResetV1 = prefs.getBool('favorites_reset_done_v1') ?? false;

    // Force reset if migration hasn't run OR if data is corrupted (heuristic)
    if (!hasResetV1 || (current?.length ?? 0) > 20) {
      prefs.setBool('favorites_reset_done_v1', true);
      prefs.setStringList(
        'favorite_countries',
        defaultList,
      ); // Ensure it persists
      return defaultList;
    }

    if (current == null || current.isEmpty) {
      return defaultList;
    }
    return current;
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

  Future<void> updateExchangeCorrectionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_exchange_correction_enabled', value);
    state = state.copyWith(isExchangeCorrectionEnabled: value);
  }

  Future<void> updateExchangeCorrectionPercentage(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('exchange_correction_percentage', value);
    state = state.copyWith(exchangeCorrectionPercentage: value);
  }

  Future<void> updateTtsGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_gender', gender);
    state = state.copyWith(ttsGender: gender);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((
  ref,
) {
  return SettingsNotifier();
});
