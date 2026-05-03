import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import '../models/account_model.dart'; // أضف هذا السطر
import 'account_provider.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];

  List<OrderModel> get orders => _orders;

  void addOrders(
    List<CartItem> cartItems,
    double totalPrice, {
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyCity,
    required String regionId,
    required String paymentType,
    required String paymentMethod,
    int? creditDays,
  }) {
    final Map<String, List<CartItem>> itemsByCompany = {};
    for (var item in cartItems) {
      itemsByCompany.putIfAbsent(item.companyId, () => []).add(item);
    }
    for (var entry in itemsByCompany.entries) {
      final companyId = entry.key;
      final items = entry.value;
      final companyName = items.first.companyName;
      final companyTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + companyId,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        pharmacyCity: pharmacyCity,
        regionId: regionId,
        companyId: companyId,
        companyName: companyName,
        items: items.map((item) => OrderItem(
          productId: item.id,
          productName: item.name,
          scientificName: item.scientificName,
          quantity: item.quantity,
          quantityInPieces: item.totalPieces,
          unit: item.unit,
          piecesPerCarton: item.piecesPerCarton,
          price: item.unitPrice,
          bonusReceived: item.bonus,
          totalPrice: item.totalPrice,
        )).toList(),
        totalPrice: companyTotal,
        status: 'pending',
        date: DateTime.now(),
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        creditDays: creditDays,
      );
      _orders.insert(0, order);
    }
    notifyListeners();
  }

  void acceptOrder(String orderId, AccountProvider accountProvider) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      if (order.status == 'pending') {
        // تحديث حالة الطلب إلى accepted
        final updatedOrder = OrderModel(
          id: order.id,
          pharmacyId: order.pharmacyId,
          pharmacyName: order.pharmacyName,
          pharmacyCity: order.pharmacyCity,
          regionId: order.regionId,
          companyId: order.companyId,
          companyName: order.companyName,
          items: order.items,
          totalPrice: order.totalPrice,
          status: 'accepted',
          date: order.date,
          paymentType: order.paymentType,
          paymentMethod: order.paymentMethod,
          creditDays: order.creditDays,
        );
        _orders[index] = updatedOrder;
        
        // إذا كان الدفع آجلاً، نضيف المعاملة إلى حسابات العملاء والموردين
        if (order.paymentType == 'credit') {
          // 1. إضافة معاملة للعميل (الصيدلية) في جهة الشركة
          CustomerAccount? existingCustomer;
          try {
            existingCustomer = accountProvider.customers.firstWhere(
              (c) => c.pharmacyId == order.pharmacyId,
            );
          } catch (e) {
            existingCustomer = null;
          }
          
          final transaction = Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: order.totalPrice,
            date: DateTime.now(),
            note: 'طلب #${order.id.substring(0,8)} - شراء أدوية أجل',
            type: 'purchase',
          );
          
          if (existingCustomer != null) {
            accountProvider.addCustomerTransaction(existingCustomer.id, transaction);
          } else {
            final newCustomer = CustomerAccount(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              pharmacyId: order.pharmacyId,
              pharmacyName: order.pharmacyName,
              phone: '',
              balance: order.totalPrice,
              createdAt: DateTime.now(),
              transactions: [transaction],
            );
            accountProvider.addCustomer(newCustomer);
          }
          
          // 2. إضافة معاملة للمورد (الشركة) في جهة الصيدلية
          SupplierAccount? existingSupplier;
          try {
            existingSupplier = accountProvider.suppliers.firstWhere(
              (s) => s.name == order.companyName,
            );
          } catch (e) {
            existingSupplier = null;
          }
          
          final supplierTransaction = Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: order.totalPrice,
            date: DateTime.now(),
            note: 'طلب #${order.id.substring(0,8)} - شراء أدوية أجل',
            type: 'purchase',
          );
          
          if (existingSupplier != null) {
            accountProvider.addSupplierTransaction(existingSupplier.id, supplierTransaction);
          } else {
            final newSupplier = SupplierAccount(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: order.companyName,
              phone: '',
              balance: order.totalPrice,
              createdAt: DateTime.now(),
              transactions: [supplierTransaction],
            );
            accountProvider.addSupplier(newSupplier);
          }
        }
        
        notifyListeners();
      }
    }
  }

  void rejectOrder(String orderId, String? rejectionReason, AccountProvider? accountProvider) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final old = _orders[index];
      _orders[index] = OrderModel(
        id: old.id,
        pharmacyId: old.pharmacyId,
        pharmacyName: old.pharmacyName,
        pharmacyCity: old.pharmacyCity,
        regionId: old.regionId,
        companyId: old.companyId,
        companyName: old.companyName,
        items: old.items,
        totalPrice: old.totalPrice,
        status: 'rejected',
        date: old.date,
        paymentType: old.paymentType,
        paymentMethod: old.paymentMethod,
        creditDays: old.creditDays,
        rejectionReason: rejectionReason,
      );
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, String newStatus, {String? rejectionReason}) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final old = _orders[index];
      _orders[index] = OrderModel(
        id: old.id,
        pharmacyId: old.pharmacyId,
        pharmacyName: old.pharmacyName,
        pharmacyCity: old.pharmacyCity,
        regionId: old.regionId,
        companyId: old.companyId,
        companyName: old.companyName,
        items: old.items,
        totalPrice: old.totalPrice,
        status: newStatus,
        date: old.date,
        paymentType: old.paymentType,
        paymentMethod: old.paymentMethod,
        creditDays: old.creditDays,
        rejectionReason: rejectionReason,
      );
      notifyListeners();
    }
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  List<OrderModel> getOrdersForCompany(String companyId) {
    return _orders.where((order) => order.companyId == companyId).toList();
  }

  List<OrderModel> getOrdersForPharmacy(String pharmacyId) {
    return _orders.where((order) => order.pharmacyId == pharmacyId).toList();
  }
}