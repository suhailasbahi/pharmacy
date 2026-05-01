import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agency_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';

class StorageService {
  static const String _agenciesKey = 'agencies_data';
  static const String _ordersKey = 'orders_data';
  static const String _cartKey = 'cart_data';
  static const String _selectedCityKey = 'selected_city';
  
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== الوكالات والمنتجات ==========
  Future<void> saveAgencies(List<AgencyModel> agencies) async {
    final List<Map<String, dynamic>> agenciesMap = agencies.map((a) => a.toMap()).toList();
    await _prefs.setString(_agenciesKey, jsonEncode(agenciesMap));
  }

  Future<List<AgencyModel>> loadAgencies() async {
    final String? data = _prefs.getString(_agenciesKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((item) => AgencyModel.fromMap('', item as Map<String, dynamic>)).toList();
  }

  // ========== الطلبات ==========
  Future<void> saveOrders(List<OrderModel> orders) async {
    final List<Map<String, dynamic>> ordersMap = orders.map((o) => o.toMap()).toList();
    await _prefs.setString(_ordersKey, jsonEncode(ordersMap));
  }

  Future<List<OrderModel>> loadOrders() async {
    final String? data = _prefs.getString(_ordersKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((item) => OrderModel.fromMap('', item as Map<String, dynamic>)).toList();
  }

  // ========== السلة ==========
  Future<void> saveCart(List<CartItem> cartItems) async {
    final List<Map<String, dynamic>> cartMap = cartItems.map((item) => item.toMap()).toList();
    await _prefs.setString(_cartKey, jsonEncode(cartMap));
  }

  Future<List<CartItem>> loadCart() async {
    final String? data = _prefs.getString(_cartKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((item) => CartItem.fromMap(item as Map<String, dynamic>)).toList();
  }

  // ========== المحافظة ==========
  Future<void> saveSelectedCity(String city) async => await _prefs.setString(_selectedCityKey, city);
  String? loadSelectedCity() => _prefs.getString(_selectedCityKey);

  Future<void> clearAll() async => await _prefs.clear();
}