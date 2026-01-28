import 'package:flutter/material.dart';
import '../../../data/models/currency_model.dart'; // Adjust path if needed

class FavoriteCurrencyChips extends StatelessWidget {
  final List<Currency> currencies;
  final Currency selectedCurrency;
  final Function(Currency) onSelect;

  const FavoriteCurrencyChips({
    super.key,
    required this.currencies,
    required this.selectedCurrency,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: currencies.length,
        itemBuilder: (context, index) {
          final currency = currencies[index];
          final isSelected = currency.code == selectedCurrency.code;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currency.code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "₩ ${currency.rateToKrw.toStringAsFixed(1)}",
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) onSelect(currency);
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }
}
