class Currency {
  final String code; // e.g., USD, JPY
  final String name; // e.g., US Dollar, Japanese Yen
  final double rateToKrw; // e.g., 1300.50
  final DateTime updatedAt;

  Currency({
    required this.code,
    required this.name,
    required this.rateToKrw,
    required this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String,
      name: json['name'] as String,
      rateToKrw: (json['rate_to_krw'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'rate_to_krw': rateToKrw,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
