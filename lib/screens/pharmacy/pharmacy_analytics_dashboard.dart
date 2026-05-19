import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class PharmacyAnalyticsDashboard extends StatefulWidget {
  final String pharmacyId;

  const PharmacyAnalyticsDashboard({
    Key? key,
    required this.pharmacyId,
  }) : super(key: key);

  @override
  State<PharmacyAnalyticsDashboard> createState() =>
      _PharmacyAnalyticsDashboardState();
}

class _PharmacyAnalyticsDashboardState
    extends State<PharmacyAnalyticsDashboard> {
  bool isLoading = true;

  List<OrderModel> orders = [];

  double totalPurchases = 0;
  double cashPurchases = 0;
  double creditPurchases = 0;

  int totalOrders = 0;
  int deliveredOrders = 0;
  int pendingOrders = 0;
  int rejectedOrders = 0;

  double averageOrder = 0;

  Map<String, double> companyPurchases = {};
  Map<String, int> productPurchases = {};
  Map<String, double> monthlyPurchases = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final provider = Provider.of<OrderProvider>(
      context,
      listen: false,
    );

    orders = await provider.getOrdersForPharmacy(
      widget.pharmacyId,
    );

    calculateAnalytics();

    setState(() {
      isLoading = false;
    });
  }

  void calculateAnalytics() {
    totalPurchases = 0;
    cashPurchases = 0;
    creditPurchases = 0;

    totalOrders = orders.length;
    deliveredOrders = 0;
    pendingOrders = 0;
    rejectedOrders = 0;

    companyPurchases.clear();
    productPurchases.clear();
    monthlyPurchases.clear();

    for (var order in orders) {
      totalPurchases += order.totalPrice;

      if (order.paymentType == 'cash') {
        cashPurchases += order.totalPrice;
      } else {
        creditPurchases += order.totalPrice;
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

      companyPurchases.update(
        order.companyName,
        (value) => value + order.totalPrice,
        ifAbsent: () => order.totalPrice,
      );

      final month =
          "${order.date.month}/${order.date.year}";

      monthlyPurchases.update(
        month,
        (value) => value + order.totalPrice,
        ifAbsent: () => order.totalPrice,
      );

      for (var item in order.items) {
        productPurchases.update(
          item.productName,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    averageOrder =
        totalOrders == 0 ? 0 : totalPurchases / totalOrders;
  }

  List<MapEntry<String, double>> getTopCompanies() {
    final sorted = companyPurchases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  List<MapEntry<String, int>> getTopProducts() {
    final sorted = productPurchases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        title: const Text('تحليلات الصيدلية'),
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
                  /// ANALYTICS CARDS
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
                        title: 'إجمالي المشتريات',
                        value:
                            '${totalPurchases.toStringAsFixed(0)} ر.ي',
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
                  /// MONTHLY PURCHASES
                  /// =========================

                  sectionTitle('اتجاه المشتريات'),

                  const SizedBox(height: 16),

                  Container(
                    height: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration(),
                    child: LineChart(
                      LineChartData(
                        borderData:
                            FlBorderData(show: false),
                        gridData:
                            FlGridData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles:
                              const AxisTitles(),
                          topTitles:
                              const AxisTitles(),
                        ),
                        lineBarsData: [

                          LineChartBarData(
                            isCurved: true,
                            barWidth: 4,
                            dotData:
                                const FlDotData(
                              show: true,
                            ),
                            spots: monthlyPurchases.entries
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
                            value: cashPurchases,
                            title: 'نقدي',
                            radius: 70,
                            color: Colors.green,
                          ),

                          PieChartSectionData(
                            value: creditPurchases,
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
                  /// TOP COMPANIES
                  /// =========================

                  sectionTitle('أكثر الشركات شراءً منها'),

                  const SizedBox(height: 12),

                  ...getTopCompanies().map(
                    (company) => analyticsTile(
                      title: company.key,
                      subtitle:
                          '${company.value.toStringAsFixed(0)} ر.ي',
                      icon: Icons.business,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// TOP PRODUCTS
                  /// =========================

                  sectionTitle('أكثر المنتجات شراءً'),

                  const SizedBox(height: 12),

                  ...getTopProducts().map(
                    (product) => analyticsTile(
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
          ),
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

  Widget analyticsTile({
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