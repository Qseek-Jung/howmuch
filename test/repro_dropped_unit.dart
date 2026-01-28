import 'package:exchange_flutter/core/amount_recognizer.dart';

void main() {
  final testCases = [
    "23 6000", // Target: 236,000 (Infer 'Man' for 23)
    "5 5000", // Target: 55,000 (Infer 'Man' for 5)
    "50 500", // Target: 500,500? Or 50,500? Heuristic: 50 < 500 -> 50 Man 500 = 500,500.
    "20 24", // Target: 2024 (No inference, 24 is too small)
    "100 200", // Target: 100 Man 200 = 1,000,200? Or 300? 100 < 200 -> Infer Man?
    "500 50", // Normal: 550.
    "23만 6천", // Normal: 236,000.
  ];

  print("\n--- Running Dropped Unit Reproduction Test ---\n");

  for (var input in testCases) {
    try {
      print("Input: '$input'");
      final result = AmountParser.parseAmount(input);
      print("Result: $result\n");
    } catch (e) {
      print("Error processing '$input': $e\n");
    }
  }
}
