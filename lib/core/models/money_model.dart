class MoneyModel {

  final double amount;

  // YER | SAR
  final String currency;

  // سعر الصرف بالنسبة للعملة الأساسية
  final double exchangeRate;

  // القيمة المحولة للعملة الأساسية
  final double baseAmount;

  const MoneyModel({
    required this.amount,
    required this.currency,
    required this.exchangeRate,
    required this.baseAmount,
  });

  factory MoneyModel.fromMap(Map<String, dynamic> map) {
    return MoneyModel(
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'YER',
      exchangeRate: (map['exchangeRate'] ?? 1).toDouble(),
      baseAmount: (map['baseAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'baseAmount': baseAmount,
    };
  }

  MoneyModel copyWith({
    double? amount,
    String? currency,
    double? exchangeRate,
    double? baseAmount,
  }) {
    return MoneyModel(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      baseAmount: baseAmount ?? this.baseAmount,
    );
  }
}