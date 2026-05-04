import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class CashCreditSalesScreen extends StatefulWidget {
  const CashCreditSalesScreen({Key? key}) : super(key: key);

  @override
  State<CashCreditSalesScreen> createState() => _CashCreditSalesScreenState();
}

class _CashCreditSalesScreenState extends State<CashCreditSalesScreen> {
  String _selectedRegion = 'all';
  List<String> regions = [];
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  void _loadRegions() {
    final orders = Provider.of<OrderProvider>(context, listen: false)
        .getOrdersForCompany(Provider.of<AuthService>(context, listen: false).currentCompanyId ?? 'comp_001');
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
    final companyId = Provider.of<AuthService>(context).currentCompanyId ?? 'comp_001';
    List<OrderModel> orders = Provider.of<OrderProvider>(context)
        .getOrdersForCompany(companyId);

    if (_dateRange != null) {
      orders = orders.where((o) =>
          o.date.isAfter(_dateRange!.start) &&
          o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
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

    List<String> displayRegions = _selectedRegion == 'all'
        ? [...cashByRegion.keys.toSet(), ...creditByRegion.keys.toSet()].toSet().toList()
        : [_selectedRegion];

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
                  TextButton(
                    onPressed: () => setState(() => _dateRange = null),
                    child: const Text('إلغاء التصفية'),
                  ),
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