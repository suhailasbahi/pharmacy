import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';

class AccountProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CustomerAccount> _customers = [];
  List<SupplierAccount> _suppliers = [];

  List<CustomerAccount> get customers => _customers;
  List<SupplierAccount> get suppliers => _suppliers;

  // ========== دوال العملاء (من وجهة نظر الشركة) ==========
  
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

  Future<void> addCustomerTransaction(
  String customerId,
  LedgerTransaction transaction,
) async {
  final docRef =
      _firestore.collection('customer_accounts').doc(customerId);

  await _firestore.runTransaction((trx) async {
    final snapshot = await trx.get(docRef);

    if (!snapshot.exists) {
      throw Exception('Customer account not found');
    }

    final customer = CustomerAccount.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    final newTransactions = [
      ...customer.transactions,
      transaction,
    ];

    double newBalance;

    if (transaction.type == 'payment') {
      newBalance = customer.balance - transaction.amount;
    } else {
      newBalance = customer.balance + transaction.amount;
    }

    final updated = customer.copyWith(
      balance: newBalance,
      transactions: newTransactions,
    );

    trx.update(docRef, updated.toMap());

    final index = _customers.indexWhere((c) => c.id == customerId);

    if (index != -1) {
      _customers[index] = updated;
    }
  });

  notifyListeners();
}

  Future<void> updateCustomer(CustomerAccount customer) async {
    await _firestore.collection('customer_accounts').doc(customer.id).update(customer.toMap());
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) _customers[index] = customer;
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _firestore.collection('customer_accounts').doc(id).delete();
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }


  // ========== دوال الموردين (من وجهة نظر الصيدلية) ==========

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

  Future<void> addSupplierTransaction(
  String supplierId,
  LedgerTransaction transaction,
) async {
  final docRef =
      _firestore.collection('supplier_accounts').doc(supplierId);

  await _firestore.runTransaction((trx) async {
    final snapshot = await trx.get(docRef);

    if (!snapshot.exists) {
      throw Exception('Supplier account not found');
    }

    final supplier = SupplierAccount.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    final newTransactions = [
      ...supplier.transactions,
      transaction,
    ];

    double newBalance;

    if (transaction.type == 'payment') {
      newBalance = supplier.balance - transaction.amount;
    } else {
      newBalance = supplier.balance + transaction.amount;
    }

    final updated = supplier.copyWith(
      balance: newBalance,
      transactions: newTransactions,
    );

    trx.update(docRef, updated.toMap());

    final index = _suppliers.indexWhere((s) => s.id == supplierId);

    if (index != -1) {
      _suppliers[index] = updated;
    }
  });

  notifyListeners();
}

  Future<void> updateSupplier(SupplierAccount supplier) async {
    await _firestore.collection('supplier_accounts').doc(supplier.id).update(supplier.toMap());
    final index = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) _suppliers[index] = supplier;
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    await _firestore.collection('supplier_accounts').doc(id).delete();
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }


  Future<SupplierAccount?> findSupplierByCompanyAndPharmacy(String companyId, String pharmacyId) async {
    final snapshot = await _firestore
        .collection('supplier_accounts')
        .where('companyId', isEqualTo: companyId)
        .where('pharmacyId', isEqualTo: pharmacyId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return SupplierAccount.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }

  Future<CustomerAccount?> findCustomerByPharmacyAndCompany(String pharmacyId, String companyId) async {
    final snapshot = await _firestore
        .collection('customer_accounts')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .where('companyId', isEqualTo: companyId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return CustomerAccount.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }
}