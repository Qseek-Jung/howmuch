import 'dart:convert';

class SplitBill {
  final String id;
  final String title;
  final DateTime date;
  final double totalAmount;
  final String currency;
  final int peopleCount;
  final double perPersonAmount;
  final double surplus;
  final int roundUnit;
  final String payer;
  final bool isShared;
  final double? originalAmount;
  final String? originalCurrency;
  final double? rateToKrw;

  SplitBill({
    required this.id,
    required this.title,
    required this.date,
    required this.totalAmount,
    required this.currency,
    required this.peopleCount,
    required this.perPersonAmount,
    required this.surplus,
    required this.roundUnit,
    this.payer = '나',
    this.isShared = false,
    this.originalAmount,
    this.originalCurrency,
    this.rateToKrw,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'currency': currency,
      'peopleCount': peopleCount,
      'perPersonAmount': perPersonAmount,
      'surplus': surplus,
      'roundUnit': roundUnit,
      'payer': payer,
      'isShared': isShared,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'rateToKrw': rateToKrw,
    };
  }

  factory SplitBill.fromMap(Map<String, dynamic> map) {
    return SplitBill(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      currency: map['currency'],
      peopleCount: map['peopleCount'],
      perPersonAmount: (map['perPersonAmount'] as num).toDouble(),
      surplus: (map['surplus'] as num).toDouble(),
      roundUnit: map['roundUnit'],
      payer: map['payer'] ?? '나',
      isShared: map['isShared'] ?? false,
      originalAmount: map['originalAmount'] != null
          ? (map['originalAmount'] as num).toDouble()
          : null,
      originalCurrency: map['originalCurrency'],
      rateToKrw: map['rateToKrw'] != null
          ? (map['rateToKrw'] as num).toDouble()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SplitBill.fromJson(String source) =>
      SplitBill.fromMap(json.decode(source));
}
