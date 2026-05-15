import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';

class TopProductsScreen extends StatefulWidget {
  const TopProductsScreen({Key? key}) : super(key: key);

  @override
  State<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends State<TopProductsScreen> {
  DateTimeRange? _dateRange;
  List<OrderModel> _allOrders = [];
  Map<String, ProductModel> _products = {};
  bool _isLoading = true;
  String _sortBy = 'quantity'; // 'quantity' or 'revenue'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId;
    if (companyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // جلب الطلبات
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    List<OrderModel> orders = await orderProvider.getOrdersForCompany(companyId);
    
    if (_dateRange != null) {
      orders = orders.where((o) =>
          o.date.isAfter(_dateRange!.start) &&
          o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    // جلب أسماء المنتجات
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('companyId', isEqualTo: companyId)
        .get();
    
    for (var doc in productsSnapshot.docs) {
      _products[doc.id] = ProductModel.fromMap(doc.id, doc.data());
    }

    setState(() {
      _allOrders = orders;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('أكثر المنتجات مبيعاً'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // تجميع المبيعات لكل منتج
    Map<String, Map<String, double>> productStats = {};

    for (var order in _allOrders) {
      for (var item in order.items) {
        final productId = item.productId;
        final quantity = item.quantity.toDouble();
        final revenue = item.totalPrice;

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {'quantity': 0.0, 'revenue': 0.0};
        }
        productStats[productId]!['quantity'] = (productStats[productId]!['quantity'] ?? 0) + quantity;
        productStats[productId]!['revenue'] = (productStats[productId]!['revenue'] ?? 0) + revenue;
      }
    }

    // ترتيب حسب الاختيار
    final entries = productStats.entries.toList();
    if (_sortBy == 'quantity') {
      entries.sort((a, b) => (b.value['quantity'] ?? 0).compareTo(a.value['quantity'] ?? 0));
    } else {
      entries.sort((a, b) => (b.value['revenue'] ?? 0).compareTo(a.value['revenue'] ?? 0));
    }

    final topProducts = entries.take(10).toList();
    final totalQuantity = entries.fold(0.0, (s, e) => s + (e.value['quantity'] ?? 0));
    final totalRevenue = entries.fold(0.0, (s, e) => s + (e.value['revenue'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('أكثر المنتجات مبيعاً'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'تحديد فترة',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'quantity', child: Text('حسب الكمية')),
              const PopupMenuItem(value: 'revenue', child: Text('حسب القيمة')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            if (_dateRange != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('من ${_formatDate(_dateRange!.start)} إلى ${_formatDate(_dateRange!.end)}'),
                    TextButton(
                      onPressed: () async {
                        setState(() => _dateRange = null);
                        await _loadData();
                      },
                      child: const Text('إلغاء التصفية'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildSummaryCard('إجمالي الكمية', totalQuantity, 'قطعة', Colors.blue),
                  const SizedBox(width: 12),
                  _buildSummaryCard('إجمالي الإيرادات', totalRevenue, 'جنيه', Colors.green),
                ],
              ),
            ),
            Expanded(
              child: topProducts.isEmpty
                  ? const Center(child: Text('لا توجد مبيعات'))
                  : ListView.builder(
                      itemCount: topProducts.length,
                      itemBuilder: (context, index) {
                        final entry = topProducts[index];
                        final product = _products[entry.key];
                        final productName = product?.name ?? entry.key;
                        final quantity = entry.value['quantity'] ?? 0;
                        final revenue = entry.value['revenue'] ?? 0;
                        final quantityPercent = totalQuantity > 0 ? (quantity / totalQuantity) * 100 : 0;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(productName),
                            subtitle: Text('الكمية: ${quantity.toStringAsFixed(0)} | الإيرادات: ${revenue.toStringAsFixed(2)}'),
                            trailing: Text('${quantityPercent.toStringAsFixed(1)}%'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, String unit, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${value.toStringAsFixed(0)} $unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}