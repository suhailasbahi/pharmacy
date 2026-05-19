import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends State<PerformanceDashboardScreen> {
  bool _isLoading = true;

  List<OrderModel> _orders = [];

  DateTimeRange? _dateRange;

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

    final provider = Provider.of<OrderProvider>(context, listen: false);

    List<OrderModel> orders =
        await provider.getOrdersForCompany(companyId);

    // فقط الطلبات المكتملة والمقبولة
    orders = orders.where((o) =>
    o.status == 'accepted' ||
        o.status == 'delivered' ||
        o.status == 'shipped').toList();

    if (_dateRange != null) {
      orders = orders.where((o) =>
      o.date.isAfter(_dateRange!.start) &&
          o.date.isBefore(
              _dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    orders.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _orders = orders;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الأداء'),
          backgroundColor: Colors.teal,
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalSales =
    _orders.fold(0.0, (sum, order) => sum + order.totalPrice);

    final totalOrders = _orders.length;

    final avgOrder =
    totalOrders == 0 ? 0 : totalSales / totalOrders;

    // =========================
    // النقدي والآجل
    // =========================

    double cashSales = 0;
    double creditSales = 0;

    for (var order in _orders) {
      if (order.paymentType == 'cash') {
        cashSales += order.totalPrice;
      } else {
        creditSales += order.totalPrice;
      }
    }

    // =========================
    // أعلى مدينة
    // =========================

    Map<String, double> citySales = {};

    for (var order in _orders) {
      citySales[order.pharmacyCity] =
          (citySales[order.pharmacyCity] ?? 0) +
              order.totalPrice;
    }

    String topCity = '-';
    double topCityAmount = 0;

    citySales.forEach((city, amount) {
      if (amount > topCityAmount) {
        topCity = city;
        topCityAmount = amount;
      }
    });

    // =========================
    // أعلى عميل
    // =========================

    Map<String, double> customerSales = {};

    for (var order in _orders) {
      customerSales[order.pharmacyName] =
          (customerSales[order.pharmacyName] ?? 0) +
              order.totalPrice;
    }

    String topCustomer = '-';
    double topCustomerAmount = 0;

    customerSales.forEach((customer, amount) {
      if (amount > topCustomerAmount) {
        topCustomer = customer;
        topCustomerAmount = amount;
      }
    });

    // =========================
    // أكثر يوم نشاط
    // =========================

    Map<String, int> dailyOrders = {};

    for (var order in _orders) {
      final key =
          '${order.date.day}/${order.date.month}';

      dailyOrders[key] =
          (dailyOrders[key] ?? 0) + 1;
    }

    String busiestDay = '-';
    int busiestCount = 0;

    dailyOrders.forEach((day, count) {
      if (count > busiestCount) {
        busiestDay = day;
        busiestCount = count;
      }
    });

    // =========================
    // متوسط المنتجات لكل طلب
    // =========================

    int totalItems = 0;

    for (var order in _orders) {
      totalItems += order.items.length;
    }

    final avgItems =
    totalOrders == 0 ? 0 : totalItems / totalOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأداء'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [

            // =====================
            // الفلترة
            // =====================

            if (_dateRange != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDate(_dateRange!.start)}'
                            ' - '
                            '${_formatDate(_dateRange!.end)}',
                      ),

                      TextButton(
                        onPressed: () async {
                          setState(() => _dateRange = null);
                          await _loadData();
                        },
                        child: const Text('إلغاء'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // =====================
            // KPI
            // =====================

            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,

              children: [

                _buildKpiCard(
                  title: 'إجمالي المبيعات',
                  value:
                  totalSales.toStringAsFixed(2),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),

                _buildKpiCard(
                  title: 'إجمالي الطلبات',
                  value: totalOrders.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.teal,
                ),

                _buildKpiCard(
                  title: 'متوسط الطلب',
                  value:
                  avgOrder.toStringAsFixed(2),
                  icon: Icons.analytics,
                  color: Colors.orange,
                ),

                _buildKpiCard(
                  title: 'متوسط المنتجات',
                  value:
                  avgItems.toStringAsFixed(1),
                  icon: Icons.medication,
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =====================
            // بطاقات التحليل
            // =====================

            _buildInsightCard(
              title: 'أفضل مدينة',
              subtitle:
              '$topCity (${topCityAmount.toStringAsFixed(2)})',
              icon: Icons.location_city,
              color: Colors.purple,
            ),

            _buildInsightCard(
              title: 'أفضل عميل',
              subtitle:
              '$topCustomer (${topCustomerAmount.toStringAsFixed(2)})',
              icon: Icons.person,
              color: Colors.indigo,
            ),

            _buildInsightCard(
              title: 'أكثر يوم نشاط',
              subtitle:
              '$busiestDay ($busiestCount طلب)',
              icon: Icons.calendar_today,
              color: Colors.deepOrange,
            ),

            const SizedBox(height: 20),

            // =====================
            // النقدي والآجل
            // =====================

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'تحليل طرق الدفع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildPaymentRow(
                      title: 'نقدي',
                      value: cashSales,
                      total: totalSales,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 14),

                    _buildPaymentRow(
                      title: 'آجل',
                      value: creditSales,
                      total: totalSales,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),

            const SizedBox(height: 14),

            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),

        title: Text(title),

        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildPaymentRow({
    required String title,
    required double value,
    required double total,
    required Color color,
  }) {
    final percent =
    total == 0 ? 0 : (value / total) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

          children: [
            Text(title),

            Text(
              '${value.toStringAsFixed(2)}'
                  ' (${percent.toStringAsFixed(1)}%)',
            ),
          ],
        ),

        const SizedBox(height: 8),

        LinearProgressIndicator(
          value: total == 0 ? 0 : value / total,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          color: color,
          backgroundColor: color.withOpacity(0.15),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}