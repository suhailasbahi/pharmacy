import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/region.dart';

class ProductSalesByRegionScreen extends StatefulWidget {
  const ProductSalesByRegionScreen({Key? key}) : super(key: key);

  @override
  State<ProductSalesByRegionScreen> createState() => _ProductSalesByRegionScreenState();
}

class _ProductSalesByRegionScreenState extends State<ProductSalesByRegionScreen> {
  String? _selectedProductId;
  Map<String, String> _productIdToName = {};
  DateTimeRange? _dateRange;
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;

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
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId;
    if (companyId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    List<OrderModel> orders = await orderProvider.getOrdersForCompany(companyId);
    
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
          title: const Text('مبيعات صنف حسب المحافظة'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // تجميع البيانات للمنتج المختار
    Map<String, double> salesByRegion = {};
    
    if (_selectedProductId != null) {
      for (var order in _allOrders) {
        for (var item in order.items) {
          if (item.productId == _selectedProductId) {
            final region = order.pharmacyCity;
            salesByRegion[region] = (salesByRegion[region] ?? 0) + item.totalPrice;
          }
        }
      }
    }

    final entries = salesByRegion.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مبيعات صنف حسب المحافظة'),
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
              child: DropdownButtonFormField<String>(
                hint: const Text('اختر المنتج'),
                value: _selectedProductId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('-- اختر منتجاً --')),
                  ..._productIdToName.entries.map((entry) {
                    return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                  }),
                ],
                onChanged: (val) => setState(() => _selectedProductId = val),
              ),
            ),
            if (_selectedProductId != null && entries.isEmpty)
              const Expanded(
                child: Center(child: Text('لا توجد مبيعات لهذا المنتج في الفترة المحددة')),
              ),
            if (_selectedProductId != null && entries.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('المحافظة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('إجمالي المبيعات')),
                      DataColumn(label: Text('النسبة المئوية')),
                    ],
                    rows: entries.map((entry) {
                      final region = entry.key;
                      final amount = entry.value;
                      final percentage = total > 0 ? (amount / total) * 100 : 0;
                      return DataRow(cells: [
                        DataCell(Text(region)),
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