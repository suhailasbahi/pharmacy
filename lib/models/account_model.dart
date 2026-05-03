class SupplierAccount {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final double balance; // رصيد مستحق للصيدلية (موجب يعني للصيدلية على المورد، سالب يعني للصيدلية)
  final DateTime createdAt;
  final List<Transaction> transactions;

  SupplierAccount({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.balance = 0,
    required this.createdAt,
    this.transactions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
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
              ?.map((t) => Transaction.fromMap(t))
              .toList() ??
          [],
    );
  }

  SupplierAccount copyWith({double? balance, List<Transaction>? transactions}) {
    return SupplierAccount(
      id: id,
      name: name,
      phone: phone,
      email: email,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      transactions: transactions ?? this.transactions,
    );
  }
}

class CustomerAccount {
  final String id;
  final String pharmacyId; // معرف الصيدلية
  final String pharmacyName;
  final String phone;
  final double balance; // رصيد مستحق للشركة على الصيدلية (موجب يعني على الصيدلية)
  final DateTime createdAt;
  final List<Transaction> transactions;

  CustomerAccount({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.phone,
    this.balance = 0,
    required this.createdAt,
    this.transactions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'phone': phone,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
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
      transactions: (map['transactions'] as List?)
              ?.map((t) => Transaction.fromMap(t))
              .toList() ??
          [],
    );
  }

  CustomerAccount copyWith({double? balance, List<Transaction>? transactions}) {
    return CustomerAccount(
      id: id,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      phone: phone,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      transactions: transactions ?? this.transactions,
    );
  }
}

class Transaction {
  final String id;
  final double amount; // موجب: دفع (تسديد)، سالب: شراء بالدين (التزام)
  final DateTime date;
  final String note;
  final String type; // 'payment', 'purchase', 'adjustment'

  Transaction({
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

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      note: map['note'] ?? '',
      type: map['type'] ?? 'adjustment',
    );
  }
}