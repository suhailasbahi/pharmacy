import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class SalesTrendScreen extends StatefulWidget {
  const SalesTrendScreen({Key? key}) : super(key: key);

  @override
  State<SalesTrendScreen> createState() => _SalesTrendScreenState();
}

class _SalesTrendScreenState extends State<SalesTrendScreen> {
  DateTimeRange? _dateRange;
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String _groupBy = 'day'; // 'day', 'month'

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
          o.date.isBefore(_dateRange!.end.add(const Duration(days:1)))).toList();
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

  Map<DateTime, double> _getDailySales() {
    Map<DateTime, double> dailySales = {};
    for (var order in _allOrders) {
      final date = DateTime(order.date.year, order.date.month, order.date.day);
      dailySales[date] = (dailySales[date] ?? 0) + order.totalPrice;
    }
    return dailySales;
  }

  Map<String, double> _getMonthlySales() {
    Map<String, double> monthlySales = {};
    for (var order in _allOrders) {
      final key = '${order.date.year}-${order.date.month.toString().padLeft(2, '0')}';
      monthlySales[key] = (monthlySales[key] ?? 0) + order.totalPrice;
    }
    return monthlySales;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('اتجاه المبيعات'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_allOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('اتجاه المبيعات'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: Text('لا توجد بيانات للفترة المحددة')),
      );
    }

    Map<DateTime, double> dailySales = {};
    Map<String, double> monthlySales = {};
    List<FlSpot> spots = [];

    if (_groupBy == 'day') {
      dailySales = _getDailySales();
      final sortedDates = dailySales.keys.toList()..sort();
      for (int i = 0; i < sortedDates.length; i++) {
        spots.add(FlSpot(i.toDouble(), dailySales[sortedDates[i]] ?? 0));
      }
    } else {
      monthlySales = _getMonthlySales();
      final sortedKeys = monthlySales.keys.toList()..sort();
      for (int i = 0; i < sortedKeys.length; i++) {
        spots.add(FlSpot(i.toDouble(), monthlySales[sortedKeys[i]] ?? 0));
      }
    }

    final maxY = spots.isEmpty ? 100 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final totalSales = _allOrders.fold(0.0, (s, o) => s + o.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه المبيعات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'تحديد فترة',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_week),
            onSelected: (value) => setState(() => _groupBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'day', child: Text('يومي')),
              const PopupMenuItem(value: 'month', child: Text('شهري')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('إجمالي المبيعات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${totalSales.toStringAsFixed(2)} جنيه', 
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('الرسم البياني', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Colors.teal,
                                barWidth: 3,
                                belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.2)),
                              ),
                            ],
                            minY: 0,
                            maxY: maxY * 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}