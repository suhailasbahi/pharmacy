import 'package:flutter/material.dart';
import '../models/account_model.dart';

class AccountProvider extends ChangeNotifier {
  List<SupplierAccount> _suppliers = [];
  List<CustomerAccount> _customers = [];

  List<SupplierAccount> get suppliers => _suppliers;
  List<CustomerAccount> get customers => _customers;

  // ========== إدارة الموردين (للصيدلية) ==========
  void addSupplier(SupplierAccount supplier) {
    _suppliers.add(supplier);
    notifyListeners();
  }

  void updateSupplier(SupplierAccount supplier) {
    final index = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      _suppliers[index] = supplier;
      notifyListeners();
    }
  }

  void deleteSupplier(String id) {
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void addSupplierTransaction(String supplierId, Transaction transaction) {
  final index = _suppliers.indexWhere((s) => s.id == supplierId);
  if (index != -1) {
    final supplier = _suppliers[index];
    final newTransactions = [...supplier.transactions, transaction];
    double newBalance;
    if (transaction.type == 'payment') {
      // تسديد المورد يقلل الرصيد المستحق (لأن الصيدلية دفعت)
      newBalance = supplier.balance - transaction.amount;
    } else {
      // شراء بالدين يزيد الرصيد المستحق
      newBalance = supplier.balance + transaction.amount;
    }
    _suppliers[index] = supplier.copyWith(balance: newBalance, transactions: newTransactions);
    notifyListeners();
  }
}
  // ========== إدارة العملاء (للشركة) ==========
  void addCustomer(CustomerAccount customer) {
    _customers.add(customer);
    notifyListeners();
  }

  void updateCustomer(CustomerAccount customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void addCustomerTransaction(String customerId, Transaction transaction) {
  final index = _customers.indexWhere((c) => c.id == customerId);
  if (index != -1) {
    final customer = _customers[index];
    final newTransactions = [...customer.transactions, transaction];
    double newBalance;
    if (transaction.type == 'payment') {
      // الدفعة المستلمة تقلل الرصيد المستحق على العميل
      newBalance = customer.balance - transaction.amount;
    } else {
      // المشتريات تزيد الرصيد
      newBalance = customer.balance + transaction.amount;
    }
    _customers[index] = customer.copyWith(balance: newBalance, transactions: newTransactions);
    notifyListeners();
  }
}

  // بيانات تجريبية للاختبار
  void loadSampleData() {
    if (_suppliers.isEmpty) {
      _suppliers = [
        SupplierAccount(
          id: 'sup1',
          name: 'مستودع الخير',
          phone: '777777777',
          email: 'alkhair@example.com',
          balance: 5000,
          createdAt: DateTime.now(),
          transactions: [
            Transaction(id: 't1', amount: 5000, date: DateTime.now(), note: 'فاتورة أدوية', type: 'purchase'),
          ],
        ),
      ];
    }
    if (_customers.isEmpty) {
      _customers = [
        CustomerAccount(
          id: 'cust1',
          pharmacyId: 'pharm1',
          pharmacyName: 'صيدلية السلام',
          phone: '777888999',
          balance: -2500,
          createdAt: DateTime.now(),
          transactions: [
            Transaction(id: 't1', amount: -2500, date: DateTime.now(), note: 'شراء أدوية أجل', type: 'purchase'),
          ],
        ),
      ];
    }
    notifyListeners();
  }
}