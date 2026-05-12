import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/region.dart';

class CashCreditSalesScreen extends StatefulWidget {
  const CashCreditSalesScreen({Key? key}) : super(key: key);

  @override
  State<CashCreditSalesScreen> createState() => _CashCreditSalesScreenState();
}

class _CashCreditSalesScreenState extends State<CashCreditSalesScreen> {
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
          title: const Text('تفصيل المبيعات (نقدي / آجل)'),
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

    double totalCash = 0, totalCredit = 0;
    Map<String, double> cashByRegion = {}, creditByRegion = {};

    for (var order in orders) {
      final region = order.pharmacyCity;
      final amount = order.totalPrice;
      if (order.paymentType == 'cash') {
        totalCash += amount;
        cashByRegion[region] = (cashByRegion[region] ?? 0) + amount;
      } else {
        totalCredit += amount;
        creditByRegion[region] = (creditByRegion[region] ?? 0) + amount;
      }
    }

    double total = totalCash + totalCredit;
    double cashPercent = total == 0 ? 0 : (totalCash / total) * 100;
    double creditPercent = total == 0 ? 0 : (totalCredit / total) * 100;

    // جمع المناطق من البيانات الفعلية
    final Set<String> allRegionNames = {
      ...cashByRegion.keys,
      ...creditByRegion.keys,
    };
    List<String> displayRegions = _selectedRegionId == 'all'
        ? allRegionNames.toList()
        : [_selectedRegionId == 'all' ? 'all' : Region.getNameById(_selectedRegionId)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفصيل المبيعات (نقدي / آجل)'),
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
                value: _selectedRegionId,
                decoration: const InputDecoration(labelText: 'تصفية حسب المحافظة'),
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
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('الإجمالي الكلي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryCard('نقدي', totalCash, cashPercent, Colors.green),
                        _buildSummaryCard('آجل', totalCredit, creditPercent, Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('المحافظة')),
                    DataColumn(label: Text('نقدي')),
                    DataColumn(label: Text('آجل')),
                    DataColumn(label: Text('الإجمالي')),
                  ],
                  rows: displayRegions.map((region) {
                    final cash = cashByRegion[region] ?? 0;
                    final credit = creditByRegion[region] ?? 0;
                    final totalRegion = cash + credit;
                    return DataRow(cells: [
                      DataCell(Text(region)),
                      DataCell(Text('${cash.toStringAsFixed(2)}')),
                      DataCell(Text('${credit.toStringAsFixed(2)}')),
                      DataCell(Text('${totalRegion.toStringAsFixed(2)}')),
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

  Widget _buildSummaryCard(String title, double amount, double percent, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text('${percent.toStringAsFixed(1)}%', style: TextStyle(color: color)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}