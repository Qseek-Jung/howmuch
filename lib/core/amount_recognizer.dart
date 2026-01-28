class AmountParser {
  static final _currency = RegExp(
    r'(원|엔|옌|달러|불|위안|유로|USD|KRW|JPY|CNY|EUR)',
    caseSensitive: false,
  );

  static String sanitize(String input) {
    var s = input.trim();
    s = s.replaceAll(_currency, '');
    s = s.replaceAll(RegExp(r'\([^)]*\)'), ''); // Remove (3980) etc
    s = s.replaceAll(
      RegExp(r'(정도|쯤|가량|약|대략|총|합계|금액|가격|결제|으로|로|은|는|가|을|를)'),
      '',
    );
    return s.trim();
  }

  static const _digitMap = {
    '영': 0,
    '공': 0,
    '일': 1,
    '이': 2,
    '삼': 3,
    '사': 4,
    '오': 5,
    '육': 6,
    '칠': 7,
    '팔': 8,
    '구': 9,
  };

  static const _unitMap = {
    '십': 10.0,
    '백': 100.0,
    '천': 1000.0,
    '만': 10000.0,
    '억': 100000000.0,
    '조': 1000000000000.0,
  };

  /// 고정밀 한국어 금액 파서
  static double? parseAmount(String raw) {
    if (raw.isEmpty) return null;

    final preprocessed = raw.trim();

    // 1. Sanitize
    var s = preprocessed.trim().replaceAll(RegExp(r'[,.]$'), '');
    s = s.replaceAll(_currency, '');
    s = s.replaceAll(RegExp(r'\([^)]*\)'), ''); // Remove (3980) etc
    s = s.replaceAll(RegExp(r'(정도|쯤|가량|약|대략|총|합계|금액|가격|결제)'), '');

    // 2. Tokenize
    final regex = RegExp(r'(\d+[\d,.]*|[가-힣])');
    final matches = regex.allMatches(s);
    if (matches.isEmpty) {
      return null;
    }

    final tokens = matches.map((m) => m.group(0)!).toList();

    double grandTotal = 0;
    double segmentSum = 0;
    double currentNum = 0;

    for (final token in tokens) {
      if (_unitMap.containsKey(token)) {
        double multiplier = _unitMap[token]!;
        if (multiplier >= 10000) {
          double base =
              segmentSum +
              (currentNum == 0 && segmentSum == 0 ? 1 : currentNum);
          double added = base * multiplier;
          grandTotal += added;
          segmentSum = 0;
          currentNum = 0;
        } else {
          double base = (currentNum == 0 ? 1 : currentNum);
          double added = base * multiplier;
          segmentSum += added;
          currentNum = 0;
        }
      } else if (_digitMap.containsKey(token)) {
        double val = _digitMap[token]!.toDouble();
        // 🎯 SMART DIGIT CONCATENATION (Hangul)
        if (currentNum > 0 && currentNum < 1000 && val < 10) {
          currentNum = currentNum * 10 + val;
        } else {
          currentNum += val;
        }
      } else if (RegExp(r'^\d').hasMatch(token)) {
        double val = double.tryParse(token.replaceAll(',', '')) ?? 0;

        // 🎯 HEURISTIC: "Ascending Value Split" for Dropped Units
        if (currentNum > 0 && val > currentNum && val >= 100) {
          grandTotal += currentNum * 10000;
          currentNum = 0;
        }

        // 🎯 HEURISTIC: Robust Digit Concatenation
        // Join if previous ends in non-zero (12 3 -> 123) OR if this is zero (126 0 -> 1260)
        // Add if previous ends in zero (100 25 -> 125) - likely addition context.
        if (currentNum > 0 &&
            !token.contains('.') &&
            (currentNum % 10 != 0 || val == 0)) {
          // Join digits
          String combined =
              currentNum.toInt().toString() + token.replaceAll(',', '');
          currentNum = double.tryParse(combined) ?? (currentNum + val);
        } else {
          currentNum += val;
        }
      }
    }

    double result = grandTotal + segmentSum + currentNum;
    return result == 0 ? null : result;
  }
}
