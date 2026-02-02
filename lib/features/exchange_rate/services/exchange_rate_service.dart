import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final exchangeRateServiceProvider = Provider(
  (ref) => ExchangeRateService(Supabase.instance.client),
);

class ExchangeRateService {
  final SupabaseClient _client;

  ExchangeRateService(this._client);

  /// Fetches the latest exchange rates from `fx_latest_cache`.
  /// [baseCode] is usually 'KRW' or 'USD'.
  Future<Map<String, double>> getLatestRates(String baseCode) async {
    try {
      final response = await _client
          .from('fx_latest_cache')
          .select()
          .eq('base', baseCode)
          .maybeSingle();

      if (response == null) {
        // Fallback or empty if not cached yet
        return {};
      }

      final rates = response['rates'] as Map<String, dynamic>;
      // Convert dynamic values to double
      return rates.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (e) {
      print('Error fetching latest rates: $e');
      return {};
    }
  }

  /// Fetches historical chart data from `fx_history`.
  /// [base] is usually the target currency (e.g., 'USD'), [target] is our base (e.g., 'KRW').
  /// Returns a list of maps: `[{"d": "2024-01-01", "v": 1300.0}, ...]`
  Future<List<dynamic>> getChartData({
    required String base,
    required String target,
    required String range, // '1W', '1M', '6M', '1Y'
  }) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (range) {
        case '1W':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '1M':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '6M':
          startDate = now.subtract(const Duration(days: 180));
          break;
        case '1Y':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      final response = await _client
          .from('fx_history')
          .select('date, rates')
          .eq('base', 'KRW') // Our storage always uses KRW as base
          .gte('date', DateFormat('yyyy-MM-dd').format(startDate))
          .order('date', ascending: true);

      if ((response as List).isEmpty) {
        return [];
      }

      final List<dynamic> history = response;
      return history.map((row) {
        final date = row['date'] as String;
        final rates = row['rates'] as Map<String, dynamic>;

        // If the user wants USD/KRW trend:
        // In DB, rates['USD'] = 0.00075 (which is KRW -> USD)
        // We want 1/0.00075 = 1333.33 (which is USD -> KRW)
        double value = 0.0;
        if (rates.containsKey(base)) {
          final rateToTarget = (rates[base] as num).toDouble();
          if (rateToTarget != 0) {
            value = 1 / rateToTarget;
          }
        }

        // Return raw value to preserve precision for small currencies (VND, JPY, etc.)
        return {"d": date, "v": value};
      }).toList();
    } catch (e) {
      print('Error fetching chart data: $e');
      return [];
    }
  }
}
