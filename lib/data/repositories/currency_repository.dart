import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/currency_model.dart';
import '../../core/currency_data.dart';

class CurrencyRepository {
  final SupabaseClient _supabase;
  List<Currency>? _cachedRates;

  CurrencyRepository(this._supabase);

  // Fetch rates exclusively from Supabase DB ('fx_latest_cache')
  Future<List<Currency>> fetchBriefRates() async {
    // 1. Return memory cache if available
    if (_cachedRates != null && _cachedRates!.isNotEmpty) {
      return _cachedRates!;
    }

    // 2. Try loading from SharedPreferences immediate arrival
    final prefs = await SharedPreferences.getInstance();
    final String? localRaw = prefs.getString('local_cached_rates');
    if (localRaw != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(localRaw);
        final localList = jsonList.map((j) => Currency.fromJson(j)).toList();
        if (localList.isNotEmpty) {
          _cachedRates = localList;
          // Return local cache but continue to fetch fresh data in background if needed
          // For now, we return and trigger background fetch by not returning early here
          // but we want the UI to have SOMETHING immediately.
          // Better approach: allow UI to see the local data first.
        }
      } catch (e) {
        print("[ERROR] Local cache parse error: $e");
      }
    }

    try {
      print("[DEBUG] fetching fx_latest_cache...");
      final response = await _supabase
          .from('fx_latest_cache')
          .select()
          .eq('base', 'KRW')
          .maybeSingle();

      if (response != null && response['rates'] != null) {
        final ratesMap = Map<String, dynamic>.from(response['rates']);
        List<Currency> list = [];

        for (var country in CurrencyData.allCountries) {
          final code = country['currency']!;
          final flagCode = country['flag'];

          dynamic val = ratesMap[code];
          if (val == null && flagCode != null) val = ratesMap[flagCode];
          if (val == null && code.length >= 2)
            val = ratesMap[code.substring(0, 2)];

          if (val != null && val is num && val != 0) {
            final inverseRate = 1 / val.toDouble();
            list.add(
              Currency(
                code: code,
                name: country['countryKR']!,
                countryEn: country['countryEN'],
                currencyName: CurrencyData.currencyNames[code],
                flagCode: country['flag'],
                rateToKrw: inverseRate,
                updatedAt: DateTime.now(),
              ),
            );
          } else if (code == 'KRW') {
            list.add(
              Currency(
                code: 'KRW',
                name: country['countryKR']!,
                countryEn: country['countryEN'],
                currencyName: CurrencyData.currencyNames[code],
                flagCode: country['flag'],
                rateToKrw: 1.0,
                updatedAt: DateTime.now(),
              ),
            );
          }
        }

        if (list.isNotEmpty) {
          list.sort((a, b) => a.name.compareTo(b.name));
          _cachedRates = list;

          // 3. Persist to SharedPreferences for next startup
          final String encoded = jsonEncode(
            list.map((c) => c.toJson()).toList(),
          );
          await prefs.setString('local_cached_rates', encoded);

          return list;
        }
      }
    } catch (e) {
      print("[ERROR] Supabase fetch error: $e");
    }

    // Fallback to local cache if network failed but we had it
    if (_cachedRates != null) return _cachedRates!;

    return [];
  }
}
