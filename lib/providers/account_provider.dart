import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';

class AccountProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CustomerAccount> _customers = [];
  List<SupplierAccount> _suppliers = [];

  List<CustomerAccount> get customers => _customers;
  List<SupplierAccount> get suppliers => _suppliers;

  // ========== CUSTOMER MANAGEMENT ==========

  Future<void> loadCustomersForCompany(String companyId) async {
    if (companyId.isEmpty) return;
    final snapshot = await _firestore
        .collection('customer_accounts')
        .where('companyId', isEqualTo: companyId)
        .get();

    _customers = snapshot.docs
        .map((doc) => CustomerAccount.fromMap(doc.id, doc.data()))
        .toList();

    notifyListeners();
  }

  Future<void> addCustomer(CustomerAccount customer) async {
    await _firestore
        .collection('customer_accounts')
        .doc(customer.id)
        .set(customer.toMap());

    _customers.add(customer);
    notifyListeners();
  }

  Future<CustomerAccount?> findCustomerByPharmacyAndCompany(
    String pharmacyId,
    String companyId,
  ) async {
    final snapshot = await _firestore
        .collection('customer_accounts')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .where('companyId', isEqualTo: companyId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CustomerAccount.fromMap(
          snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }

  Future<CustomerAccount> getOrCreateCustomer({
    required String pharmacyId,
    required String pharmacyName,
    required String companyId,
    String? branchId,
    String phone = '',
  }) async {
    // البحث عن حساب موجود
    final existing =
        await findCustomerByPharmacyAndCompany(pharmacyId, companyId);
    if (existing != null) return existing;

    // إنشاء حساب جديد
    final newId = _firestore.collection('customer_accounts').doc().id;

    final newCustomer = CustomerAccount(
      id: newId,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      phone: phone,
      balance: 0,
      createdAt: DateTime.now(),
      branchId: branchId,
      companyId: companyId,
    );

    await _firestore
        .collection('customer_accounts')
        .doc(newId)
        .set(newCustomer.toMap());

    _customers.add(newCustomer);
    notifyListeners();

    return newCustomer;
  }

  // ========== SUPPLIER MANAGEMENT ==========

  Future<void> loadSuppliersForPharmacy(String pharmacyId) async {
    if (pharmacyId.isEmpty) return;
    final snapshot = await _firestore
        .collection('supplier_accounts')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    _suppliers = snapshot.docs
        .map((doc) => SupplierAccount.fromMap(doc.id, doc.data()))
        .toList();

    notifyListeners();
  }

  Future<void> addSupplier(SupplierAccount supplier) async {
    await _firestore
        .collection('supplier_accounts')
        .doc(supplier.id)
        .set(supplier.toMap());

    _suppliers.add(supplier);
    notifyListeners();
  }

  Future<SupplierAccount?> findSupplierByCompanyAndPharmacy(
    String companyId,
    String pharmacyId,
  ) async {
    final snapshot = await _firestore
        .collection('supplier_accounts')
        .where('companyId', isEqualTo: companyId)
        .where('pharmacyId', isEqualTo: pharmacyId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SupplierAccount.fromMap(
          snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }

  Future<SupplierAccount> getOrCreateSupplier({
    required String companyId,
    required String companyName,
    required String pharmacyId,
    String phone = '',
  }) async {
    // البحث عن حساب موجود
    final existing =
        await findSupplierByCompanyAndPharmacy(companyId, pharmacyId);
    if (existing != null) return existing;

    // إنشاء حساب جديد
    final newId = _firestore.collection('supplier_accounts').doc().id;

    final newSupplier = SupplierAccount(
      id: newId,
      companyId: companyId,
      companyName: companyName,
      phone: phone,
      balance: 0,
      createdAt: DateTime.now(),
      pharmacyId: pharmacyId,
    );

    await _firestore
        .collection('supplier_accounts')
        .doc(newId)
        .set(newSupplier.toMap());

    _suppliers.add(newSupplier);
    notifyListeners();

    return newSupplier;
  }

  // ========== LEDGER TRANSACTIONS ==========

  Future<void> addLedgerTransaction({
    required String accountId,
    required String accountType, // customer | supplier
    required String type, // debit | credit
    required double amount,
    required String orderId,
    required String note,
    required String companyId,
    required String pharmacyId,
  }) async {
    final ledgerRef = _firestore.collection('ledger_transactions').doc();

    await ledgerRef.set({
      'accountId': accountId,
      'accountType': accountType,
      'type': type,
      'amount': amount,
      'orderId': orderId,
      'note': note,
      'companyId': companyId,
      'pharmacyId': pharmacyId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }

  Future<void> createOrderLedgerEntry({
    required String orderId,
    required String accountId,
    required String accountType, // customer | supplier
    required double amount,
    required String direction, // sale | purchase | payment
    required String companyId,
    required String pharmacyId,
  }) async {
    String type;
    String note;

    if (direction == 'sale') {
      // بيع: العميل عليه دين (debit يزيد رصيده)
      type = 'debit';
      note = 'مبيعات آجل - الطلب #${orderId.substring(0, 8)}';
    } else if (direction == 'purchase') {
      // شراء: الصيدلية عليها دين للمورد (debit يزيد رصيد المورد)
      type = 'debit';
      note = 'مشتريات آجل - الطلب #${orderId.substring(0, 8)}';
    } else if (direction == 'payment') {
      // سداد: يقل الدين (credit يقلل الرصيد)
      type = 'credit';
      note = 'سداد دفعة - الطلب #${orderId.substring(0, 8)}';
    } else {
      throw Exception('Invalid direction: $direction');
    }

    await addLedgerTransaction(
      accountId: accountId,
      accountType: accountType,
      type: type,
      amount: amount,
      orderId: orderId,
      note: note,
      companyId: companyId,
      pharmacyId: pharmacyId,
    );
  }

  // ========== BALANCE CALCULATION ==========

   Future<double> getAccountBalance(String accountId) async {
  try {
    final snapshot = await _firestore
        .collection('ledger_transactions')
        .where('accountId', isEqualTo: accountId)
        .get();

    double balance = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final type = data['type'] ?? 'debit';
      final amount = (data['amount'] ?? 0).toDouble();

      if (type == 'debit') {
        balance += amount;
      } else {
        balance -= amount;
      }
    }

    return balance;
  } catch (e) {
    debugPrint('getAccountBalance error: $e');
    return 0;
  }
}
    
    
  Future<Map<String, double>> getMultipleBalances(
      List<String> accountIds) async {
    if (accountIds.isEmpty) return {};

    final snapshot = await _firestore
        .collection('ledger_transactions')
        .where('accountId', whereIn: accountIds)
        .get();

    final balances = <String, double>{};
    for (var id in accountIds) balances[id] = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final accountId = data['accountId'];
      final type = data['type'];
      final amount = (data['amount'] as num).toDouble();

      if (type == 'debit') {
        balances[accountId] = (balances[accountId] ?? 0) + amount;
      } else {
        balances[accountId] = (balances[accountId] ?? 0) - amount;
      }
    }

    return balances;
  }

  Future<List<LedgerTransaction>> getAccountTransactions(
    String accountId) async {
  try {
    final snapshot = await _firestore
        .collection('ledger_transactions')
        .where('accountId', isEqualTo: accountId)
        .get();

    final transactions = snapshot.docs.map((doc) {
      final data = doc.data();

      DateTime date = DateTime.now();

      try {
        final createdAt = data['createdAt'];

        if (createdAt is Timestamp) {
          date = createdAt.toDate();
        }
      } catch (_) {}

      final type = data['type'] ?? 'debit';

      return LedgerTransaction(
        id: doc.id,

        amount:
            (data['amount'] ?? 0).toDouble(),

        date: date,

        note: data['note'] ?? '',

        type: type == 'debit'
            ? 'purchase'
            : 'payment',

        orderId: data['orderId'],
      );
    }).toList();

    transactions.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    return transactions;
  } catch (e) {
    debugPrint(
      'getAccountTransactions error: $e',
    );

    return [];
  }
}

  }
