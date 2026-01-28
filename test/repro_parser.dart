import 'package:exchange_flutter/core/amount_recognizer.dart';

void main() {
  final testCases = [
    "55,000",
    "55000",
    "55500",
    "오백오십오만오천",
    "오만오천오백",
    "5,555,000",
    "555,000",
  ];

  print("\n--- Running AmountParser Reproduction Test ---\n");

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
