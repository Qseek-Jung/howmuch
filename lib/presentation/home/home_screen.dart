import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'currency_provider.dart';
import '../../data/models/currency_model.dart';
import 'widgets/top_status_bar.dart';
import 'widgets/favorite_currency_chips.dart';
import 'widgets/convert_card.dart';
import 'widgets/quick_action_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyList = ref.watch(currencyListProvider);
    final selectedCurrency = ref.watch(targetCurrencyProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      body: SafeArea(
        child: currencyList.when(
          data: (currencies) {
            final current =
                selectedCurrency ??
                (currencies.isNotEmpty ? currencies.first : null);

            if (current == null) return const Center(child: Text("환율 데이터 없음"));

            return Column(
              children: [
                TopStatusBar(
                  countryName: current.name,
                  currencyCode: current.code,
                  localTime: DateTime.now(), // TODO: Actual local time logic
                  onToggleRate: () {
                    // TODO: Toggle Real/My Rate logic
                  },
                ),
                const SizedBox(height: 12),
                FavoriteCurrencyChips(
                  currencies: currencies.take(5).toList(), // Show top 5
                  selectedCurrency: current,
                  onSelect: (currency) {
                    ref.read(targetCurrencyProvider.notifier).state = currency;
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          ConvertCard(
                            currency: current,
                            exchangeRate:
                                current.rateToKrw, // TODO: Apply multipliers
                            onAmountChanged: (amount) {
                              // Handle amount change logic if needed globally
                            },
                            onAddToExpense: () {
                              // TODO: Navigate to Add Expense
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("가계부 등록 기능 준비중")),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          QuickActionBar(
                            onCamera: () => print("Camera"),
                            onVoice: () => print("Voice"),
                            onDutchPay: () => print("DutchPay"),
                          ),
                          // TODO: Add RateTrendPanel and RecentLedgerPreview
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
