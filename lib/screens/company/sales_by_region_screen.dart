import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/region.dart';

class SalesByRegionScreen extends StatefulWidget {
  const SalesByRegionScreen({Key? key}) : super(key: key);

  @override
  State<SalesByRegionScreen> createState() => _SalesByRegionScreenState();
}

class _SalesByRegionScreenState extends State<SalesByRegionScreen> {
  String _selectedRegionId = 'all';
  DateTimeRange? _dateRange;
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  List<Region> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId ?? 'comp_001';
    final branchId = auth.getEffectiveBranchId();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    List<OrderModel> orders = await orderProvider.getOrdersForCompany(companyId, branchId: branchId);
    if (_dateRange != null) {
      orders = orders.where((o) =>
          o.date.isAfter(_dateRange!.start) &&
          o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }
    final Set<String> regionIds = {};
    final List<Region> allRegions = Region.allRegions;
    for (var order in orders) {
      final city = order.pharmacyCity;
      // محاولة مطابقة اسم المدينة مع معرف المنطقة
      final matchedRegion = allRegions.firstWhere(
        (r) => r.name == city,
        orElse: () => const Region('other', 'أخرى'),
      );
      if (matchedRegion.id != 'other') {
        regionIds.add(matchedRegion.id);
      }
    }
    final regionsList = regionIds.map((id) => allRegions.firstWhere((r) => r.id == id)).toList();
    regionsList.sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      _allOrders = orders;
      _regions = regionsList;
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
        appBar: AppBar(
          title: const Text('المبيعات حسب المحافظة'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<OrderModel> orders = _allOrders;
    if (_selectedRegionId != 'all') {
      final regionName = Region.getNameById(_selectedRegionId);
      orders = orders.where((o) => o.pharmacyCity == regionName).toList();
    }

    Map<String, double> salesByRegion = {};
    Map<String, Map<String, double>> cashCreditByRegion = {};

    for (var order in orders) {
      final city = order.pharmacyCity;
      final amount = order.totalPrice;
      salesByRegion[city] = (salesByRegion[city] ?? 0) + amount;
      cashCreditByRegion.putIfAbsent(city, () => {'cash': 0.0, 'credit': 0.0});
      if (order.paymentType == 'cash') {
        cashCreditByRegion[city]!['cash'] = (cashCreditByRegion[city]!['cash'] ?? 0) + amount;
      } else {
        cashCreditByRegion[city]!['credit'] = (cashCreditByRegion[city]!['credit'] ?? 0) + amount;
      }
    }

    final entries = salesByRegion.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات حسب المحافظة'),
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
                value: _selectedRegionId,
                decoration: const InputDecoration(labelText: 'اختر المحافظة'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('جميع المحافظات')),
                  ..._regions.map((region) => DropdownMenuItem(
                        value: region.id,
                        child: Text(region.name),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedRegionId = val!),
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
                          final city = entry.key;
                          final total = entry.value;
                          final cash = cashCreditByRegion[city]?['cash'] ?? 0;
                          final credit = cashCreditByRegion[city]?['credit'] ?? 0;
                          return DataRow(cells: [
                            DataCell(Text(city)),
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
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}