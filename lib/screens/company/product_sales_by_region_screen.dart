import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/dummy_products.dart';

class ProductSalesByRegionScreen extends StatefulWidget {
  const ProductSalesByRegionScreen({Key? key}) : super(key: key);

  @override
  State<ProductSalesByRegionScreen> createState() => _ProductSalesByRegionScreenState();
}

class _ProductSalesByRegionScreenState extends State<ProductSalesByRegionScreen> {
  String? _selectedProductId;
  List<String> _productNames = [];
  Map<String, String> _productIdToName = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    // تجميع جميع المنتجات من الوكالات التجريبية
    for (var agency in dummyAgencies) {
      for (var product in agency.products) {
        if (!_productIdToName.containsKey(product.id)) {
          _productIdToName[product.id] = product.name;
          _productNames.add(product.name);
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final companyId = Provider.of<AuthService>(context).currentCompanyId ?? 'comp_001';
    final orders = Provider.of<OrderProvider>(context)
        .getOrdersForCompany(companyId);

    Map<String, Map<String, double>> salesByProductRegion = {}; // productName -> region -> total

    for (var order in orders) {
      final region = order.pharmacyCity;
      for (var item in order.items) {
        final productName = item.productName;
        salesByProductRegion.putIfAbsent(productName, () => {});
        salesByProductRegion[productName]![region] = (salesByProductRegion[productName]![region] ?? 0) + item.totalPrice;
      }
    }

    String selectedProductName = '';
    if (_selectedProductId != null && _productIdToName.containsKey(_selectedProductId)) {
      selectedProductName = _productIdToName[_selectedProductId]!;
    }

    Map<String, double> regionSales = {};
    if (selectedProductName.isNotEmpty && salesByProductRegion.containsKey(selectedProductName)) {
      regionSales = salesByProductRegion[selectedProductName]!;
    }

    final entries = regionSales.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('مبيعات صنف حسب المحافظة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
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
                  ? const Center(child: Text('لا توجد مبيعات لهذا المنتج'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('المحافظة')),
                          DataColumn(label: Text('إجمالي المبيعات')),
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
    );
  }
}