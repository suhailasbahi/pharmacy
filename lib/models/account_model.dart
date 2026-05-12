class SupplierAccount {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final double balance;
  final DateTime createdAt;
  final List<LedgerTransaction> transactions;
  final String? companyId; // الشركة التي يتبع لها هذا المورد

  SupplierAccount({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.balance = 0,
    required this.createdAt,
    this.transactions = const [],
    this.companyId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'companyId': companyId,
    };
  }

  factory SupplierAccount.fromMap(String id, Map<String, dynamic> map) {
    return SupplierAccount(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      balance: (map['balance'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      transactions: (map['transactions'] as List?)
              ?.map((t) => LedgerTransaction.fromMap(t))
              .toList() ??
          [],
      companyId: map['companyId'],
    );
  }

  SupplierAccount copyWith({
    double? balance,
    List<LedgerTransaction>? transactions,
    String? companyId,
  }) {
    return SupplierAccount(
      id: id,
      name: name,
      phone: phone,
      email: email,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      transactions: transactions ?? this.transactions,
      companyId: companyId ?? this.companyId,
    );
  }
}

class CustomerAccount {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String phone;
  final double balance;
  final DateTime createdAt;
  final List<LedgerTransaction> transactions;
  final String? branchId;
  final String? companyId; // الشركة التي يتبع لها هذا العميل

  CustomerAccount({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.phone,
    this.balance = 0,
    required this.createdAt,
    this.transactions = const [],
    this.branchId,
    this.companyId,
  });

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'phone': phone,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'branchId': branchId,
      'companyId': companyId,
    };
  }

  factory CustomerAccount.fromMap(String id, Map<String, dynamic> map) {
    return CustomerAccount(
      id: id,
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      transactions: (map['transactions'] as List?)?.map((t) => LedgerTransaction.fromMap(t)).toList() ?? [],
      branchId: map['branchId'],
      companyId: map['companyId'],
    );
  }

  CustomerAccount copyWith({
    double? balance,
    List<LedgerTransaction>? transactions,
    String? branchId,
    String? companyId,
  }) {
    return CustomerAccount(
      id: id,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      phone: phone,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      transactions: transactions ?? this.transactions,
      branchId: branchId ?? this.branchId,
      companyId: companyId ?? this.companyId,
    );
  }
}

class LedgerTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final String note;
  final String type;

  LedgerTransaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type,
    };
  }

  factory LedgerTransaction.fromMap(Map<String, dynamic> map) {
    return LedgerTransaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      note: map['note'] ?? '',
      type: map['type'] ?? 'adjustment',
    );
  }
}