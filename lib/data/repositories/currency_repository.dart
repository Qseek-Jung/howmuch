import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/currency_model.dart';
import '../../core/currency_data.dart';

class CurrencyRepository {
  final SupabaseClient _supabase;

  CurrencyRepository(this._supabase);

  // 1. Fetch Rates from Supabase (Table: exchange_rates)
  // Schema assumption: code (text), rate_to_krw (numeric), last_updated (timestamp)
  // Or maybe a single JSON blob?
  // User said: "Supabase updates rates hourly".
  // Simplest: A table `exchange_rates` with `code` and `rate`. Base is KRW?
  // Or Base is EUR (Frankfurter default).
  // If user wants "All currencies from Frankfurter", calculating KRW rate requires:
  // KRW rate = (1 / EUR_to_KRW) * EUR_to_Target?
  // Let's assume the Supabase table contains pre-calculated 'rate_to_krw' OR standard rates.
  // I will implement a fetch that tries to get `rate_to_krw` from Supabase.
  // If failure, fallbacks to Frankfurter API (Client side).

  Future<List<Currency>> fetchBriefRates() async {
    try {
      // Fetch from fx_latest_cache (Base KRW)
      final response = await _supabase
          .from('fx_latest_cache')
          .select('rates')
          .eq('base_currency', 'KRW')
          .maybeSingle();

      if (response != null && response['rates'] != null) {
        final ratesJson = response['rates'] as Map<String, dynamic>;

        // Convert to list
        List<Currency> list = [];
        ratesJson.forEach((code, rate) {
          // rate is KRW -> Target? or Target -> KRW?
          // fx_latest_cache for Base KRW usually means: 1 KRW = x Target
          // e.g. KRW/USD = 0.00075
          // We want RateToKRW: 1 Target = y KRW => y = 1/x

          double rateVal = (rate as num).toDouble();
          double rateToKrw = rateVal == 0 ? 0 : (1 / rateVal);

          list.add(
            Currency(
              code: code,
              rateToKrw: rateToKrw,
              name: CurrencyData.getCountryName(code),
              updatedAt: DateTime.now(),
            ),
          );
        });

        // Sort by Code
        list.sort((a, b) => a.code.compareTo(b.code));
        return list;
      }
    } catch (e) {
      print("Supabase fx_latest_cache error: $e");
    }

    // Fallback or Initial implementation: Frankfurter API via HTTP
    return await fetchFromFrankfurter();
  }

  Future<List<Currency>> fetchFromFrankfurter() async {
    // 1. Get List of Currencies
    // 2. Get Rates (Base KRW? Frankfurter doesn't support KRW as base for free?
    // Actually Frankfurter base is EUR.
    // We need EUR -> KRW and EUR -> Others.
    // Target Rate (KRW based) = (EUR_to_Target) / (EUR_to_KRW).

    try {
      final url = Uri.parse('https://api.frankfurter.app/latest?from=EUR');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rates = data['rates'] as Map<String, dynamic>;
        rates['EUR'] = 1.0; // Base

        if (!rates.containsKey('KRW')) return [];

        double eurToKrw = (rates['KRW'] as num).toDouble();

        List<Currency> list = [];
        rates.forEach((code, rateVal) {
          double eurToTarget = (rateVal as num).toDouble();
          // 1 Target = ? KRW
          // 1 EUR = eurToKrw KRW
          // 1 EUR = eurToTarget Target
          // => eurToTarget Target = eurToKrw KRW
          // => 1 Target = (eurToKrw / eurToTarget) KRW
          double rateToKrw = eurToKrw / eurToTarget;

          list.add(
            Currency(
              code: code,
              rateToKrw: rateToKrw,
              name: CurrencyData.getCountryName(code),
              updatedAt: DateTime.now(),
            ),
          );
        });
        return list;
      }
    } catch (e) {
      print("Frankfurter API error: $e");
    }
    return [];
  }
}
