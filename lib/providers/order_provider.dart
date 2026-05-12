import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import '../models/account_model.dart' as ledger;
import 'account_provider.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];

  List<OrderModel> get orders => _orders;

  Future<void> addOrders(
    List<CartItem> cartItems,
    double totalPrice, {
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyCity,
    required String regionId,
    required String paymentType,
    required String paymentMethod,
    int? creditDays,
  }) async {
    final Map<String, List<CartItem>> itemsByCompany = {};
    for (var item in cartItems) {
      itemsByCompany.putIfAbsent(item.companyId, () => []).add(item);
    }
    for (var entry in itemsByCompany.entries) {
      final companyId = entry.key;
      final items = entry.value;
      final companyName = items.first.companyName;
      final companyTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final orderId = DateTime.now().millisecondsSinceEpoch.toString() + companyId;
      final order = OrderModel(
        id: orderId,
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
        branchId: null,
      );
      await _firestore.collection('orders').doc(orderId).set(order.toMap());
      _orders.insert(0, order);
    }
    notifyListeners();
  }

  Future<void> acceptOrder(String orderId, AccountProvider accountProvider) async {
    final docRef = _firestore.collection('orders').doc(orderId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final order = OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    if (order.status != 'pending') return;

    await docRef.update({'status': 'accepted'});
    
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = OrderModel(
        id: _orders[index].id,
        pharmacyId: _orders[index].pharmacyId,
        pharmacyName: _orders[index].pharmacyName,
        pharmacyCity: _orders[index].pharmacyCity,
        regionId: _orders[index].regionId,
        companyId: _orders[index].companyId,
        companyName: _orders[index].companyName,
        items: _orders[index].items,
        totalPrice: _orders[index].totalPrice,
        status: 'accepted',
        date: _orders[index].date,
        paymentType: _orders[index].paymentType,
        paymentMethod: _orders[index].paymentMethod,
        creditDays: _orders[index].creditDays,
        createdBy: _orders[index].createdBy,
        assignedTo: _orders[index].assignedTo,
        branchId: _orders[index].branchId,
      );
      notifyListeners();
    }

    if (order.paymentType == 'credit') {
      ledger.CustomerAccount? existingCustomer;
      try {
        existingCustomer = accountProvider.customers.firstWhere(
          (c) => c.pharmacyId == order.pharmacyId,
        );
      } catch (e) {
        existingCustomer = null;
      }
      
      final transaction = ledger.LedgerTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: order.totalPrice,
        date: DateTime.now(),
        note: 'طلب #${order.id.substring(0,8)} - شراء أدوية أجل',
        type: 'purchase',
      );
      
      if (existingCustomer != null) {
        await accountProvider.addCustomerTransaction(existingCustomer.id, transaction);
      } else {
        final newCustomer = ledger.CustomerAccount(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          pharmacyId: order.pharmacyId,
          pharmacyName: order.pharmacyName,
          phone: '',
          balance: order.totalPrice,
          createdAt: DateTime.now(),
          transactions: [transaction],
          branchId: order.branchId,
          companyId: order.companyId, 
        );
        await accountProvider.addCustomer(newCustomer);
      }
      
      ledger.SupplierAccount? existingSupplier;
      try {
        existingSupplier = accountProvider.suppliers.firstWhere(
          (s) => s.name == order.companyName,
        );
      } catch (e) {
        existingSupplier = null;
      }
      
      final supplierTransaction = ledger.LedgerTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: order.totalPrice,
        date: DateTime.now(),
        note: 'طلب #${order.id.substring(0,8)} - شراء أدوية أجل',
        type: 'purchase',
      );
      
      if (existingSupplier != null) {
        await accountProvider.addSupplierTransaction(existingSupplier.id, supplierTransaction);
      } else {
        final newSupplier = ledger.SupplierAccount(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: order.companyName,
          phone: '',
          balance: order.totalPrice,
          createdAt: DateTime.now(),
          transactions: [supplierTransaction],
        );
        await accountProvider.addSupplier(newSupplier);
      }
    }
  }

  Future<void> rejectOrder(String orderId, String? rejectionReason, AccountProvider? accountProvider) async {
    final docRef = _firestore.collection('orders').doc(orderId);
    await docRef.update({
      'status': 'rejected',
      'rejectionReason': rejectionReason,
    });
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = OrderModel(
        id: _orders[index].id,
        pharmacyId: _orders[index].pharmacyId,
        pharmacyName: _orders[index].pharmacyName,
        pharmacyCity: _orders[index].pharmacyCity,
        regionId: _orders[index].regionId,
        companyId: _orders[index].companyId,
        companyName: _orders[index].companyName,
        items: _orders[index].items,
        totalPrice: _orders[index].totalPrice,
        status: 'rejected',
        date: _orders[index].date,
        paymentType: _orders[index].paymentType,
        paymentMethod: _orders[index].paymentMethod,
        creditDays: _orders[index].creditDays,
        rejectionReason: rejectionReason,
        createdBy: _orders[index].createdBy,
        assignedTo: _orders[index].assignedTo,
        branchId: _orders[index].branchId,
      );
      notifyListeners();
    }
  }
    
    // أضف هذه الدالة داخل كلاس OrderProvider

