import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class PurchasesBySupplierScreen extends StatefulWidget {
  const PurchasesBySupplierScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesBySupplierScreen> createState() => _PurchasesBySupplierScreenState();
}

class _PurchasesBySupplierScreenState extends State<PurchasesBySupplierScreen> {
  String _selectedSupplier = 'all';
  List<String> suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  void _loadSuppliers() {
    final pharmacyId = Provider.of<AuthService>(context, listen: false).currentUserId ?? 'pharmacy_demo_123';
    final orders = Provider.of<OrderProvider>(context, listen: false)
        .getOrdersForPharmacy(pharmacyId);
    suppliers = ['all', ...orders.map((o) => o.companyName).toSet().toList()];
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyId = Provider.of<AuthService>(context).currentUserId ?? 'pharmacy_demo_123';
    final orders = Provider.of<OrderProvider>(context)
        .getOrdersForPharmacy(pharmacyId);

    Map<String, double> purchasesBySupplier = {};
    Map<String, Map<String, double>> cashCreditBySupplier = {};

    for (var order in orders) {
      final supplier = order.companyName;
      final amount = order.totalPrice;
      purchasesBySupplier[supplier] = (purchasesBySupplier[supplier] ?? 0) + amount;

      cashCreditBySupplier.putIfAbsent(supplier, () => {'cash': 0.0, 'credit': 0.0});
      if (order.paymentType == 'cash') {
        cashCreditBySupplier[supplier]!['cash'] = (cashCreditBySupplier[supplier]!['cash'] ?? 0) + amount;
      } else {
        cashCreditBySupplier[supplier]!['credit'] = (cashCreditBySupplier[supplier]!['credit'] ?? 0) + amount;
      }
    }

    List<MapEntry<String, double>> entries = purchasesBySupplier.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    if (_selectedSupplier != 'all') {
      entries = entries.where((e) => e.key == _selectedSupplier).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشتريات حسب المورد'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedSupplier,
              decoration: const InputDecoration(labelText: 'تصفية حسب المورد'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('جميع الموردين')),
                ...suppliers.where((s) => s != 'all').map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (val) => setState(() => _selectedSupplier = val!),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('لا توجد مشتريات'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('المورد')),
                        DataColumn(label: Text('إجمالي المشتريات')),
                        DataColumn(label: Text('نقدي')),
                        DataColumn(label: Text('آجل')),
                      ],
                      rows: entries.map((entry) {
                        final supplier = entry.key;
                        final total = entry.value;
                        final cash = cashCreditBySupplier[supplier]?['cash'] ?? 0;
                        final credit = cashCreditBySupplier[supplier]?['credit'] ?? 0;
                        return DataRow(cells: [
                          DataCell(Text(supplier)),
                          DataCell(Text('${total.toStringAsFixed(2)}')),
                          DataCell(Text('${cash.toStringAsFixed(2)}')),
                          DataCell(Text('${credit.toStringAsFixed(2)}')),
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