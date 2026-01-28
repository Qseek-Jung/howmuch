import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final Map<String, OnDeviceTranslator> _translators = {};
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  /// Map currency code to TranslateLanguage
  static TranslateLanguage? getLanguageForCurrency(String currencyCode) {
    const currencyToLanguage = {
      'KRW': TranslateLanguage.korean,
      'USD': TranslateLanguage.english,
      'JPY': TranslateLanguage.japanese,
      'CNY': TranslateLanguage.chinese,
      'VND': TranslateLanguage.vietnamese,
      'THB': TranslateLanguage.thai,
      'IDR': TranslateLanguage.indonesian,
      'PHP': TranslateLanguage.english, // Filipino not well supported
      'SGD': TranslateLanguage.english,
      'TWD': TranslateLanguage.chinese,
      'HKD': TranslateLanguage.chinese,
      'EUR': TranslateLanguage.english,
      'GBP': TranslateLanguage.english,
      'CHF': TranslateLanguage.german,
      'CAD': TranslateLanguage.english,
      'AUD': TranslateLanguage.english,
      'NZD': TranslateLanguage.english,
    };
    return currencyToLanguage[currencyCode];
  }

  /// Get or create translator for Korean -> target language
  Future<OnDeviceTranslator?> _getTranslator(String currencyCode) async {
    final targetLang = getLanguageForCurrency(currencyCode);
    if (targetLang == null || targetLang == TranslateLanguage.korean) {
      return null;
    }

    final key = '${TranslateLanguage.korean.bcpCode}_${targetLang.bcpCode}';

    if (!_translators.containsKey(key)) {
      // Check if model is downloaded
      final isDownloaded = await _modelManager.isModelDownloaded(
        targetLang.bcpCode,
      );
      if (!isDownloaded) {
        // Download the model
        await _modelManager.downloadModel(targetLang.bcpCode);
      }

      _translators[key] = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.korean,
        targetLanguage: targetLang,
      );
    }

    return _translators[key];
  }

  /// Translate Korean text to the language for the given currency
  Future<String> translate(String koreanText, String currencyCode) async {
    try {
      final translator = await _getTranslator(currencyCode);
      if (translator == null) {
        return koreanText; // Return original for Korean or unsupported
      }
      return await translator.translateText(koreanText);
    } catch (e) {
      print('Translation error: $e');
      return koreanText;
    }
  }

  /// Translate to multiple currencies at once
  Future<Map<String, String>> translateToMultiple(
    String koreanText,
    List<String> currencyCodes,
  ) async {
    final results = <String, String>{};

    for (final code in currencyCodes) {
      results[code] = await translate(koreanText, code);
    }

    return results;
  }

  /// Check if language model is downloaded
  Future<bool> isModelDownloaded(String currencyCode) async {
    final lang = getLanguageForCurrency(currencyCode);
    if (lang == null || lang == TranslateLanguage.korean) {
      return true;
    }
    return await _modelManager.isModelDownloaded(lang.bcpCode);
  }

  /// Download language model for currency
  Future<bool> downloadModel(String currencyCode) async {
    final lang = getLanguageForCurrency(currencyCode);
    if (lang == null || lang == TranslateLanguage.korean) {
      return true;
    }
    try {
      await _modelManager.downloadModel(lang.bcpCode);
      return true;
    } catch (e) {
      print('Model download error: $e');
      return false;
    }
  }

  /// Dispose all translators
  void dispose() {
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
