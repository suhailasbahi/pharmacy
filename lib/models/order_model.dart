import 'package:flutter/material.dart';

class OrderModel {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyCity;
  final String regionId;
  final String companyId;
  final String companyName;
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // pending, accepted, rejected, shipped, delivered
  final DateTime date;
  final String paymentType; // 'cash' or 'credit'
  final String paymentMethod; // 'transfer', 'wallet', 'cash_on_delivery'
  final int? creditDays;
  final String? rejectionReason;

  OrderModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyCity,
    required this.regionId,
    required this.companyId,
    required this.companyName,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.date,
    required this.paymentType,
    required this.paymentMethod,
    this.creditDays,
    this.rejectionReason,
  });

  String get paymentTypeText => paymentType == 'cash' ? 'نقدي' : 'أجل';
  String get paymentMethodText {
    switch (paymentMethod) {
      case 'transfer': return 'حوالة';
      case 'wallet': return 'محفظة إلكترونية';
      case 'cash_on_delivery': return 'كاش عند الاستلام';
      default: return paymentMethod;
    }
  }

  String get statusText {
    switch (status) {
      case 'pending': return 'قيد المراجعة';
      case 'accepted': return 'تم القبول';
      case 'rejected': return 'مرفوض';
      case 'shipped': return 'تم الشحن';
      case 'delivered': return 'تم التسليم';
      default: return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyCity': pharmacyCity,
      'regionId': regionId,
      'companyId': companyId,
      'companyName': companyName,
      'items': items.map((i) => i.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'date': date.toIso8601String(),
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'creditDays': creditDays,
      'rejectionReason': rejectionReason,
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      pharmacyCity: map['pharmacyCity'] ?? '',
      regionId: map['regionId'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      items: (map['items'] as List?)?.map((i) => OrderItem.fromMap(i)).toList() ?? [],
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      paymentType: map['paymentType'] ?? 'cash',
      paymentMethod: map['paymentMethod'] ?? 'transfer',
      creditDays: map['creditDays'],
      rejectionReason: map['rejectionReason'],
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String scientificName;
  final int quantity;
  final int quantityInPieces; // total pieces (for display)
  final String unit; // 'piece' or 'carton'
  final int? piecesPerCarton;
  final double price; // unit price at time of order
  final int? bonusReceived;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.scientificName,
    required this.quantity,
    required this.quantityInPieces,
    required this.unit,
    this.piecesPerCarton,
    required this.price,
    this.bonusReceived,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'scientificName': scientificName,
      'quantity': quantity,
      'quantityInPieces': quantityInPieces,
      'unit': unit,
      'piecesPerCarton': piecesPerCarton,
      'price': price,
      'bonusReceived': bonusReceived,
      'totalPrice': totalPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      scientificName: map['scientificName'] ?? '',
      quantity: map['quantity'] ?? 0,
      quantityInPieces: map['quantityInPieces'] ?? 0,
      unit: map['unit'] ?? 'piece',
      piecesPerCarton: map['piecesPerCarton'],
      price: (map['price'] ?? 0).toDouble(),
      bonusReceived: map['bonusReceived'],
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }
}