import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTransaction({
    required String accountId,
    required String accountType, // customer | supplier
    required String type, // debit | credit
    required double amount,
    required String orderId,
    required String note,
    required String companyId,
    required String pharmacyId,
  }) async {
    final ref = _firestore.collection('financial_transactions').doc();

    await ref.set({
      'id': ref.id,
      'accountId': accountId,
      'accountType': accountType,
      'type': type,
      'amount': amount,
      'orderId': orderId,
      'note': note,
      'companyId': companyId,
      'pharmacyId': pharmacyId,
      'createdAt': Timestamp.now(),
    });
  }

  Future<double> calculateBalance(String accountId) async {
    final snapshot = await _firestore
        .collection('financial_transactions')
        .where('accountId', isEqualTo: accountId)
        .get();

    double balance = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final amount = (data['amount'] ?? 0).toDouble();

      if (type == 'credit') {
        balance += amount;
      } else {
        balance -= amount;
      }
    }

    return balance;
  }
}