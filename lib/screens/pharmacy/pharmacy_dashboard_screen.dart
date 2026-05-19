import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const PharmacyDashboardScreen({
    Key? key,
    required this.pharmacyId,
    required this.pharmacyName,
  }) : super(key: key);

  @override
  State<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState
    extends State<PharmacyDashboardScreen> {
  bool isLoading = true;

  List<OrderModel> orders = [];

  double totalPurchases = 0;
  double cashPurchases = 0;
  double creditPurchases = 0;

  int totalOrders = 0;
  int pendingOrders = 0;
  int deliveredOrders = 0;

  double averageOrder = 0;

  Map<String, double> monthlySales = {};
  Map<String, double> companyTotals = {};
  Map<String, int> productTotals = {};

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final provider = Provider.of<OrderProvider>(
      context,
      listen: false,
    );

    orders = await provider.getOrdersForPharmacy(
      widget.pharmacyId,
    );

    calculateData();

    setState(() {
      isLoading = false;
    });
  }

  void calculateData() {
    totalPurchases = 0;
    cashPurchases = 0;
    creditPurchases = 0;

    totalOrders = orders.length;
    pendingOrders = 0;
    deliveredOrders = 0;

    monthlySales.clear();
    companyTotals.clear();
    productTotals.clear();

    for (var order in orders) {
      totalPurchases += order.totalPrice;

      if (order.paymentType == 'cash') {
        cashPurchases += order.totalPrice;
      } else {
        creditPurchases += order.totalPrice;
      }

      if (order.status == 'pending') {
        pendingOrders++;
      }

      if (order.status == 'delivered') {
        deliveredOrders++;
      }

      final month =
          "${order.date.month}/${order.date.year}";

      monthlySales.update(
        month,
        (value) => value + order.totalPrice,
        ifAbsent: () => order.totalPrice,
      );

      companyTotals.update(
        order.companyName,
        (value) => value + order.totalPrice,
        ifAbsent: () => order.totalPrice,
      );

      for (var item in order.items) {
        productTotals.update(
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
    final list = companyTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return list.take(5).toList();
  }

  List<MapEntry<String, int>> getTopProducts() {
    final list = productTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.pharmacyName),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  /// =========================
                  /// HEADER
                  /// =========================

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff1565C0),
                          Color(0xff42A5F5),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          'إجمالي المشتريات',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '${totalPurchases.toStringAsFixed(0)} ر.ي',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [

                            dashboardStat(
                              'الطلبات',
                              '$totalOrders',
                            ),

                            dashboardStat(
                              'المعلقة',
                              '$pendingOrders',
                            ),

                            dashboardStat(
                              'المكتملة',
                              '$deliveredOrders',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// KPI CARDS
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
                        title: 'مشتريات نقدية',
                        value:
                            '${cashPurchases.toStringAsFixed(0)}',
                        icon: Icons.payments,
                        color: Colors.green,
                      ),

                      analyticsCard(
                        title: 'مشتريات آجل',
                        value:
                            '${creditPurchases.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),

                      analyticsCard(
                        title: 'متوسط الطلب',
                        value:
                            '${averageOrder.toStringAsFixed(0)}',
                        icon: Icons.analytics,
                        color: Colors.blue,
                      ),

                      analyticsCard(
                        title: 'الشركات',
                        value:
                            '${companyTotals.length}',
                        icon: Icons.business,
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// MONTHLY TREND
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
                            spots: monthlySales.entries
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
                  /// PAYMENT ANALYTICS
                  /// =========================

                  sectionTitle('تحليل الدفع'),

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
                  /// TOP COMPANIES
                  /// =========================

                  sectionTitle('أفضل الشركات'),

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

                  sectionTitle('المنتجات الأكثر شراء'),

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

                  /// =========================
                  /// RECENT ORDERS
                  /// =========================

                  sectionTitle('آخر الطلبات'),

                  const SizedBox(height: 12),

                  ...orders.take(5).map(
                    (order) => recentOrderCard(order),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget dashboardStat(
    String title,
    String value,
  ) {
    return Column(
      children: [

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
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
      decoration: cardDecoration(),
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

  Widget recentOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [

          CircleAvatar(
            backgroundColor:
                order.statusColor.withOpacity(0.15),
            child: Icon(
              Icons.shopping_cart,
              color: order.statusColor,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  order.companyName,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${order.totalPrice.toStringAsFixed(0)} ر.ي',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: order.statusColor
                  .withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              order.statusText,
              style: TextStyle(
                color: order.statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
}