Future<void> updateOrderItems(String orderId, List<OrderItem> newItems, double newTotal) async {
  final docRef = _firestore.collection('orders').doc(orderId);
  await docRef.update({
    'items': newItems.map((i) => i.toMap()).toList(),
    'totalPrice': newTotal,
  });
  // تحديث القائمة المحلية
  final index = _orders.indexWhere((o) => o.id == orderId);
  if (index != -1) {
    _orders[index] = OrderModel(
      id: _orders[index].id,
      pharmacyId: _orders[index].pharmacyId,
      pharmacyName: _orders[index].pharmacyName,
      pharmacyCity: _orders[index].pharmacyCity,
      regionId: _orders[index].regionId,
      companyId: _orders[index].companyId,
      companyName: _orders[index].companyName,
      items: newItems,
      totalPrice: newTotal,
      status: _orders[index].status, // يبقى pending
      date: _orders[index].date,
      paymentType: _orders[index].paymentType,
      paymentMethod: _orders[index].paymentMethod,
      creditDays: _orders[index].creditDays,
      rejectionReason: _orders[index].rejectionReason,
      createdBy: _orders[index].createdBy,
      assignedTo: _orders[index].assignedTo,
      branchId: _orders[index].branchId,
    );
    notifyListeners();
  }
}

  Future<void> updateOrderStatus(String orderId, String newStatus, {String? rejectionReason}) async {
    final docRef = _firestore.collection('orders').doc(orderId);
    await docRef.update({'status': newStatus});
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = OrderModel(
        id: _orders[index].id,
        pharmacyId: _orders[index].pharmacyId,
        pharmacyName: _orders[index].pharmacyName,
        pharmacyCity: _orders[index].pharmacyCity,
        regionId: _orders[index].regionId,
        companyId: _orders[index].companyId,
        companyName: _orders[index].companyName,
        items: _orders[index].items,
        totalPrice: _orders[index].totalPrice,
        status: newStatus,
        date: _orders[index].date,
        paymentType: _orders[index].paymentType,
        paymentMethod: _orders[index].paymentMethod,
        creditDays: _orders[index].creditDays,
        rejectionReason: rejectionReason,
        createdBy: _orders[index].createdBy,
        assignedTo: _orders[index].assignedTo,
        branchId: _orders[index].branchId,
      );
      notifyListeners();
    }
  }

  Future<List<OrderModel>> getOrdersForCompany(String companyId, {String? branchId}) async {
    Query query = _firestore.collection('orders').where('companyId', isEqualTo: companyId);
    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> getOrdersForPharmacy(String pharmacyId) async {
    final snapshot = await _firestore.collection('orders').where('pharmacyId', isEqualTo: pharmacyId).get();
    return snapshot.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> getOrdersForBranch(String branchId) async {
    final snapshot = await _firestore.collection('orders').where('branchId', isEqualTo: branchId).get();
    return snapshot.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }
}