class CurrencyData {
  // Popular Currencies (Ranked 1-10)
  static const List<String> popularCodes = [
    'JPY', // Japan
    'VND', // Vietnam
    'THB', // Thailand
    'USD', // USA
    'CNY', // China
    'IDR', // Indonesia
    'PHP', // Philippines
    'SGD', // Singapore
    'TWD', // Taiwan
    'HKD', // Hong Kong
  ];

  // Full Mapping: Code -> {Country Name KR, Country Name EN, Symbol}
  static const Map<String, Map<String, String>> countryDetails = {
    // Popular
    'JPY': {'countryKR': '일본', 'countryEN': 'Japan', 'name': '엔'},
    'VND': {'countryKR': '베트남', 'countryEN': 'Vietnam', 'name': '동'},
    'THB': {'countryKR': '태국', 'countryEN': 'Thailand', 'name': '바트'},
    'USD': {'countryKR': '미국', 'countryEN': 'United States', 'name': '달러'},
    'CNY': {'countryKR': '중국', 'countryEN': 'China', 'name': '위안'},
    'IDR': {'countryKR': '인도네시아', 'countryEN': 'Indonesia', 'name': '루피아'},
    'PHP': {'countryKR': '필리핀', 'countryEN': 'Philippines', 'name': '페소'},
    'SGD': {'countryKR': '싱가포르', 'countryEN': 'Singapore', 'name': '달러'},
    'TWD': {'countryKR': '대만', 'countryEN': 'Taiwan', 'name': '달러'},
    'HKD': {'countryKR': '홍콩', 'countryEN': 'Hong Kong', 'name': '달러'},

    // Others (Europe/Oceania/etc)
    // Frankfurter Supported & Common travel
    'EUR': {'countryKR': '유럽연합', 'countryEN': 'Eurozone', 'name': '유로'},
    'GBP': {'countryKR': '영국', 'countryEN': 'United Kingdom', 'name': '파운드'},
    'CHF': {'countryKR': '스위스', 'countryEN': 'Switzerland', 'name': '프랑'},
    'CAD': {'countryKR': '캐나다', 'countryEN': 'Canada', 'name': '달러'},
    'AUD': {'countryKR': '호주', 'countryEN': 'Australia', 'name': '달러'},
    'NZD': {'countryKR': '뉴질랜드', 'countryEN': 'New Zealand', 'name': '달러'},
    'MYR': {'countryKR': '말레이시아', 'countryEN': 'Malaysia', 'name': '링깃'},
    'INR': {'countryKR': '인도', 'countryEN': 'India', 'name': '루피'},
    'TRY': {'countryKR': '튀르키예', 'countryEN': 'Turkey', 'name': '리라'},
    'MXN': {'countryKR': '멕시코', 'countryEN': 'Mexico', 'name': '페소'},
    'BGN': {'countryKR': '불가리아', 'countryEN': 'Bulgaria', 'name': '레프'},
    'CZK': {'countryKR': '체코', 'countryEN': 'Czechia', 'name': '코루나'},
    'DKK': {'countryKR': '덴마크', 'countryEN': 'Denmark', 'name': '크로네'},
    'HUF': {'countryKR': '헝가리', 'countryEN': 'Hungary', 'name': '포린트'},
    'ILS': {'countryKR': '이스라엘', 'countryEN': 'Israel', 'name': '셰켈'},
    'ISK': {'countryKR': '아이슬란드', 'countryEN': 'Iceland', 'name': '크로나'},
    'NOK': {'countryKR': '노르웨이', 'countryEN': 'Norway', 'name': '크로네'},
    'PLN': {'countryKR': '폴란드', 'countryEN': 'Poland', 'name': '즈워티'},
    'RON': {'countryKR': '루마니아', 'countryEN': 'Romania', 'name': '레우'},
    'SEK': {'countryKR': '스웨덴', 'countryEN': 'Sweden', 'name': '크로나'},
    'BRL': {'countryKR': '브라질', 'countryEN': 'Brazil', 'name': '헤알'},
    'ZAR': {
      'countryKR': '남아프리카 공화국',
      'countryEN': 'South Africa',
      'name': '랜드',
    },
    'KRW': {'countryKR': '한국', 'countryEN': 'South Korea', 'name': '원'},
  };

  /// Typical Tip Percentages by Currency
  static const Map<String, int> defaultTips = {
    // Asia (Mostly 0% or Service Charge Included)
    'KRW': 0,
    'JPY': 0,
    'CNY': 0,
    'HKD': 0,
    'TWD': 0,
    'THB': 0,
    'VND': 0,
    'IDR': 0,
    'PHP': 10,
    'SGD': 0,
    'MYR': 0,
    'INR': 10,

    // North America (High Tip Culture)
    'USD': 18,
    'CAD': 15,
    'MXN': 10,

    // Europe (Service or 5-10%)
    'EUR': 10,
    'GBP': 10,
    'CHF': 0, // Included in price
    'TRY': 10,
    'BGN': 10,
    'CZK': 10,
    'DKK': 0, // Included
    'HUF': 10,
    'ILS': 12,
    'ISK': 0, // Included
    'NOK': 0, // Included
    'PLN': 10,
    'RON': 10,
    'SEK': 0, // Included
    // Oceania
    'AUD': 0, // Not expected
    'NZD': 0, // Not expected
    // Others
    'BRL': 10,
    'ZAR': 10,
  };

  static String getCountryName(String code) {
    return countryDetails[code]?['countryKR'] ?? code;
  }

  static int getDefaultTip(String code) {
    return defaultTips[code] ?? 0;
  }
}
