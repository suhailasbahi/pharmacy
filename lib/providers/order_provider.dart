import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';

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