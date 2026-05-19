import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class CompanyAnalyticsDashboard extends StatefulWidget {
  final String companyId;

  const CompanyAnalyticsDashboard({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CompanyAnalyticsDashboard> createState() =>
      _CompanyAnalyticsDashboardState();
}

class _CompanyAnalyticsDashboardState
    extends State<CompanyAnalyticsDashboard> {
  bool isLoading = true;

  List<OrderModel> orders = [];

  double totalSales = 0;
  double cashSales = 0;
  double creditSales = 0;

  int totalOrders = 0;
  int deliveredOrders = 0;
  int pendingOrders = 0;
  int rejectedOrders = 0;

  double averageOrder = 0;

  Map<String, double> regionSales = {};
  Map<String, int> productSales = {};
  Map<String, double> dailySales = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);

    orders = await provider.getOrdersForCompany(widget.companyId);

    calculateAnalytics();

    setState(() {
      isLoading = false;
    });
  }

  void calculateAnalytics() {
    totalSales = 0;
    cashSales = 0;
    creditSales = 0;

    totalOrders = orders.length;
    deliveredOrders = 0;
    pendingOrders = 0;
    rejectedOrders = 0;

    regionSales.clear();
    productSales.clear();
    dailySales.clear();

    for (var order in orders) {
      totalSales += order.totalPrice;

      if (order.paymentType == 'cash') {
        cashSales += order.totalPrice;
      } else {
        creditSales += order.totalPrice;
      }

      switch (order.status) {
        case 'delivered':
          deliveredOrders++;
          break;

        case 'pending':
          pendingOrders++;
          break;

        case 'rejected':
          rejectedOrders++;
          break;
      }

      regionSales.update(
        order.pharmacyCity,
        (value) => value + order.totalPrice,
        ifAbsent: () => order.totalPrice,
      );

      final day =
          "${order.date.day}/${order.date.month}";

      dailySales.update(
        day,
        (value) => value + order.totalPrice,
        ifAbsent: () => order.totalPrice,
      );

      for (var item in order.items) {
        productSales.update(
          item.productName,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    averageOrder =
        totalOrders == 0 ? 0 : totalSales / totalOrders;
  }

  List<MapEntry<String, double>> getTopRegions() {
    final sorted = regionSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  List<MapEntry<String, int>> getTopProducts() {
    final sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        title: const Text('لوحة تحليلات الشركة'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  /// =========================
                  /// TOP CARDS
                  /// =========================

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [

                      analyticsCard(
                        title: 'إجمالي المبيعات',
                        value:
                            '${totalSales.toStringAsFixed(0)} ر.ي',
                        icon: Icons.payments,
                        color: Colors.green,
                      ),

                      analyticsCard(
                        title: 'عدد الطلبات',
                        value: '$totalOrders',
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                      ),

                      analyticsCard(
                        title: 'متوسط الطلب',
                        value:
                            '${averageOrder.toStringAsFixed(0)}',
                        icon: Icons.analytics,
                        color: Colors.orange,
                      ),

                      analyticsCard(
                        title: 'طلبات مكتملة',
                        value: '$deliveredOrders',
                        icon: Icons.check_circle,
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// SALES TREND
                  /// =========================

                  sectionTitle('اتجاه المبيعات'),

                  const SizedBox(height: 16),

                  Container(
                    height: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration(),
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: FlGridData(
                          show: true,
                        ),
                        titlesData: FlTitlesData(
                          rightTitles:
                              const AxisTitles(),
                          topTitles:
                              const AxisTitles(),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: dailySales.entries
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.value,
                                  ),
                                )
                                .toList(),
                            barWidth: 4,
                            dotData:
                                const FlDotData(
                              show: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// CASH VS CREDIT
                  /// =========================

                  sectionTitle('نقدي / آجل'),

                  const SizedBox(height: 16),

                  Container(
                    height: 260,
                    decoration: cardDecoration(),
                    child: PieChart(
                      PieChartData(
                        sections: [

                          PieChartSectionData(
                            value: cashSales,
                            title: 'نقدي',
                            radius: 70,
                            color: Colors.green,
                          ),

                          PieChartSectionData(
                            value: creditSales,
                            title: 'آجل',
                            radius: 70,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// ORDER STATUS
                  /// =========================

                  sectionTitle('حالات الطلبات'),

                  const SizedBox(height: 16),

                  Container(
                    height: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration(),
                    child: BarChart(
                      BarChartData(
                        borderData:
                            FlBorderData(show: false),
                        titlesData:
                            FlTitlesData(show: false),
                        barGroups: [

                          buildBar(
                            0,
                            pendingOrders.toDouble(),
                            Colors.orange,
                          ),

                          buildBar(
                            1,
                            deliveredOrders.toDouble(),
                            Colors.green,
                          ),

                          buildBar(
                            2,
                            rejectedOrders.toDouble(),
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// TOP REGIONS
                  /// =========================

                  sectionTitle('أفضل المناطق'),

                  const SizedBox(height: 12),

                  ...getTopRegions().map(
                    (region) => analyticsListTile(
                      title: region.key,
                      subtitle:
                          '${region.value.toStringAsFixed(0)} ر.ي',
                      icon: Icons.location_on,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// TOP PRODUCTS
                  /// =========================

                  sectionTitle('أفضل المنتجات'),

                  const SizedBox(height: 12),

                  ...getTopProducts().map(
                    (product) => analyticsListTile(
                      title: product.key,
                      subtitle:
                          '${product.value} وحدة',
                      icon: Icons.medication,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget analyticsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [

          CircleAvatar(
            backgroundColor:
                color.withOpacity(0.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
        ),
      ],
    );
  }

  BarChartGroupData buildBar(
    int x,
    double value,
    Color color,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [

        BarChartRodData(
          toY: value,
          color: color,
          width: 28,
          borderRadius:
              BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget analyticsListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [

          CircleAvatar(
            backgroundColor:
                color.withOpacity(0.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}