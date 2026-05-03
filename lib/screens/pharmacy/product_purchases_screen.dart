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
  List<String> _productNames = [];
  Map<String, String> _productIdToName = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
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
    final pharmacyId = Provider.of<AuthService>(context).currentUserId ?? 'pharmacy_demo_123';
    final orders = Provider.of<OrderProvider>(context)
        .getOrdersForPharmacy(pharmacyId);

    Map<String, Map<String, double>> purchasesByProductSupplier = {}; // productName -> supplier -> total

    for (var order in orders) {
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
    );
  }
}