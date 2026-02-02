import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final Map<String, OnDeviceTranslator> _translators = {};
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  /// Map Country Code (Flag Code) to TranslateLanguage
  static const Map<String, TranslateLanguage> countryToLanguage = {
    // === Asia ===
    'KR': TranslateLanguage.korean, // South Korea
    'JP': TranslateLanguage.japanese, // Japan
    'CN': TranslateLanguage.chinese, // China
    'TW': TranslateLanguage.chinese, // Taiwan
    'HK': TranslateLanguage.chinese, // Hong Kong
    'MO': TranslateLanguage.chinese, // Macau
    'VN': TranslateLanguage.vietnamese, // Vietnam
    'TH': TranslateLanguage.thai, // Thailand
    'ID': TranslateLanguage.indonesian, // Indonesia
    'MY': TranslateLanguage.malay, // Malaysia
    'PH': TranslateLanguage.english,
    'SG': TranslateLanguage.english, // Singapore
    'IN': TranslateLanguage.hindi, // India
    'PK': TranslateLanguage.urdu, // Pakistan
    'BD': TranslateLanguage.bengali, // Bangladesh
    'NP': TranslateLanguage.english,
    'LK': TranslateLanguage.tamil,
    'KH': TranslateLanguage.english,
    'LA': TranslateLanguage.english,
    'MM': TranslateLanguage.english,
    'MN': TranslateLanguage.english,
    'UZ': TranslateLanguage.english,
    'KZ': TranslateLanguage.russian,
    'KG': TranslateLanguage.russian,
    'TJ': TranslateLanguage.russian,
    'TM': TranslateLanguage.russian,
    'AF': TranslateLanguage.persian,
    'IR': TranslateLanguage.persian, // Iran
    'IQ': TranslateLanguage.arabic, // Iraq
    'SA': TranslateLanguage.arabic, // Saudi Arabia
    'AE': TranslateLanguage.arabic, // UAE
    'QA': TranslateLanguage.arabic, // Qatar
    'KW': TranslateLanguage.arabic, // Kuwait
    'BH': TranslateLanguage.arabic, // Bahrain
    'OM': TranslateLanguage.arabic, // Oman
    'YE': TranslateLanguage.arabic, // Yemen
    'LB': TranslateLanguage.arabic, // Lebanon
    'JO': TranslateLanguage.arabic, // Jordan
    'SY': TranslateLanguage.arabic, // Syria
    'IL': TranslateLanguage.hebrew, // Israel
    'TR': TranslateLanguage.turkish, // Turkey
    'AZ': TranslateLanguage.english,
    'GE': TranslateLanguage.georgian, // Georgia
    'AM': TranslateLanguage.english,
    // === Europe ===
    'GB': TranslateLanguage.english, // UK
    'IE': TranslateLanguage.english, // Ireland
    'FR': TranslateLanguage.french, // France
    'MC': TranslateLanguage.french, // Monaco
    'BE': TranslateLanguage.french,
    'LU': TranslateLanguage.french,
    'CH': TranslateLanguage.german,
    'DE': TranslateLanguage.german, // Germany
    'AT': TranslateLanguage.german, // Austria
    'LI': TranslateLanguage.german, // Liechtenstein
    'ES': TranslateLanguage.spanish, // Spain
    'PT': TranslateLanguage.portuguese, // Portugal
    'IT': TranslateLanguage.italian, // Italy
    'SM': TranslateLanguage.italian, // San Marino
    'VA': TranslateLanguage.italian, // Vatican City
    'NL': TranslateLanguage.dutch, // Netherlands
    'DK': TranslateLanguage.danish, // Denmark
    'NO': TranslateLanguage.norwegian, // Norway
    'SE': TranslateLanguage.swedish, // Sweden
    'FI': TranslateLanguage.finnish, // Finland
    'IS': TranslateLanguage.icelandic, // Iceland
    'PL': TranslateLanguage.polish, // Poland
    'CZ': TranslateLanguage.czech, // Czechia
    'SK': TranslateLanguage.slovak, // Slovakia
    'HU': TranslateLanguage.hungarian, // Hungary
    'RO': TranslateLanguage.romanian, // Romania
    'MD': TranslateLanguage.romanian, // Moldova (Romanian)
    'BG': TranslateLanguage.bulgarian, // Bulgaria
    'GR': TranslateLanguage.greek, // Greece
    'CY': TranslateLanguage.greek, // Cyprus
    'AL': TranslateLanguage.albanian, // Albania
    'MK': TranslateLanguage.macedonian, // North Macedonia
    'RS': TranslateLanguage.english,
    'HR': TranslateLanguage.croatian, // Croatia
    'SI': TranslateLanguage.slovenian, // Slovenia
    'BA': TranslateLanguage.croatian,
    'ME': TranslateLanguage.english,
    'RU': TranslateLanguage.russian, // Russia
    'BY': TranslateLanguage.belarusian, // Belarus
    'UA': TranslateLanguage.ukrainian, // Ukraine
    'EE': TranslateLanguage.estonian, // Estonia
    'LV': TranslateLanguage.latvian, // Latvia
    'LT': TranslateLanguage.lithuanian, // Lithuania
    'MT': TranslateLanguage.english,
    'AD': TranslateLanguage.catalan, // Andorra
    // === North America ===
    'US': TranslateLanguage.english, // USA
    'CA': TranslateLanguage.english, // Canada (English/French)
    'MX': TranslateLanguage.spanish, // Mexico
    'GT': TranslateLanguage.spanish, // Guatemala
    'BZ': TranslateLanguage.english, // Belize
    'SV': TranslateLanguage.spanish, // El Salvador
    'HN': TranslateLanguage.spanish, // Honduras
    'NI': TranslateLanguage.spanish, // Nicaragua
    'CR': TranslateLanguage.spanish, // Costa Rica
    'PA': TranslateLanguage.spanish, // Panama
    'CU': TranslateLanguage.spanish, // Cuba
    'DO': TranslateLanguage.spanish, // Dominican Republic
    'HT': TranslateLanguage.french,
    'JM': TranslateLanguage.english, // Jamaica
    'BS': TranslateLanguage.english, // Bahamas
    'BB': TranslateLanguage.english, // Barbados
    'TT': TranslateLanguage.english, // Trinidad & Tobago
    // === South America ===
    'BR': TranslateLanguage.portuguese, // Brazil
    'AR': TranslateLanguage.spanish, // Argentina
    'CO': TranslateLanguage.spanish, // Colombia
    'CL': TranslateLanguage.spanish, // Chile
    'PE': TranslateLanguage.spanish, // Peru
    'VE': TranslateLanguage.spanish, // Venezuela
    'EC': TranslateLanguage.spanish, // Ecuador
    'BO': TranslateLanguage.spanish, // Bolivia
    'PY': TranslateLanguage.spanish, // Paraguay
    'UY': TranslateLanguage.spanish, // Uruguay
    'GY': TranslateLanguage.english, // Guyana
    'SR': TranslateLanguage.dutch, // Suriname (Dutch official)
    'GF': TranslateLanguage.french, // French Guiana
    // === Oceania ===
    'AU': TranslateLanguage.english, // Australia
    'NZ': TranslateLanguage.english, // New Zealand
    'FJ': TranslateLanguage.english, // Fiji
    'PG': TranslateLanguage.english, // Papua New Guinea
    'SB': TranslateLanguage.english, // Solomon Islands
    'VU': TranslateLanguage.english, // Vanuatu
    'WS': TranslateLanguage.english, // Samoa
    'TO': TranslateLanguage.english, // Tonga
    // === Africa ===
    'ZA': TranslateLanguage.afrikaans,
    'EG': TranslateLanguage.arabic, // Egypt
    'MA': TranslateLanguage.arabic, // Morocco
    'DZ': TranslateLanguage.arabic, // Algeria
    'TN': TranslateLanguage.arabic, // Tunisia
    'LY': TranslateLanguage.arabic, // Libya
    'SD': TranslateLanguage.arabic, // Sudan
    'NG': TranslateLanguage.english, // Nigeria
    'GH': TranslateLanguage.english, // Ghana
    'KE': TranslateLanguage.swahili, // Kenya
    'TZ': TranslateLanguage.swahili, // Tanzania
    'UG': TranslateLanguage.swahili, // Uganda
    'ET': TranslateLanguage.english,
    'RW': TranslateLanguage.english,
    'SN': TranslateLanguage.french, // Senegal
    'CI': TranslateLanguage.french, // Cote d'Ivoire
    'CM': TranslateLanguage.french, // Cameroon
    'CD': TranslateLanguage.french, // DR Congo
    'MG': TranslateLanguage.french, // Madagascar
    'AO': TranslateLanguage.portuguese, // Angola
    'MZ': TranslateLanguage.portuguese, // Mozambique
    'ZW': TranslateLanguage.english, // Zimbabwe
    'NA': TranslateLanguage.english, // Namibia
    'BW': TranslateLanguage.english, // Botswana
    'ZM': TranslateLanguage.english, // Zambia
    'MU': TranslateLanguage.english, // Mauritius
    'SC': TranslateLanguage.french, // Seychelles
  };

  /// Map ShoppingPhrases language keys to TranslateLanguage
  static const Map<String, TranslateLanguage> phraseKeyToLanguage = {
    'en': TranslateLanguage.english,
    'JPY': TranslateLanguage.japanese,
    'CNY': TranslateLanguage.chinese,
    'VND': TranslateLanguage.vietnamese,
    'THB': TranslateLanguage.thai,
    'IDR': TranslateLanguage.indonesian,
    'es': TranslateLanguage.spanish,
    'fr': TranslateLanguage.french,
    'de': TranslateLanguage.german,
    'it': TranslateLanguage.italian,
    'pt': TranslateLanguage.portuguese,
    'ru': TranslateLanguage.russian,
    'ar': TranslateLanguage.arabic,
    'tr': TranslateLanguage.turkish,
    'pl': TranslateLanguage.polish,
    'cs': TranslateLanguage.czech,
    'hu': TranslateLanguage.hungarian,
    'sv': TranslateLanguage.swedish,
    'no': TranslateLanguage.norwegian,
    'da': TranslateLanguage.danish,
    'fi': TranslateLanguage.finnish,
    'nl': TranslateLanguage.dutch,
    'el': TranslateLanguage.greek,
    'he': TranslateLanguage.hebrew,
    'ro': TranslateLanguage.romanian,
  };

  /// Get language based on Country Code (Primary) or Currency Code (Fallback)
  static TranslateLanguage? getLanguage(String uniqueId) {
    final parts = uniqueId.split(':');
    final name = parts[0];
    String code = parts.length > 1 ? parts[1] : parts[0];

    // Handle legacy format potentially
    if (RegExp(r'^[A-Z]{3}$').hasMatch(parts[0])) {
      code = parts[0];
    }

    // 1. Try mapping by Country Name (Korean)
    final langByName = _getLangByCountryName(name);
    if (langByName != null) return langByName;

    // 2. Fallback to Currency Code mapping
    const currencyToLanguage = {
      'KRW': TranslateLanguage.korean,
      'USD': TranslateLanguage.english,
      'JPY': TranslateLanguage.japanese,
      'CNY': TranslateLanguage.chinese,
      'VND': TranslateLanguage.vietnamese,
      'THB': TranslateLanguage.thai,
      'IDR': TranslateLanguage.indonesian,
      'EUR': TranslateLanguage.english,
      'GBP': TranslateLanguage.english,
      'HKD': TranslateLanguage.chinese,
      'TWD': TranslateLanguage.chinese,
      'CHF': TranslateLanguage.german,
    };
    return currencyToLanguage[code];
  }

  static TranslateLanguage? _getLangByCountryName(String name) {
    if (['독일', '오스트리아', '스위스'].contains(name)) return TranslateLanguage.german;
    if (['프랑스', '벨기에', '룩셈부르크'].contains(name)) return TranslateLanguage.french;
    if (['스페인', '멕시코', '아르헨티나'].contains(name))
      return TranslateLanguage.spanish;
    if (['일본'].contains(name)) return TranslateLanguage.japanese;
    if (['중국'].contains(name)) return TranslateLanguage.chinese;
    if (['대한민국'].contains(name)) return TranslateLanguage.korean;
    if (['베트남'].contains(name)) return TranslateLanguage.vietnamese;
    if (['태국'].contains(name)) return TranslateLanguage.thai;
    if (['인도네시아'].contains(name)) return TranslateLanguage.indonesian;
    if (['미국', '영국', '호주', '캐나다', '뉴질랜드', '싱가포르', '필리핀'].contains(name))
      return TranslateLanguage.english;
    return null;
  }

  /// Get or create translator for Korean -> target language
  Future<OnDeviceTranslator?> _getTranslator(String uniqueId) async {
    final targetLang = getLanguage(uniqueId);
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

  /// Translate Korean text to a specific language key (e.g., 'es', 'JPY')
  Future<String> translateToLanguage(String koreanText, String langKey) async {
    final targetLang = phraseKeyToLanguage[langKey];
    if (targetLang == null || targetLang == TranslateLanguage.korean) {
      return koreanText;
    }

    try {
      final key = '${TranslateLanguage.korean.bcpCode}_${targetLang.bcpCode}';
      if (!_translators.containsKey(key)) {
        final isDownloaded = await _modelManager.isModelDownloaded(
          targetLang.bcpCode,
        );
        if (!isDownloaded) {
          await _modelManager.downloadModel(targetLang.bcpCode);
        }
        _translators[key] = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.korean,
          targetLanguage: targetLang,
        );
      }
      return await _translators[key]!.translateText(koreanText);
    } catch (e) {
      print('Translation error for $langKey: $e');
      return koreanText;
    }
  }

  /// Translate Korean text to the language for the given currency
  Future<String> translate(String koreanText, String uniqueId) async {
    try {
      final translator = await _getTranslator(uniqueId);
      if (translator == null) {
        return koreanText;
      }
      return await translator.translateText(koreanText);
    } catch (e) {
      print('Translation error: $e');
      return koreanText;
    }
  }

  /// Translate to all supported phrase languages
  Future<Map<String, String>> translateToAll(String koreanText) async {
    final results = <String, String>{};
    for (final entry in phraseKeyToLanguage.entries) {
      final langKey = entry.key;
      results[langKey] = await translateToLanguage(koreanText, langKey);
    }
    return results;
  }

  /// Check if language model is downloaded
  Future<bool> isModelDownloaded(String uniqueId) async {
    final lang = getLanguage(uniqueId);
    if (lang == null || lang == TranslateLanguage.korean) {
      return true;
    }
    return await _modelManager.isModelDownloaded(lang.bcpCode);
  }

  /// Download language model for currency
  Future<bool> downloadModel(String uniqueId) async {
    final lang = getLanguage(uniqueId);
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
