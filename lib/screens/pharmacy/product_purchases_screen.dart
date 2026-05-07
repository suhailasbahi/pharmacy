import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/dummy_products.dart';

class ProductPurchasesScreen extends StatefulWidget {
  const ProductPurchasesScreen({Key? key}) : super(key: key);

  @override
  State<ProductPurchasesScreen> createState() => _ProductPurchasesScreenState();
}

class _ProductPurchasesScreenState extends State<ProductPurchasesScreen> {
  String? _selectedProductId;
  Map<String, String> _productIdToName = {};
  DateTimeRange? _dateRange;
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadData();
  }

  void _loadProducts() {
    for (var agency in dummyAgencies) {
      for (var product in agency.products) {
        if (!_productIdToName.containsKey(product.id)) {
          _productIdToName[product.id] = product.name;
        }
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final pharmacyId = auth.currentUserId ?? 'pharmacy_demo_123';
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    List<OrderModel> orders = await orderProvider.getOrdersForPharmacy(pharmacyId);
    if (_dateRange != null) {
      orders = orders.where((o) =>
          o.date.isAfter(_dateRange!.start) &&
          o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
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
        appBar: AppBar(title: const Text('مشتريات صنف حسب المورد'), centerTitle: true, backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, Map<String, double>> purchasesByProductSupplier = {};

    for (var order in _orders) {
      final supplier = order.companyName;
      for (var item in order.items) {
        final productName = item.productName;
        purchasesByProductSupplier.putIfAbsent(productName, () => {});
        purchasesByProductSupplier[productName]![supplier] = (purchasesByProductSupplier[productName]![supplier] ?? 0) + item.totalPrice;
      }
    }

    String selectedProductName = '';
    if (_selectedProductId != null && _productIdToName.containsKey(_selectedProductId)) {
      selectedProductName = _productIdToName[_selectedProductId]!;
    }

    Map<String, double> supplierPurchases = {};
    if (selectedProductName.isNotEmpty && purchasesByProductSupplier.containsKey(selectedProductName)) {
      supplierPurchases = purchasesByProductSupplier[selectedProductName]!;
    }
    final entries = supplierPurchases.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشتريات صنف حسب المورد'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _selectDateRange, tooltip: 'تحديد فترة'),
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
                items: _productIdToName.entries.map((entry) {
                  return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                }).toList(),
                onChanged: (val) => setState(() => _selectedProductId = val),
              ),
            ),
            if (selectedProductName.isNotEmpty)
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('لا توجد مشتريات لهذا المنتج'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('المورد')),
                            DataColumn(label: Text('إجمالي المشتريات')),
                          ],
                          rows: entries.map((entry) {
                            return DataRow(cells: [
                              DataCell(Text(entry.key)),
                              DataCell(Text('${entry.value.toStringAsFixed(2)}')),
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