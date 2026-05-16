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

  Future<void> acceptOrder(
  String orderId,
  AccountProvider accountProvider,
) async {
  try {
    final orderRef = _firestore.collection('orders').doc(orderId);

    await _firestore.runTransaction((trx) async {

      final orderSnapshot = await trx.get(orderRef);

      if (!orderSnapshot.exists) {
        throw Exception('Order not found');
      }

      final order = OrderModel.fromMap(
        orderSnapshot.id,
        orderSnapshot.data() as Map<String, dynamic>,
      );

      // حماية من التكرار
      if (order.status != 'pending') {
        throw Exception('Order already processed');
      }

      // تحديث حالة الطلب
      trx.update(orderRef, {
        'status': 'accepted',
      });

      // ===== الطلبات الآجلة فقط =====

      if (order.paymentType == 'credit') {

        // =====================================================
        // Customer Account
        // =====================================================

        final customerQuery = await _firestore
            .collection('customer_accounts')
            .where('pharmacyId', isEqualTo: order.pharmacyId)
            .where('companyId', isEqualTo: order.companyId)
            .limit(1)
            .get();

        final customerTransaction = LedgerTransaction(
          id: _firestore.collection('tmp').doc().id,
          amount: order.totalPrice,
          date: DateTime.now(),
          note:
              'طلب #${order.id.substring(0, 8)} - مبيعات آجل',
          type: 'purchase',
        );

        if (customerQuery.docs.isNotEmpty) {

          final customerDoc = customerQuery.docs.first;

          final customer = CustomerAccount.fromMap(
            customerDoc.id,
            customerDoc.data(),
          );

          final updatedTransactions = [
            ...customer.transactions,
            customerTransaction,
          ];

          final newBalance =
              customer.balance + order.totalPrice;

          trx.update(
            customerDoc.reference,
            {
              'balance': newBalance,
              'transactions': updatedTransactions
                  .map((e) => e.toMap())
                  .toList(),
            },
          );

        } else {

          final newCustomerRef = _firestore
              .collection('customer_accounts')
              .doc();

          final newCustomer = CustomerAccount(
            id: newCustomerRef.id,
            pharmacyId: order.pharmacyId,
            pharmacyName: order.pharmacyName,
            phone: '',
            balance: order.totalPrice,
            createdAt: DateTime.now(),
            transactions: [customerTransaction],
            branchId: order.branchId,
            companyId: order.companyId,
          );

          trx.set(
            newCustomerRef,
            newCustomer.toMap(),
          );
        }

        // =====================================================
        // Supplier Account
        // =====================================================

        final supplierQuery = await _firestore
            .collection('supplier_accounts')
            .where('companyId', isEqualTo: order.companyId)
            .where('pharmacyId', isEqualTo: order.pharmacyId)
            .limit(1)
            .get();

        final supplierTransaction = LedgerTransaction(
          id: _firestore.collection('tmp').doc().id,
          amount: order.totalPrice,
          date: DateTime.now(),
          note:
              'طلب #${order.id.substring(0, 8)} - مشتريات آجل',
          type: 'purchase',
        );

        if (supplierQuery.docs.isNotEmpty) {

          final supplierDoc = supplierQuery.docs.first;

          final supplier = SupplierAccount.fromMap(
            supplierDoc.id,
            supplierDoc.data(),
          );

          final updatedTransactions = [
            ...supplier.transactions,
            supplierTransaction,
          ];

          final newBalance =
              supplier.balance + order.totalPrice;

          trx.update(
            supplierDoc.reference,
            {
              'balance': newBalance,
              'transactions': updatedTransactions
                  .map((e) => e.toMap())
                  .toList(),
            },
          );

        } else {

          final newSupplierRef = _firestore
              .collection('supplier_accounts')
              .doc();

          final newSupplier = SupplierAccount(
            id: newSupplierRef.id,
            companyId: order.companyId,
            companyName: order.companyName,
            phone: '',
            balance: order.totalPrice,
            createdAt: DateTime.now(),
            transactions: [supplierTransaction],
            pharmacyId: order.pharmacyId,
          );

          trx.set(
            newSupplierRef,
            newSupplier.toMap(),
          );
        }

        // =====================================================
        // Financial Ledger Transactions
        // =====================================================

        final customerLedgerRef = _firestore
            .collection('financial_transactions')
            .doc();

        trx.set(customerLedgerRef, {
          'id': customerLedgerRef.id,
          'type': 'customer_credit',
          'accountType': 'customer',
          'pharmacyId': order.pharmacyId,
          'companyId': order.companyId,
          'orderId': order.id,
          'amount': order.totalPrice,
          'createdAt': Timestamp.now(),
          'note':
              'مبيعات آجل للطلب #${order.id.substring(0, 8)}',
        });

        final supplierLedgerRef = _firestore
            .collection('financial_transactions')
            .doc();

        trx.set(supplierLedgerRef, {
          'id': supplierLedgerRef.id,
          'type': 'supplier_credit',
          'accountType': 'supplier',
          'pharmacyId': order.pharmacyId,
          'companyId': order.companyId,
          'orderId': order.id,
          'amount': order.totalPrice,
          'createdAt': Timestamp.now(),
          'note':
              'مشتريات آجل للطلب #${order.id.substring(0, 8)}',
        });
      }
    });

    // تحديث القائمة المحلية

    final index = _orders.indexWhere((o) => o.id == orderId);

    if (index != -1) {

      final oldOrder = _orders[index];

      _orders[index] = OrderModel(
        id: oldOrder.id,
        pharmacyId: oldOrder.pharmacyId,
        pharmacyName: oldOrder.pharmacyName,
        pharmacyCity: oldOrder.pharmacyCity,
        regionId: oldOrder.regionId,
        companyId: oldOrder.companyId,
        companyName: oldOrder.companyName,
        items: oldOrder.items,
        totalPrice: oldOrder.totalPrice,
        status: 'accepted',
        date: oldOrder.date,
        paymentType: oldOrder.paymentType,
        paymentMethod: oldOrder.paymentMethod,
        creditDays: oldOrder.creditDays,
        rejectionReason: oldOrder.rejectionReason,
        createdBy: oldOrder.createdBy,
        assignedTo: oldOrder.assignedTo,
        branchId: oldOrder.branchId,
      );

      notifyListeners();
    }

  } catch (e) {
    debugPrint('acceptOrder error: $e');
    rethrow;
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