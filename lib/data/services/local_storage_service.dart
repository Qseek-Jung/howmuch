import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';

class LocalStorageService {
  static const String _currencyKey = 'cached_currencies';

  Future<void> saveCurrencies(List<Currency> currencies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = currencies.map((c) => c.toJson()).toList();
    await prefs.setString(_currencyKey, jsonEncode(jsonList));
  }

  Future<List<Currency>> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_currencyKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Currency.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
