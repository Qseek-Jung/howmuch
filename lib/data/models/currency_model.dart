class Currency {
  final String code; // e.g., USD, JPY
  final String name; // e.g., 독일, 미국
  final String?
  countryEn; // e.g., Germany, United States (For Search & Subtitle)
  final String? currencyName; // e.g., 유로, 달러
  final double rateToKrw;
  final String? flagCode;
  final DateTime updatedAt;

  String get uniqueId => "$name:$code";

  Currency({
    required this.code,
    required this.name,
    this.countryEn,
    this.currencyName,
    required this.rateToKrw,
    this.flagCode,
    required this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String,
      name: json['name'] as String,
      countryEn: json['country_en'] as String?,
      currencyName: json['currency_name'] as String?,
      rateToKrw: (json['rate_to_krw'] as num).toDouble(),
      flagCode: json['flag_code'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'country_en': countryEn,
      'currency_name': currencyName,
      'rate_to_krw': rateToKrw,
      'flag_code': flagCode,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
