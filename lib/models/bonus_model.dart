class BonusModel {
  final double percentage; // 10 for 10%
  final bool forCashOnly; // true = only for cash orders, false = only for credit orders

  BonusModel({
    required this.percentage,
    required this.forCashOnly,
  });

  Map<String, dynamic> toMap() {
    return {
      'percentage': percentage,
      'forCashOnly': forCashOnly,
    };
  }

  factory BonusModel.fromMap(Map<String, dynamic> map) {
    return BonusModel(
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      forCashOnly: map['forCashOnly'] ?? false,
    );
  }
}