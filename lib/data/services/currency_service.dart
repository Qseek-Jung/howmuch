import 'dart:async';
import '../models/currency_model.dart';

class CurrencyService {
  // Mock API call
  Future<List<Currency>> fetchExchangeRates() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Return dummy data
    return [
      Currency(
        code: 'KRW',
        name: 'South Korean Won',
        rateToKrw: 1.0,
        updatedAt: DateTime.now(),
      ),
      Currency(
        code: 'USD',
        name: 'United States Dollar',
        rateToKrw: 1335.50,
        updatedAt: DateTime.now(),
      ),
      Currency(
        code: 'JPY',
        name: 'Japanese Yen',
        rateToKrw:
            9.05, // 100 JPY is usually quoted, but standardizing to 1 unit here for simplicity, or 100? usually 1 unit in system, display *100
        updatedAt: DateTime.now(),
      ),
      Currency(
        code: 'EUR',
        name: 'Euro',
        rateToKrw: 1450.20,
        updatedAt: DateTime.now(),
      ),
      Currency(
        code: 'CNY',
        name: 'Chinese Yuan',
        rateToKrw: 185.30,
        updatedAt: DateTime.now(),
      ),
      Currency(
        code: 'VND',
        name: 'Vietnamese Dong',
        rateToKrw: 0.054, // 100 VND = 5.4 KRW
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
