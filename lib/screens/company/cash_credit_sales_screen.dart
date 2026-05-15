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

    double totalCash = 0;
    double totalCredit = 0;
    Map<String, double> cashByRegion = {};
    Map<String, double> creditByRegion = {};

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

    final total = totalCash + totalCredit;
    final cashPercent = total > 0 ? (totalCash / total) * 100 : 0;
    final creditPercent = total > 0 ? (totalCredit / total) * 100 : 0;

    final Set<String> allRegions = {...cashByRegion.keys, ...creditByRegion.keys};
    final regionList = allRegions.toList();
    regionList.sort();

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
              child: Row(
                children: [
                  _buildSummaryCard('إجمالي المبيعات', total, Icons.attach_money, Colors.teal, ''),
                  const SizedBox(width: 12),
                  _buildSummaryCard('نقدي', totalCash, Icons.money, Colors.green, '${cashPercent.toStringAsFixed(1)}%'),
                  const SizedBox(width: 12),
                  _buildSummaryCard('آجل', totalCredit, Icons.credit_card, Colors.orange, '${creditPercent.toStringAsFixed(1)}%'),
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
                  ...regionList.map((region) => DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedRegionId = val!),
              ),
            ),
            Expanded(
              child: regionList.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('المحافظة')),
                          DataColumn(label: Text('نقدي'), numeric: true),
                          DataColumn(label: Text('آجل'), numeric: true),
                          DataColumn(label: Text('الإجمالي'), numeric: true),
                          DataColumn(label: Text('% نقدي'), numeric: true),
                        ],
                        rows: regionList.map((region) {
                          final cash = cashByRegion[region] ?? 0;
                          final credit = creditByRegion[region] ?? 0;
                          final regionTotal = cash + credit;
                          final regionCashPercent = regionTotal > 0 ? (cash / regionTotal) * 100 : 0;
                          return DataRow(cells: [
                            DataCell(Text(region)),
                            DataCell(Text('${cash.toStringAsFixed(2)}')),
                            DataCell(Text('${credit.toStringAsFixed(2)}')),
                            DataCell(Text('${regionTotal.toStringAsFixed(2)}')),
                            DataCell(Text('${regionCashPercent.toStringAsFixed(1)}%')),
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

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color, String percentage) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text('${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              if (percentage.isNotEmpty)
                Text(percentage, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}