import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Fetches historical chart data from `fx_series_cache`.
  /// Returns a list of maps: `[{"d": "2024-01-01", "v": 1300.5}, ...]`
  Future<List<dynamic>> getChartData({
    required String base,
    required String target,
    required String range, // '1W', '1M', '6M', '1Y'
  }) async {
    try {
      final response = await _client
          .from('fx_series_cache')
          .select('data, expires_at')
          .eq('base', base)
          .eq('target', target)
          .eq('range', range)
          .maybeSingle();

      if (response != null) {
        final expiresAt = DateTime.parse(response['expires_at']);
        if (expiresAt.isAfter(DateTime.now())) {
          return response['data'] as List<dynamic>;
        } else {
          // Cache expired
          print('Chart cache expired for $base/$target - $range');
          // TODO: Trigger Edge Function to refresh? For now, return stale data or empty.
          return response['data'] as List<dynamic>;
        }
      }

      // No cache found
      // TODO: Trigger Edge Function to create cache.
      return [];
    } catch (e) {
      print('Error fetching chart data: $e');
      return [];
    }
  }
}
