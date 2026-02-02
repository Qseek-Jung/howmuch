enum ExpenseCategory {
  food, // 식비
  lodging, // 숙박
  transport, // 교통
  shopping, // 쇼핑
  tour, // 관광
  golf, // 골프
  activity, // 액티비티
  medical, // 의료비
  etc, // 기타
}

enum PaymentMethod { cash, card, etc }

class LedgerExpense {
  final String id;
  final DateTime date;
  final ExpenseCategory category;
  final String title;
  final double amountLocal; // Amount in local currency
  final String currencyCode; // e.g., 'USD', 'EUR'
  final double exchangeRate; // Rate to KRW
  final double amountKrw; // Converted amount
  final PaymentMethod paymentMethod;
  final List<String> payers; // List of member names who share this cost
  final String? memo;
  final List<String> receiptPaths; // Local paths to images

  LedgerExpense({
    required this.id,
    required this.date,
    required this.category,
    required this.title,
    required this.amountLocal,
    required this.currencyCode,
    required this.exchangeRate,
    required this.amountKrw,
    required this.paymentMethod, // Default cash if not provided logic handled in UI
    required this.payers,
    this.memo,
    required this.receiptPaths,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category.index,
      'title': title,
      'amountLocal': amountLocal,
      'currencyCode': currencyCode,
      'exchangeRate': exchangeRate,
      'amountKrw': amountKrw,
      'paymentMethod': paymentMethod.index,
      'payers': payers,
      'memo': memo,
      'receiptPaths': receiptPaths,
    };
  }

  factory LedgerExpense.fromJson(Map<String, dynamic> json) {
    return LedgerExpense(
      id: json['id'],
      date: DateTime.parse(json['date']),
      category: ExpenseCategory.values[json['category'] ?? 5],
      title: json['title'],
      amountLocal: (json['amountLocal'] as num).toDouble(),
      currencyCode: json['currencyCode'],
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
      amountKrw: (json['amountKrw'] as num).toDouble(),
      paymentMethod: PaymentMethod.values[json['paymentMethod'] ?? 0],
      payers: List<String>.from(json['payers'] ?? []),
      memo: json['memo'],
      receiptPaths: List<String>.from(
        json['receiptPaths'] ??
            (json['receiptPath'] != null ? [json['receiptPath']] : []),
      ),
    );
  }
}
