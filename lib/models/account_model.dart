import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAccount {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String phone;
  final double balance;
  final DateTime createdAt;
  final String? branchId;
  final String companyId;

  CustomerAccount({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.phone,
    required this.balance,
    required this.createdAt,
    this.branchId,
    required this.companyId,
  });

  factory CustomerAccount.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return CustomerAccount(
      id: id,
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      createdAt:
          (map['createdAt'] as Timestamp).toDate(),
      branchId: map['branchId'],
      companyId: map['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'phone': phone,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'branchId': branchId,
      'companyId': companyId,
    };
  }

  CustomerAccount copyWith({
    String? id,
    String? pharmacyId,
    String? pharmacyName,
    String? phone,
    double? balance,
    DateTime? createdAt,
    String? branchId,
    String? companyId,
  }) {
    return CustomerAccount(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName:
          pharmacyName ?? this.pharmacyName,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      branchId: branchId ?? this.branchId,
      companyId: companyId ?? this.companyId,
    );
  }
}

class SupplierAccount {
  final String id;
  final String companyId;
  final String companyName;
  final String phone;
  final double balance;
  final DateTime createdAt;
  final String pharmacyId;

  SupplierAccount({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.phone,
    required this.balance,
    required this.createdAt,
    required this.pharmacyId,
  });

  factory SupplierAccount.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SupplierAccount(
      id: id,
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      createdAt:
          (map['createdAt'] as Timestamp).toDate(),
      pharmacyId: map['pharmacyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'phone': phone,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'pharmacyId': pharmacyId,
    };
  }

  SupplierAccount copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? phone,
    double? balance,
    DateTime? createdAt,
    String? pharmacyId,
  }) {
    return SupplierAccount(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName:
          companyName ?? this.companyName,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      pharmacyId: pharmacyId ?? this.pharmacyId,
    );
  }
}

// معاملة دفتر أستاذ (مشترك بين الطرفين)
class LedgerTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final String note;
  final String type; // 'purchase' (شراء/مبيعات) أو 'payment' (دفع)

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
      type: map['type'] ?? 'purchase',
    );
  }
}