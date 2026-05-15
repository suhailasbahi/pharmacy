import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';

class ProductPurchasesScreen extends StatefulWidget {
  const ProductPurchasesScreen({Key? key}) : super(key: key);

  @override
  State<ProductPurchasesScreen> createState() => _ProductPurchasesScreenState();
}

class _ProductPurchasesScreenState extends State<ProductPurchasesScreen> {
  String? _selectedProductId;
  Map<String, String> _productIdToName = {};
  DateTimeRange? _dateRange;
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<String> _filteredProductIds = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadData();
  }

  Future<void> _loadProducts() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId;
    if (companyId == null) return;
    
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('companyId', isEqualTo: companyId)
        .get();
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      _productIdToName[doc.id] = data['name'] ?? 'منتج بدون اسم';
    }
    _filteredProductIds = _productIdToName.keys.toList();
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final pharmacyId = auth.currentUserId;
    if (pharmacyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    List<OrderModel> orders = await orderProvider.getOrdersForPharmacy(pharmacyId);
    
    if (_dateRange != null) {
      orders = orders.where((o) =>
          o.date.isAfter(_dateRange!.start) &&
          o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }
    
    setState(() {
      _allOrders = orders;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProductIds = _productIdToName.keys.toList();
      } else {
        _filteredProductIds = _productIdToName.entries
            .where((entry) => entry.value.toLowerCase().contains(query.toLowerCase()))
            .map((entry) => entry.key)
            .toList();
      }
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
          title: const Text('مشتريات صنف حسب المورد'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // تجميع المشتريات للمنتج المختار
    Map<String, double> purchasesBySupplier = {};
    double totalPurchases = 0;

    if (_selectedProductId != null) {
      for (var order in _allOrders) {
        for (var item in order.items) {
          if (item.productId == _selectedProductId) {
            final supplier = order.companyName;
            purchasesBySupplier[supplier] = (purchasesBySupplier[supplier] ?? 0) + item.totalPrice;
            totalPurchases += item.totalPrice;
          }
        }
      }
    }

    final entries = purchasesBySupplier.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشتريات صنف حسب المورد'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'تحديد فترة',
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
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _filterProducts(''),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: _filterProducts,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                hint: const Text('اختر المنتج'),
                value: _selectedProductId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('-- اختر منتجاً --')),
                  ..._filteredProductIds.map((productId) {
                    return DropdownMenuItem(
                      value: productId,
                      child: Text(_productIdToName[productId] ?? productId),
                    );
                  }),
                ],
                onChanged: (val) => setState(() => _selectedProductId = val),
              ),
            ),
            if (_selectedProductId != null && entries.isEmpty)
              const Expanded(
                child: Center(child: Text('لا توجد مشتريات لهذا المنتج في الفترة المحددة')),
              ),
            if (_selectedProductId != null && entries.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('المورد')),
                      DataColumn(label: Text('إجمالي المشتريات'), numeric: true),
                      DataColumn(label: Text('النسبة'), numeric: true),
                    ],
                    rows: entries.map((entry) {
                      final supplier = entry.key;
                      final amount = entry.value;
                      final percentage = totalPurchases > 0 ? (amount / totalPurchases) * 100 : 0;
                      return DataRow(cells: [
                        DataCell(Text(supplier)),
                        DataCell(Text('${amount.toStringAsFixed(2)}')),
                        DataCell(Text('${percentage.toStringAsFixed(1)}%')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}