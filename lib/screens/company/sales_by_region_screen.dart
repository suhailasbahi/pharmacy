import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class SalesByRegionScreen extends StatefulWidget {
  const SalesByRegionScreen({Key? key}) : super(key: key);

  @override
  State<SalesByRegionScreen> createState() => _SalesByRegionScreenState();
}

class _SalesByRegionScreenState extends State<SalesByRegionScreen> {
  String _selectedRegion = 'all';
  List<String> regions = [];
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  void _loadRegions() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final orders = Provider.of<OrderProvider>(context, listen: false)
        .getOrdersForCompany(auth.currentCompanyId ?? 'comp_001', branchId: auth.getEffectiveBranchId());
    regions = ['all', ...orders.map((o) => o.pharmacyCity).toSet().toList()];
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final companyId = auth.currentCompanyId ?? 'comp_001';
    List<OrderModel> filteredOrders = Provider.of<OrderProvider>(context)
        .getOrdersForCompany(companyId, branchId: auth.getEffectiveBranchId());

    if (_dateRange != null) {
      filteredOrders = filteredOrders.where((order) =>
          order.date.isAfter(_dateRange!.start) &&
          order.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    Map<String, double> salesByRegion = {};
    Map<String, Map<String, double>> cashCreditByRegion = {};

    for (var order in filteredOrders) {
      final region = order.pharmacyCity;
      final amount = order.totalPrice;
      salesByRegion[region] = (salesByRegion[region] ?? 0) + amount;
      cashCreditByRegion.putIfAbsent(region, () => {'cash': 0.0, 'credit': 0.0});
      if (order.paymentType == 'cash') {
        cashCreditByRegion[region]!['cash'] = (cashCreditByRegion[region]!['cash'] ?? 0) + amount;
      } else {
        cashCreditByRegion[region]!['credit'] = (cashCreditByRegion[region]!['credit'] ?? 0) + amount;
      }
    }

    List<MapEntry<String, double>> entries = salesByRegion.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    if (_selectedRegion != 'all') {
      entries = entries.where((e) => e.key == _selectedRegion).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات حسب المحافظة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [IconButton(icon: const Icon(Icons.date_range), onPressed: _selectDateRange)],
      ),
      body: Column(
        children: [
          if (_dateRange != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('من ${_formatDate(_dateRange!.start)} إلى ${_formatDate(_dateRange!.end)}'),
                  TextButton(onPressed: () => setState(() => _dateRange = null), child: const Text('إلغاء التصفية')),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(labelText: 'تصفية حسب المحافظة'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('جميع المحافظات')),
                ...regions.where((r) => r != 'all').map((r) => DropdownMenuItem(value: r, child: Text(r))),
              ],
              onChanged: (val) => setState(() => _selectedRegion = val!),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('لا توجد مبيعات'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('المحافظة')),
                        DataColumn(label: Text('إجمالي المبيعات')),
                        DataColumn(label: Text('نقدي')),
                        DataColumn(label: Text('آجل')),
                      ],
                      rows: entries.map((entry) {
                        final region = entry.key;
                        final total = entry.value;
                        final cash = cashCreditByRegion[region]?['cash'] ?? 0;
                        final credit = cashCreditByRegion[region]?['credit'] ?? 0;
                        return DataRow(cells: [
                          DataCell(Text(region)),
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

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}