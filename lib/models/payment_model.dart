class PaymentModel {
  final String id;

  final String accountId;
  final String accountType; // customer | supplier

  final String companyId;
  final String pharmacyId;

  final double amount;

  final String paymentMethod;
  // cash | transfer | wallet

  final String note;

  final DateTime createdAt;

  final String? orderId;

  PaymentModel({
    required this.id,
    required this.accountId,
    required this.accountType,
    required this.companyId,
    required this.pharmacyId,
    required this.amount,
    required this.paymentMethod,
    required this.note,
    required this.createdAt,
    this.orderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'accountType': accountType,
      'companyId': companyId,
      'pharmacyId': pharmacyId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'orderId': orderId,
    };
  }

  factory PaymentModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PaymentModel(
      id: id,
      accountId: map['accountId'] ?? '',
      accountType: map['accountType'] ?? '',
      companyId: map['companyId'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      note: map['note'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      orderId: map['orderId'],
    );
  }
}