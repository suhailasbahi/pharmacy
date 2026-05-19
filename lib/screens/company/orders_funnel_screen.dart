import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class OrdersFunnelScreen extends StatefulWidget {
  const OrdersFunnelScreen({Key? key}) : super(key: key);

  @override
  State<OrdersFunnelScreen> createState() =>
      _OrdersFunnelScreenState();
}

class _OrdersFunnelScreenState
    extends State<OrdersFunnelScreen> {
  DateTimeRange? _dateRange;

  List<OrderModel> _orders = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final auth =
        Provider.of<AuthService>(context, listen: false);

    final companyId = auth.currentCompanyId;

    if (companyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);

    List<OrderModel> orders =
        await orderProvider.getOrdersForCompany(companyId);

    // فلترة التاريخ
    if (_dateRange != null) {
      orders = orders.where((o) {
        return o.date.isAfter(_dateRange!.start) &&
            o.date.isBefore(
              _dateRange!.end.add(
                const Duration(days: 1),
              ),
            );
      }).toList();
    }

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
          title: const Text('تحليل دورة الطلبات'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // =====================================
    // الإحصائيات
    // =====================================

    final totalOrders = _orders.length;

    final pendingOrders = _orders
        .where((o) => o.status == 'pending')
        .length;

    final acceptedOrders = _orders
        .where((o) => o.status == 'accepted')
        .length;

    final shippedOrders = _orders
        .where((o) => o.status == 'shipped')
        .length;

    final deliveredOrders = _orders
        .where((o) => o.status == 'delivered')
        .length;

    final rejectedOrders = _orders
        .where((o) => o.status == 'rejected')
        .length;

    // =====================================
    // النسب
    // =====================================

    double pendingPercent = totalOrders > 0
        ? (pendingOrders / totalOrders) * 100
        : 0;

    double acceptedPercent = totalOrders > 0
        ? (acceptedOrders / totalOrders) * 100
        : 0;

    double shippedPercent = totalOrders > 0
        ? (shippedOrders / totalOrders) * 100
        : 0;

    double deliveredPercent = totalOrders > 0
        ? (deliveredOrders / totalOrders) * 100
        : 0;

    double rejectedPercent = totalOrders > 0
        ? (rejectedOrders / totalOrders) * 100
        : 0;

    // =====================================
    // Conversion Rate
    // =====================================

    final conversionRate = totalOrders > 0
        ? ((deliveredOrders + shippedOrders) /
                totalOrders) *
            100
        : 0;

    // =====================================
    // Rejection Rate
    // =====================================

    final rejectionRate = totalOrders > 0
        ? (rejectedOrders / totalOrders) * 100
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل دورة الطلبات'),
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
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // =====================================
              // التاريخ
              // =====================================

              if (_dateRange != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'من ${_formatDate(_dateRange!.start)} '
                        'إلى ${_formatDate(_dateRange!.end)}',
                      ),
                      TextButton(
                        onPressed: () async {
                          setState(
                              () => _dateRange = null);

                          await _loadData();
                        },
                        child: const Text('إلغاء'),
                      ),
                    ],
                  ),
                ),

              // =====================================
              // KPIs
              // =====================================

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildKpiCard(
                      'إجمالي الطلبات',
                      totalOrders.toString(),
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                    const SizedBox(width: 10),
                    _buildKpiCard(
                      'معدل التحويل',
                      '${conversionRate.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                    const SizedBox(width: 10),
                    _buildKpiCard(
                      'معدل الرفض',
                      '${rejectionRate.toStringAsFixed(1)}%',
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),
              ),

              // =====================================
              // Funnel
              // =====================================

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildFunnelCard(
                      title: 'قيد المراجعة',
                      count: pendingOrders,
                      percent: pendingPercent,
                      color: Colors.orange,
                      icon: Icons.pending,
                    ),

                    const SizedBox(height: 14),

                    _buildFunnelCard(
                      title: 'تم القبول',
                      count: acceptedOrders,
                      percent: acceptedPercent,
                      color: Colors.blue,
                      icon: Icons.check_circle,
                    ),

                    const SizedBox(height: 14),

                    _buildFunnelCard(
                      title: 'تم الشحن',
                      count: shippedOrders,
                      percent: shippedPercent,
                      color: Colors.purple,
                      icon: Icons.local_shipping,
                    ),

                    const SizedBox(height: 14),

                    _buildFunnelCard(
                      title: 'تم التسليم',
                      count: deliveredOrders,
                      percent: deliveredPercent,
                      color: Colors.green,
                      icon: Icons.done_all,
                    ),

                    const SizedBox(height: 14),

                    _buildFunnelCard(
                      title: 'مرفوضة',
                      count: rejectedOrders,
                      percent: rejectedPercent,
                      color: Colors.red,
                      icon: Icons.cancel,
                    ),
                  ],
                ),
              ),

              // =====================================
              // Insights
              // =====================================

              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.insights,
                              color: Colors.teal,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'تحليلات ذكية',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _buildInsightRow(
                          'الطلبات المكتملة',
                          '${deliveredOrders + shippedOrders} طلب',
                          Colors.green,
                        ),

                        const SizedBox(height: 12),

                        _buildInsightRow(
                          'الطلبات المعلقة',
                          '$pendingOrders طلب',
                          Colors.orange,
                        ),

                        const SizedBox(height: 12),

                        _buildInsightRow(
                          'الطلبات المرفوضة',
                          '$rejectedOrders طلب',
                          Colors.red,
                        ),

                        const SizedBox(height: 12),

                        _buildInsightRow(
                          'نسبة نجاح الطلبات',
                          '${conversionRate.toStringAsFixed(1)}%',
                          Colors.teal,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.08),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color),

              const SizedBox(height: 8),

              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunnelCard({
    required String title,
    required int count,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),

                const SizedBox(width: 12),

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
                        '$count طلب',
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 10,
                backgroundColor:
                    Colors.grey.shade300,
                valueColor:
                    AlwaysStoppedAnimation(
                  color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    String title,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}