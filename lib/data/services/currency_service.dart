import 'dart:async';
import '../models/currency_model.dart';
import '../../core/currency_data.dart';

class CurrencyService {
  // Mock API call
  Future<List<Currency>> fetchExchangeRates() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Get all unique currency codes from CurrencyData
    final uniqueCodes = CurrencyData.allCountries
        .map((e) => e['code']!)
        .toSet()
        .toList();

    // Map to Currency objects
    return uniqueCodes.map((code) {
      // Generate a semi-realistic dummy rate based on code hash or predefined map for major ones
      double rate;
      switch (code) {
        case 'KRW':
          rate = 1.0;
          break;
        case 'USD':
          rate = 1335.50;
          break;
        case 'JPY':
          rate = 9.05;
          break;
        case 'EUR':
          rate = 1450.20;
          break;
        case 'CNY':
          rate = 185.30;
          break;
        case 'VND':
          rate = 0.054;
          break;
        case 'TWD':
          rate = 42.50;
          break;
        case 'HKD':
          rate = 170.80;
          break;
        case 'THB':
          rate = 37.20;
          break;
        case 'PHP':
          rate = 23.50;
          break;
        case 'SGD':
          rate = 995.00;
          break;
        case 'IDR':
          rate = 0.086;
          break;
        case 'MYR':
          rate = 280.0;
          break;
        case 'GBP':
          rate = 1700.0;
          break;
        case 'AUD':
          rate = 870.0;
          break;
        case 'CAD':
          rate = 980.0;
          break;
        case 'CHF':
          rate = 1520.0;
          break;
        default:
          // Generate a value between 1 and 100 for others
          rate = (code.hashCode % 1000) / 10.0 + 1.0;
      }

      return Currency(
        code: code,
        name:
            CurrencyData.currencyNames[code] ??
            code, // Use Korean name suffix or code
        rateToKrw: rate,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }
}
