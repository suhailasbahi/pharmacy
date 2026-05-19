import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class CompanyDetailedScreen extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String? branchId;

  const CompanyDetailedScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
    this.branchId,
  }) : super(key: key);

  @override
  State<CompanyDetailedScreen> createState() =>
      _CompanyDetailedScreenState();
}

class _CompanyDetailedScreenState
    extends State<CompanyDetailedScreen> {
  bool isLoading = true;

  List<OrderModel> orders = [];

  double totalSales = 0;
  int totalOrders = 0;

  double cashSales = 0;
  double creditSales = 0;

  int cashOrders = 0;
  int creditOrders = 0;

  double deliveredSales = 0;
  double pendingSales = 0;

  Map<String, double> pharmacySales = {};
  Map<String, int> productQuantity = {};
  Map<String, double> monthlySales = {};
  Map<String, int> statusCounts = {};
  Map<String, double> regionSales = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final provider =
        Provider.of<OrderProvider>(context, listen: false);

    final data = await provider.getOrdersForCompany(
      widget.companyId,
      branchId: widget.branchId,
    );

    orders = data;

    totalOrders = orders.length;

    for (var order in orders) {
      totalSales += order.totalPrice;

      // =========================
      // Payment Analytics
      // =========================
      if (order.paymentType == 'cash') {
        cashSales += order.totalPrice;
        cashOrders++;
      } else {
        creditSales += order.totalPrice;
        creditOrders++;
      }

      // =========================
      // Status Analytics
      // =========================
      statusCounts[order.status] =
          (statusCounts[order.status] ?? 0) + 1;

      if (order.status == 'delivered') {
        deliveredSales += order.totalPrice;
      }

      if (order.status == 'pending') {
        pendingSales += order.totalPrice;
      }

      // =========================
      // Pharmacy Analytics
      // =========================
      pharmacySales[order.pharmacyName] =
          (pharmacySales[order.pharmacyName] ?? 0) +
              order.totalPrice;

      // =========================
      // Region Analytics
      // =========================
      regionSales[order.pharmacyCity] =
          (regionSales[order.pharmacyCity] ?? 0) +
              order.totalPrice;

      // =========================
      // Monthly Analytics
      // =========================
      final month =
          '${order.date.year}-${order.date.month.toString().padLeft(2, '0')}';

      monthlySales[month] =
          (monthlySales[month] ?? 0) +
              order.totalPrice;

      // =========================
      // Product Analytics
      // =========================
      for (var item in order.items) {
        productQuantity[item.productName] =
            (productQuantity[item.productName] ?? 0) +
                item.quantity;
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildTopProducts() {
    final sorted = productQuantity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.take(7).map((e) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.medication),
            title: Text(e.key),
            trailing: Text('${e.value}'),
          ),
        );
      }).toList(),
    );
  }

  Widget buildTopPharmacies() {
    final sorted = pharmacySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.take(7).map((e) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.local_pharmacy),
            title: Text(e.key),
            trailing: Text(
              e.value.toStringAsFixed(0),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildRecentOrders() {
    return Column(
      children: orders.take(10).map((order) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  order.statusColor.withOpacity(0.15),
              child: Icon(
                Icons.receipt_long,
                color: order.statusColor,
              ),
            ),
            title: Text(order.pharmacyName),
            subtitle: Text(order.statusText),
            trailing: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  order.totalPrice
                      .toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.paymentTypeText,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildMonthlyChart() {
    final entries = monthlySales.entries.toList();

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: List.generate(entries.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  entries[index].value,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentChart() {
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: cashSales,
              title: 'نقدي',
            ),
            PieChartSectionData(
              value: creditSales,
              title: 'آجل',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusChart() {
    final entries = statusCounts.entries.toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].value.toDouble(),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget buildRegionChart() {
    final entries = regionSales.entries.toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].value,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final averageOrder =
        totalOrders == 0
            ? 0
            : totalSales / totalOrders;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  // =========================
                  // Main KPIs
                  // =========================
                  Row(
                    children: [
                      buildStatCard(
                        'إجمالي المبيعات',
                        totalSales.toStringAsFixed(0),
                        Icons.attach_money,
                        Colors.green,
                      ),
                      buildStatCard(
                        'عدد الطلبات',
                        totalOrders.toString(),
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      buildStatCard(
                        'المبيعات النقدية',
                        cashSales.toStringAsFixed(0),
                        Icons.payments,
                        Colors.orange,
                      ),
                      buildStatCard(
                        'المبيعات الآجلة',
                        creditSales.toStringAsFixed(0),
                        Icons.account_balance_wallet,
                        Colors.purple,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      buildStatCard(
                        'متوسط الطلب',
                        averageOrder.toStringAsFixed(0),
                        Icons.analytics,
                        Colors.teal,
                      ),
                      buildStatCard(
                        'تم التسليم',
                        deliveredSales.toStringAsFixed(0),
                        Icons.local_shipping,
                        Colors.indigo,
                      ),
                    ],
                  ),

                  // =========================
                  // Monthly Trend
                  // =========================
                  sectionTitle('اتجاه المبيعات الشهري'),
                  buildMonthlyChart(),

                  // =========================
                  // Payment Analytics
                  // =========================
                  sectionTitle('تحليل المبيعات'),
                  buildPaymentChart(),

                  // =========================
                  // Status Analytics
                  // =========================
                  sectionTitle('تحليل حالات الطلبات'),
                  buildStatusChart(),

                  // =========================
                  // Region Analytics
                  // =========================
                  sectionTitle('المبيعات حسب المناطق'),
                  buildRegionChart(),

                  // =========================
                  // Top Products
                  // =========================
                  sectionTitle('الأكثر مبيعًا'),
                  buildTopProducts(),

                  // =========================
                  // Top Pharmacies
                  // =========================
                  sectionTitle('أكثر الصيدليات شراءً'),
                  buildTopPharmacies(),

                  // =========================
                  // Recent Orders
                  // =========================
                  sectionTitle('آخر الطلبات'),
                  buildRecentOrders(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}