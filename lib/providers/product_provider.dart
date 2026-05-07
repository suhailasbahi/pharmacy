import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  Future<void> loadProducts(String companyId, {String? agencyId}) async {
    Query query = _firestore.collection('products').where('companyId', isEqualTo: companyId);
    if (agencyId != null) {
      query = query.where('agencyId', isEqualTo: agencyId);
    }
    final snapshot = await query.get();
    _products = snapshot.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection('products').doc(product.id).set(product.toMap());
    _products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) _products[index] = product;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}