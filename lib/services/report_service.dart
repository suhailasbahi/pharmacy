import 'package:flutter/material.dart';  // أضف هذا السطر
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';


class ProductReportModel {
  final String productId;
  final String productName;

  double quantity;
  double revenue;
  int ordersCount;

  ProductReportModel({
    required this.productId,
    required this.productName,
    this.quantity = 0,
    this.revenue = 0,
    this.ordersCount = 0,
  });
}

class SupplierReportModel {
  final String supplierName;

  double total;
  double cash;
  double credit;
  int ordersCount;

  SupplierReportModel({
    required this.supplierName,
    this.total = 0,
    this.cash = 0,
    this.credit = 0,
    this.ordersCount = 0,
  });
}

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================================================
  // الطلبات المعتمدة للتقارير التشغيلية
  // =========================================================
  bool isValidOperationalOrder(OrderModel order) {
    return [
      'accepted',
      'shipped',
      'delivered',
    ].contains(order.status);
  }

  // =========================================================
  // جلب طلبات الشركة
  // =========================================================
  Future<List<OrderModel>> getCompanyOrders(
    String companyId, {
    DateTimeRange? dateRange,
    String? branchId,
  }) async {
    Query query = _firestore
        .collection('orders')
        .where('companyId', isEqualTo: companyId);

    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('branchId', isEqualTo: branchId);
    }

    final snapshot = await query.get();

    List<OrderModel> orders = snapshot.docs
        .map((doc) =>
            OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // فلترة الحالات الصحيحة
    orders = orders.where(isValidOperationalOrder).toList();

    // فلترة التاريخ
    if (dateRange != null) {
      orders = orders.where((o) {
        return o.date.isAfter(
              dateRange.start.subtract(const Duration(days: 1)),
            ) &&
            o.date.isBefore(
              dateRange.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return orders;
  }

  // =========================================================
  // جلب طلبات الصيدلية
  // =========================================================
  Future<List<OrderModel>> getPharmacyOrders(
    String pharmacyId, {
    DateTimeRange? dateRange,
  }) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    List<OrderModel> orders = snapshot.docs
        .map((doc) =>
            OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // فلترة الحالات الصحيحة
    orders = orders.where(isValidOperationalOrder).toList();

    // فلترة التاريخ
    if (dateRange != null) {
      orders = orders.where((o) {
        return o.date.isAfter(
              dateRange.start.subtract(const Duration(days: 1)),
            ) &&
            o.date.isBefore(
              dateRange.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return orders;
  }

  // =========================================================
  // أكثر المنتجات مبيعاً
  // =========================================================
  Future<List<ProductReportModel>> getTopProducts({
    required String companyId,
    DateTimeRange? dateRange,
    String sortBy = 'quantity',
    int limit = 10,
  }) async {
    final orders = await getCompanyOrders(
      companyId,
      dateRange: dateRange,
    );

    final Map<String, ProductReportModel> stats = {};

    for (var order in orders) {
      for (var item in order.items) {
        if (!stats.containsKey(item.productId)) {
          stats[item.productId] = ProductReportModel(
            productId: item.productId,
            productName: item.productName,
          );
        }

        stats[item.productId]!.quantity += item.quantity.toDouble();
        stats[item.productId]!.revenue += item.totalPrice;
        stats[item.productId]!.ordersCount += 1;
      }
    }

    final result = stats.values.toList();

    if (sortBy == 'revenue') {
      result.sort((a, b) => b.revenue.compareTo(a.revenue));
    } else if (sortBy == 'orders') {
      result.sort((a, b) => b.ordersCount.compareTo(a.ordersCount));
    } else {
      result.sort((a, b) => b.quantity.compareTo(a.quantity));
    }

    return result.take(limit).toList();
  }

  // =========================================================
  // المشتريات حسب المورد
  // =========================================================
  Future<List<SupplierReportModel>> getPurchasesBySupplier({
    required String pharmacyId,
    DateTimeRange? dateRange,
  }) async {
    final orders = await getPharmacyOrders(
      pharmacyId,
      dateRange: dateRange,
    );

    final Map<String, SupplierReportModel> stats = {};

    for (var order in orders) {
      if (!stats.containsKey(order.companyName)) {
        stats[order.companyName] = SupplierReportModel(
          supplierName: order.companyName,
        );
      }

      stats[order.companyName]!.total += order.totalPrice;
      stats[order.companyName]!.ordersCount += 1;

      if (order.paymentType == 'cash') {
        stats[order.companyName]!.cash += order.totalPrice;
      } else {
        stats[order.companyName]!.credit += order.totalPrice;
      }
    }

    final result = stats.values.toList();

    result.sort((a, b) => b.total.compareTo(a.total));

    return result;
  }

  // =========================================================
  // مشتريات منتج حسب المورد
  // =========================================================
  Future<Map<String, double>> getProductPurchasesBySupplier({
    required String pharmacyId,
    required String productId,
    DateTimeRange? dateRange,
  }) async {
    final orders = await getPharmacyOrders(
      pharmacyId,
      dateRange: dateRange,
    );

    final Map<String, double> stats = {};

    for (var order in orders) {
      for (var item in order.items) {
        if (item.productId == productId) {
          stats[order.companyName] =
              (stats[order.companyName] ?? 0) + item.totalPrice;
        }
      }
    }

    return stats;
  }

  // =========================================================
  // جميع المنتجات المشتراة للصيدلية
  // =========================================================
  Future<Map<String, String>> getPharmacyProducts(
    String pharmacyId,
  ) async {
    final orders = await getPharmacyOrders(pharmacyId);

    final Map<String, String> products = {};

    for (var order in orders) {
      for (var item in order.items) {
        products[item.productId] = item.productName;
      }
    }

    return products;
  }
}