import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';

class CompanyDashboardProScreen extends StatefulWidget {
  const CompanyDashboardProScreen({Key? key}) : super(key: key);

  @override
  State<CompanyDashboardProScreen> createState() =>
      _CompanyDashboardProScreenState();
}

class _CompanyDashboardProScreenState
    extends State<CompanyDashboardProScreen> {
  bool _isLoading = true;

  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthService>(
      context,
      listen: false,
    );

    final companyId = auth.currentCompanyId;

    if (companyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final provider = Provider.of<OrderProvider>(
      context,
      listen: false,
    );

    final orders =
        await provider.getOrdersForCompany(companyId);

    orders.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xfff5f7fb),

        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          backgroundColor: Colors.teal,
          centerTitle: true,
        ),

        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final completedOrders = _orders.where((o) =>
    o.status == 'accepted' ||
        o.status == 'delivered' ||
        o.status == 'shipped').toList();

    final totalSales = completedOrders.fold(
      0.0,
          (sum, o) => sum + o.totalPrice,
    );

    final totalOrders = completedOrders.length;

    double cashSales = 0;
    double creditSales = 0;

    for (var order in completedOrders) {
      if (order.paymentType == 'cash') {
        cashSales += order.totalPrice;
      } else {
        creditSales += order.totalPrice;
      }
    }

    final customers =
    completedOrders.map((o) => o.pharmacyId).toSet();

    int totalProducts = 0;

    for (var order in completedOrders) {
      totalProducts += order.items.length;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),

            children: [

              // ==========================
              // HEADER
              // ==========================

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'تحليل شامل لأداء الشركة',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refresh,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==========================
              // KPI CARDS
              // ==========================

              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),

                children: [

                  _buildKpiCard(
                    title: 'إجمالي المبيعات',
                    value:
                    totalSales.toStringAsFixed(0),
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),

                  _buildKpiCard(
                    title: 'الطلبات',
                    value: totalOrders.toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.teal,
                  ),

                  _buildKpiCard(
                    title: 'النقدي',
                    value:
                    cashSales.toStringAsFixed(0),
                    icon: Icons.payments,
                    color: Colors.orange,
                  ),

                  _buildKpiCard(
                    title: 'العملاء',
                    value:
                    customers.length.toString(),
                    icon: Icons.people,
                    color: Colors.indigo,
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ==========================
              // SALES TREND
              // ==========================

              _buildSectionTitle(
                'اتجاه المبيعات',
                Icons.show_chart,
              ),

              const SizedBox(height: 14),

              Container(
                height: 260,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(20),
                ),

                child: LineChart(
                  _buildSalesChart(completedOrders),
                ),
              ),

              const SizedBox(height: 28),

              // ==========================
              // PAYMENT CHART
              // ==========================

              _buildSectionTitle(
                'النقدي مقابل الآجل',
                Icons.pie_chart,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(20),
                ),

                child: Column(
                  children: [

                    SizedBox(
                      height: 240,

                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 45,

                          sections: [

                            PieChartSectionData(
                              value: cashSales,
                              color: Colors.green,
                              title:
                              '${_calculatePercent(cashSales, totalSales)}%',
                              radius: 70,
                              titleStyle:
                              const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            PieChartSectionData(
                              value: creditSales,
                              color: Colors.orange,
                              title:
                              '${_calculatePercent(creditSales, totalSales)}%',
                              radius: 70,
                              titleStyle:
                              const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,

                      children: [

                        _buildLegend(
                          'نقدي',
                          Colors.green,
                        ),

                        _buildLegend(
                          'آجل',
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==========================
              // RECENT ORDERS
              // ==========================

              _buildSectionTitle(
                'آخر الطلبات',
                Icons.receipt_long,
              ),

              const SizedBox(height: 14),

              ...completedOrders.take(5).map(
                    (order) => Card(
                  elevation: 0,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),

                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.all(14),

                    leading: CircleAvatar(
                      backgroundColor:
                      order.statusColor
                          .withOpacity(0.15),

                      child: Icon(
                        Icons.shopping_bag,
                        color:
                        order.statusColor,
                      ),
                    ),

                    title: Text(
                      order.pharmacyName,
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    subtitle: Padding(
                      padding:
                      const EdgeInsets.only(
                        top: 4,
                      ),

                      child: Text(
                        '${order.items.length} منتج',
                      ),
                    ),

                    trailing: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      crossAxisAlignment:
                      CrossAxisAlignment.end,

                      children: [

                        Text(
                          order.totalPrice
                              .toStringAsFixed(0),
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Colors.teal,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          order.statusText,
                          style: TextStyle(
                            color: order
                                .statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==========================
              // SMART INSIGHTS
              // ==========================

              _buildSectionTitle(
                'تحليلات ذكية',
                Icons.auto_graph,
              ),

              const SizedBox(height: 14),

              _buildInsightCard(
                icon: Icons.trending_up,
                color: Colors.green,
                title: 'أفضل أداء',
                subtitle:
                'متوسط الطلبات ممتاز خلال الفترة الحالية',
              ),

              _buildInsightCard(
                icon: Icons.people,
                color: Colors.indigo,
                title: 'العملاء النشطون',
                subtitle:
                '${customers.length} عميل نشط قاموا بالشراء',
              ),

              _buildInsightCard(
                icon: Icons.medication,
                color: Colors.deepOrange,
                title: 'المنتجات المباعة',
                subtitle:
                '$totalProducts منتج تم بيعه',
              ),

              const SizedBox(height: 30),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          CircleAvatar(
            radius: 24,
            backgroundColor:
            color.withOpacity(0.15),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [

        Icon(icon, color: Colors.teal),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(
      String text,
      Color color,
      ) {
    return Row(
      children: [

        Container(
          width: 14,
          height: 14,

          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Text(text),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: ListTile(
        contentPadding:
        const EdgeInsets.all(14),

        leading: CircleAvatar(
          radius: 24,
          backgroundColor:
          color.withOpacity(0.15),

          child: Icon(
            icon,
            color: color,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),

          child: Text(subtitle),
        ),
      ),
    );
  }

  LineChartData _buildSalesChart(
      List<OrderModel> orders,
      ) {
    Map<int, double> monthlySales = {};

    for (var order in orders) {
      final month = order.date.month;

      monthlySales[month] =
          (monthlySales[month] ?? 0) +
              order.totalPrice;
    }

    final spots = monthlySales.entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        e.value,
      );
    }).toList();

    return LineChartData(
      gridData: FlGridData(show: true),

      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        rightTitles:
        const AxisTitles(
          sideTitles:
          SideTitles(showTitles: false),
        ),

        topTitles:
        const AxisTitles(
          sideTitles:
          SideTitles(showTitles: false),
        ),
      ),

      lineBarsData: [

        LineChartBarData(
          spots: spots,

          isCurved: true,

          color: Colors.teal,

          barWidth: 4,

          dotData:
          const FlDotData(show: false),

          belowBarData: BarAreaData(
            show: true,
            color:
            Colors.teal.withOpacity(0.12),
          ),
        ),
      ],
    );
  }

  String _calculatePercent(
      double value,
      double total,
      ) {
    if (total == 0) return '0';

    return ((value / total) * 100)
        .toStringAsFixed(1);
  }
}