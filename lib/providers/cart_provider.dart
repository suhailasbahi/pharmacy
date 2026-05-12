import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalBonus => _items.fold(0, (sum, item) => sum + item.bonus);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  bool isInCart(String productId) => _items.any((item) => item.id == productId);

  void _applyBonus(CartItem item, bool isCashOrder) {
    double bonusPercentage = item.getBonusPercentage(isCashOrder);
    if (bonusPercentage > 0) {
      int totalPieces = item.totalPieces;
      int bonusPieces = (totalPieces * bonusPercentage / 100).floor();
      item.bonus = bonusPieces;
    } else {
      item.bonus = 0;
    }
  }

  void updateBonusesForCompany(String companyId, bool isCashOrder) {
    for (var item in _items) {
      if (item.companyId == companyId) {
        _applyBonus(item, isCashOrder);
      }
    }
    notifyListeners();
  }

  int _getMinAllowedQuantity(CartItem item) {
    if (item.unit == 'carton') {
      return (item.minOrderQuantity / item.piecesPerCarton).ceil();
    } else {
      return item.minOrderQuantity;
    }
  }

  void addToCart(CartItem item, {bool isCashOrder = true}) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
      _applyBonus(_items[existingIndex], isCashOrder);
    } else {
      int initialQty = item.quantity;
      int minQty = _getMinAllowedQuantity(item);
      if (initialQty < minQty) initialQty = minQty;
      item.quantity = initialQty;
      _items.add(item);
      _applyBonus(item, isCashOrder);
    }
    notifyListeners();
  }

  void increaseQuantity(String productId, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index != -1) {
      _items[index].quantity++;
      _applyBonus(_items[index], isCashOrder);
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index != -1) {
      final item = _items[index];
      final minAllowed = _getMinAllowedQuantity(item);
      if (item.quantity > minAllowed) {
        item.quantity--;
        _applyBonus(item, isCashOrder);
        notifyListeners();
      }
    }
  }

  void updateQuantity(String productId, int newQuantity, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index != -1) {
      final item = _items[index];
      final minAllowed = _getMinAllowedQuantity(item);
      int finalQty = newQuantity;
      if (finalQty < minAllowed) finalQty = minAllowed;
      if (finalQty > 0) {
        _items[index].quantity = finalQty;
        _applyBonus(_items[index], isCashOrder);
        notifyListeners();
      }
    }
  }

  void changeUnit(String productId, String newUnit, BuildContext context, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index == -1) return;
    final item = _items[index];
    if (item.unit == newUnit) return;
    if (item.piecesPerCarton <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('هذا المنتج لا يدعم الشراء بالكرتون'), backgroundColor: Colors.orange),
      );
      return;
    }

    int newQuantity;
    if (item.unit == 'piece' && newUnit == 'carton') {
      newQuantity = (item.quantity / item.piecesPerCarton).ceil();
      if (newQuantity < 1) newQuantity = 1;
    } else if (item.unit == 'carton' && newUnit == 'piece') {
      newQuantity = item.quantity * item.piecesPerCarton;
    } else {
      return;
    }

    item.quantity = newQuantity;
    item.unit = newUnit;
    final minAllowed = _getMinAllowedQuantity(item);
    if (item.quantity < minAllowed) item.quantity = minAllowed;

    _applyBonus(item, isCashOrder);
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}