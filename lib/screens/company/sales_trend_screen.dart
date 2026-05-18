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

class _SalesTrendScreenState extends State<SalesTrendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange? _dateRange;

  List<OrderModel> _allOrders = [];

  bool _isLoading = true;

  String _trendType = 'daily'; // daily, monthly

  // =========================================
  // KPI
  // =========================================
  double _totalSales = 0;
  double _avgOrderValue = 0;
  int _totalOrders = 0;
  double _cashSales = 0;
  double _creditSales = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================================
  // تحميل البيانات
  // =========================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final companyId = auth.currentCompanyId;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      List<OrderModel> orders = await orderProvider.getOrdersForCompany(companyId);

      // الطلبات المكتملة فقط
      orders = orders.where((o) =>
          o.status == 'accepted' ||
          o.status == 'shipped' ||
          o.status == 'delivered').toList();

      // فلترة التاريخ
      if (_dateRange != null) {
        orders = orders.where((o) =>
            o.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
      }

      // حساب الإحصائيات
      double totalSales = 0;
      double cashSales = 0;
      double creditSales = 0;

      for (var order in orders) {
        totalSales += order.totalPrice;
        if (order.paymentType == 'cash') {
          cashSales += order.totalPrice;
        } else {
          creditSales += order.totalPrice;
        }
      }

      setState(() {
        _allOrders = orders;
        _totalSales = totalSales;
        _totalOrders = orders.length;
        _avgOrderValue = _totalOrders > 0 ? totalSales / _totalOrders : 0;
        _cashSales = cashSales;
        _creditSales = creditSales;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SalesTrendScreen Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      await _loadData();
    }
  }

  // =========================================
  // بيانات الرسم البياني
  // =========================================
  Map<DateTime, double> get _dailySales {
    final map = <DateTime, double>{};
    for (var order in _allOrders) {
      final date = DateTime(order.date.year, order.date.month, order.date.day);
      map[date] = (map[date] ?? 0) + order.totalPrice;
    }
    return map;
  }

  Map<String, double> get _monthlySales {
    final map = <String, double>{};
    for (var order in _allOrders) {
      final key = '${order.date.year}-${order.date.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + order.totalPrice;
    }
    return map;
  }

  List<FlSpot> get _chartSpots {
    if (_trendType == 'daily') {
      final sales = _dailySales;
      final dates = sales.keys.toList()..sort();
      return List.generate(dates.length, (i) => FlSpot(i.toDouble(), sales[dates[i]] ?? 0));
    } else {
      final sales = _monthlySales;
      final keys = sales.keys.toList()..sort();
      return List.generate(keys.length, (i) => FlSpot(i.toDouble(), sales[keys[i]] ?? 0));
    }
  }

  double get _maxY {
    if (_chartSpots.isEmpty) return 100;
    return _chartSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;
  }

  List<String> get _xLabels {
    if (_trendType == 'daily') {
      final dates = _dailySales.keys.toList()..sort();
      return dates.map((d) => '${d.day}/${d.month}').toList();
    } else {
      final keys = _monthlySales.keys.toList()..sort();
      return keys.map((k) {
        final parts = k.split('-');
        return '${parts[1]}/${parts[0]}';
      }).toList();
    }
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

    final spots = _chartSpots;
    final xLabels = _xLabels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه المبيعات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'تحديد فترة',
            onPressed: _selectDateRange,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'الرسم البياني'),
            Tab(icon: Icon(Icons.table_chart), text: 'الجدول'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // =========================================
            // شريط التاريخ
            // =========================================
            if (_dateRange != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'من ${_formatDate(_dateRange!.start)} إلى ${_formatDate(_dateRange!.end)}',
                      ),
                    ),
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

            // =========================================
            // KPI Cards
            // =========================================
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildKpiCard(
                        title: 'إجمالي المبيعات',
                        value: _totalSales.toStringAsFixed(2),
                        color: Colors.teal,
                        icon: Icons.attach_money,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'عدد الطلبات',
                        value: _totalOrders.toString(),
                        color: Colors.blue,
                        icon: Icons.receipt_long,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'متوسط الطلب',
                        value: _avgOrderValue.toStringAsFixed(2),
                        color: Colors.orange,
                        icon: Icons.calculate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildKpiCard(
                        title: 'المبيعات النقدية',
                        value: _cashSales.toStringAsFixed(2),
                        color: Colors.green,
                        icon: Icons.money,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'المبيعات الآجلة',
                        value: _creditSales.toStringAsFixed(2),
                        color: Colors.deepOrange,
                        icon: Icons.credit_card,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'نسبة نقدي',
                        value: _totalSales > 0
                            ? '${((_cashSales / _totalSales) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        color: Colors.purple,
                        icon: Icons.pie_chart,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =========================================
            // خيار العرض (يومي / شهري)
            // =========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text('عرض:'),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'daily', label: Text('يومي')),
                      ButtonSegment(value: 'monthly', label: Text('شهري')),
                    ],
                    selected: {_trendType},
                    onSelectionChanged: (set) {
                      setState(() => _trendType = set.first);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // TabBar View
            // =========================================
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // تبويب الرسم البياني
                  spots.isEmpty
                      ? const Center(child: Text('لا توجد بيانات'))
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'الرسم البياني',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 && index < xLabels.length) {
                                              return Text(xLabels[index], style: const TextStyle(fontSize: 10));
                                            }
                                            return const Text('');
                                          },
                                          reservedSize: 40,
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 50),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        color: Colors.teal,
                                        barWidth: 3,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.teal.withOpacity(0.2),
                                        ),
                                      ),
                                    ],
                                    minY: 0,
                                    maxY: _maxY,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  // تبويب الجدول
                  _buildTableView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // عرض الجدول
  // =========================================
  Widget _buildTableView() {
    if (_trendType == 'daily') {
      final dailySales = _dailySales;
      final dates = dailySales.keys.toList()..sort((a, b) => b.compareTo(a));

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final amount = dailySales[date] ?? 0;
          final percentage = _totalSales > 0 ? (amount / _totalSales) * 100 : 0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text('${date.day}/${date.month}/${date.year}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amount.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    alignment: Alignment.centerRight,
                    child: Text('${percentage.toStringAsFixed(1)}%'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      final monthlySales = _monthlySales;
      final keys = monthlySales.keys.toList()..sort((a, b) => b.compareTo(a));

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final amount = monthlySales[key] ?? 0;
          final percentage = _totalSales > 0 ? (amount / _totalSales) * 100 : 0;
          final parts = key.split('-');
          final monthName = _getMonthName(int.parse(parts[1]));

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text('$monthName ${parts[0]}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amount.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    alignment: Alignment.centerRight,
                    child: Text('${percentage.toStringAsFixed(1)}%'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // =========================================
  // اسم الشهر
  // =========================================
  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  // =========================================
  // KPI Card
  // =========================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}