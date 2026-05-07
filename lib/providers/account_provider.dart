import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart' as ledger;

class AccountProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ledger.SupplierAccount> _suppliers = [];
  List<ledger.CustomerAccount> _customers = [];

  List<ledger.SupplierAccount> get suppliers => _suppliers;
  List<ledger.CustomerAccount> get customers => _customers;

  Future<void> loadCustomers() async {
    final snapshot = await _firestore.collection('customers').get();
    _customers = snapshot.docs.map((doc) => ledger.CustomerAccount.fromMap(doc.id, doc.data())).toList();
    notifyListeners();
  }

  Future<void> loadSuppliers() async {
    final snapshot = await _firestore.collection('suppliers').get();
    _suppliers = snapshot.docs.map((doc) => ledger.SupplierAccount.fromMap(doc.id, doc.data())).toList();
    notifyListeners();
  }

  Future<void> addCustomer(ledger.CustomerAccount customer) async {
    await _firestore.collection('customers').doc(customer.id).set(customer.toMap());
    _customers.add(customer);
    notifyListeners();
  }

  Future<void> updateCustomer(ledger.CustomerAccount customer) async {
    await _firestore.collection('customers').doc(customer.id).update(customer.toMap());
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) _customers[index] = customer;
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _firestore.collection('customers').doc(id).delete();
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> addCustomerTransaction(String customerId, ledger.LedgerTransaction transaction) async {
    final customerRef = _firestore.collection('customers').doc(customerId);
    final doc = await customerRef.get();
    if (!doc.exists) return;
    
    final customer = ledger.CustomerAccount.fromMap(doc.id, doc.data()!);
    final newTransactions = [...customer.transactions, transaction];
    double newBalance;
    if (transaction.type == 'payment') {
      newBalance = customer.balance - transaction.amount;
    } else {
      newBalance = customer.balance + transaction.amount;
    }
    final updatedCustomer = customer.copyWith(balance: newBalance, transactions: newTransactions);
    await customerRef.update(updatedCustomer.toMap());
    
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) _customers[index] = updatedCustomer;
    notifyListeners();
  }

  Future<void> addSupplier(ledger.SupplierAccount supplier) async {
    await _firestore.collection('suppliers').doc(supplier.id).set(supplier.toMap());
    _suppliers.add(supplier);
    notifyListeners();
  }

  Future<void> updateSupplier(ledger.SupplierAccount supplier) async {
    await _firestore.collection('suppliers').doc(supplier.id).update(supplier.toMap());
    final index = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) _suppliers[index] = supplier;
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    await _firestore.collection('suppliers').doc(id).delete();
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> addSupplierTransaction(String supplierId, ledger.LedgerTransaction transaction) async {
    final supplierRef = _firestore.collection('suppliers').doc(supplierId);
    final doc = await supplierRef.get();
    if (!doc.exists) return;
    
    final supplier = ledger.SupplierAccount.fromMap(doc.id, doc.data()!);
    final newTransactions = [...supplier.transactions, transaction];
    double newBalance;
    if (transaction.type == 'payment') {
      newBalance = supplier.balance - transaction.amount;
    } else {
      newBalance = supplier.balance + transaction.amount;
    }
    final updatedSupplier = supplier.copyWith(balance: newBalance, transactions: newTransactions);
    await supplierRef.update(updatedSupplier.toMap());
    
    final index = _suppliers.indexWhere((s) => s.id == supplierId);
    if (index != -1) _suppliers[index] = updatedSupplier;
    notifyListeners();
  }

  Future<List<ledger.CustomerAccount>> getCustomersForBranch(String branchId) async {
    final snapshot = await _firestore.collection('customers').where('branchId', isEqualTo: branchId).get();
    return snapshot.docs.map((doc) => ledger.CustomerAccount.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> loadSampleData() async {
    if (_suppliers.isEmpty) {
      await addSupplier(ledger.SupplierAccount(
        id: 'sup1',
        name: 'مستودع الخير',
        phone: '777777777',
        email: 'alkhair@example.com',
        balance: 5000,
        createdAt: DateTime.now(),
        transactions: [
          ledger.LedgerTransaction(id: 't1', amount: 5000, date: DateTime.now(), note: 'فاتورة أدوية', type: 'purchase'),
        ],
      ));
    }
    if (_customers.isEmpty) {
      await addCustomer(ledger.CustomerAccount(
        id: 'cust1',
        pharmacyId: 'pharm1',
        pharmacyName: 'صيدلية السلام',
        phone: '777888999',
        balance: 2500,
        createdAt: DateTime.now(),
        transactions: [
          ledger.LedgerTransaction(id: 't1', amount: 2500, date: DateTime.now(), note: 'شراء أدوية أجل', type: 'purchase'),
        ],
        branchId: null,
      ));
    }
  }
}