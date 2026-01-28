import 'dart:convert';

class CustomPhrase {
  final String id;
  final String koreanText;
  final Map<String, String> translations; // currencyCode -> translatedText

  CustomPhrase({
    required this.id,
    required this.koreanText,
    Map<String, String>? translations,
  }) : translations = translations ?? {};

  CustomPhrase copyWith({
    String? id,
    String? koreanText,
    Map<String, String>? translations,
  }) {
    return CustomPhrase(
      id: id ?? this.id,
      koreanText: koreanText ?? this.koreanText,
      translations: translations ?? Map.from(this.translations),
    );
  }

  /// Get translation for currency, returning Korean if not available
  String getTranslation(String currencyCode) {
    return translations[currencyCode] ?? koreanText;
  }

  /// Add or update a translation
  CustomPhrase withTranslation(String currencyCode, String translatedText) {
    final newTranslations = Map<String, String>.from(translations);
    newTranslations[currencyCode] = translatedText;
    return copyWith(translations: newTranslations);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'koreanText': koreanText, 'translations': translations};
  }

  factory CustomPhrase.fromJson(Map<String, dynamic> json) {
    return CustomPhrase(
      id: json['id'] as String,
      koreanText: json['koreanText'] as String,
      translations: Map<String, String>.from(json['translations'] ?? {}),
    );
  }

  static String encodeList(List<CustomPhrase> phrases) {
    return jsonEncode(phrases.map((p) => p.toJson()).toList());
  }

  static List<CustomPhrase> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => CustomPhrase.fromJson(json)).toList();
  }
}
