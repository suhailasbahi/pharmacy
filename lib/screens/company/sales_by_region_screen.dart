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
    
    // استخراج المناطق من الطلبات الفعلية
    final Set<String> regionNames = {};
    for (var order in orders) {
      if (order.pharmacyCity.isNotEmpty) {
        regionNames.add(order.pharmacyCity);
      }
    }
    
    final List<Region> allRegions = Region.allRegions;
    final List<Region> regionsList = [];
    for (var name in regionNames) {
      final matched = allRegions.firstWhere(
        (r) => r.name == name,
        orElse: () => Region('other', name),
      );
      regionsList.add(matched);
    }
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
          title: const Text('المبيعات حسب المحافظة'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<OrderModel> filteredOrders = List.from(_allOrders);
    
    if (_selectedRegionId != 'all') {
      try {
        final regionName = Region.getNameById(_selectedRegionId);
        filteredOrders = filteredOrders.where((o) => o.pharmacyCity == regionName).toList();
      } catch (e) {
        print('Error filtering by region: $e');
      }
    }

    // تجميع البيانات
    Map<String, double> salesByCity = {};
    Map<String, double> cashByCity = {};
    Map<String, double> creditByCity = {};

    for (var order in filteredOrders) {
      final city = order.pharmacyCity;
      final amount = order.totalPrice;
      salesByCity[city] = (salesByCity[city] ?? 0) + amount;
      if (order.paymentType == 'cash') {
        cashByCity[city] = (cashByCity[city] ?? 0) + amount;
      } else {
        creditByCity[city] = (creditByCity[city] ?? 0) + amount;
      }
    }

    final entries = salesByCity.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    // حساب الإجماليات
    final totalSales = filteredOrders.fold(0.0, (s, o) => s + o.totalPrice);
    final totalCash = cashByCity.values.fold(0.0, (s, v) => s + v);
    final totalCredit = creditByCity.values.fold(0.0, (s, v) => s + v);

    if (filteredOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('المبيعات حسب المحافظة'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: Text('لا توجد مبيعات في هذه الفترة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات حسب المحافظة'),
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
              child: Row(
                children: [
                  _buildSummaryCard('إجمالي المبيعات', totalSales, Colors.teal),
                  const SizedBox(width: 12),
                  _buildSummaryCard('نقدي', totalCash, Colors.green),
                  const SizedBox(width: 12),
                  _buildSummaryCard('آجل', totalCredit, Colors.orange),
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
                onChanged: (val) async {
                  setState(() {
                    _selectedRegionId = val!;
                  });
                  await _loadData();
                },
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('لا توجد مبيعات'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('المحافظة')),
                          DataColumn(label: Text('إجمالي المبيعات'), numeric: true),
                          DataColumn(label: Text('نقدي'), numeric: true),
                          DataColumn(label: Text('آجل'), numeric: true),
                          DataColumn(label: Text('النسبة المئوية'), numeric: true),
                        ],
                        rows: entries.map((entry) {
                          final city = entry.key;
                          final total = entry.value;
                          final cash = cashByCity[city] ?? 0;
                          final credit = creditByCity[city] ?? 0;
                          final percentage = totalSales > 0 ? (total / totalSales) * 100 : 0;
                          return DataRow(cells: [
                            DataCell(Text(city)),
                            DataCell(Text('${total.toStringAsFixed(2)}')),
                            DataCell(Text('${cash.toStringAsFixed(2)}')),
                            DataCell(Text('${credit.toStringAsFixed(2)}')),
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

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}