import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class SalesByRegionScreen extends StatefulWidget {
  const SalesByRegionScreen({Key? key}) : super(key: key);

  @override
  State<SalesByRegionScreen> createState() =>
      _SalesByRegionScreenState();
}

class _SalesByRegionScreenState
    extends State<SalesByRegionScreen> {
  bool _isLoading = true;

  DateTimeRange? _dateRange;

  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth =
          Provider.of<AuthService>(context, listen: false);

      final orderProvider =
          Provider.of<OrderProvider>(context, listen: false);

      final companyId = auth.currentCompanyId;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      List<OrderModel> orders =
          await orderProvider.getOrdersForCompany(companyId);

      // فقط الطلبات المكتملة
      orders = orders.where((o) {
        return o.status == 'accepted' ||
            o.status == 'shipped' ||
            o.status == 'delivered';
      }).toList();

      // فلترة التاريخ
      if (_dateRange != null) {
        orders = orders.where((o) {
          return o.date.isAfter(
                  _dateRange!.start.subtract(
                      const Duration(days: 1))) &&
              o.date.isBefore(
                  _dateRange!.end.add(
                      const Duration(days: 1)));
        }).toList();
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SalesByRegionScreen Error: $e');

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

  @override
  Widget build(BuildContext context) {
    // ===============================
    // تجميع البيانات حسب المنطقة
    // ===============================

    Map<String, Map<String, dynamic>> regionStats = {};

    double totalSales = 0;

    for (var order in _orders) {
      final region =
          order.pharmacyCity.isNotEmpty
              ? order.pharmacyCity
              : 'غير محددة';

      if (!regionStats.containsKey(region)) {
        regionStats[region] = {
          'sales': 0.0,
          'orders': 0,
          'customers': <String>{},
        };
      }

      regionStats[region]!['sales'] += order.totalPrice;

      regionStats[region]!['orders'] += 1;

      (regionStats[region]!['customers']
              as Set<String>)
          .add(order.pharmacyId);

      totalSales += order.totalPrice;
    }

    final entries = regionStats.entries.toList();

    entries.sort((a, b) {
      return (b.value['sales'] as double)
          .compareTo(a.value['sales'] as double);
    });

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('المبيعات حسب المناطق'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات حسب المناطق'),
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
        child: Column(
          children: [
            // ==========================
            // التاريخ
            // ==========================

            if (_dateRange != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
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
                      child: const Text(
                        'إلغاء التصفية',
                      ),
                    ),
                  ],
                ),
              ),

            // ==========================
            // الملخص
            // ==========================

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildSummaryCard(
                    'إجمالي المناطق',
                    entries.length.toString(),
                    Icons.map,
                    Colors.teal,
                  ),

                  const SizedBox(width: 12),

                  _buildSummaryCard(
                    'إجمالي المبيعات',
                    totalSales.toStringAsFixed(0),
                    Icons.attach_money,
                    Colors.green,
                  ),
                ],
              ),
            ),

            // ==========================
            // القائمة
            // ==========================

            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات',
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(8),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];

                        final region = entry.key;

                        final sales =
                            entry.value['sales']
                                as double;

                        final orders =
                            entry.value['orders']
                                as int;

                        final customers =
                            (entry.value['customers']
                                    as Set<String>)
                                .length;

                        final percentage =
                            totalSales > 0
                                ? (sales /
                                        totalSales) *
                                    100
                                : 0;

                        final avgOrder =
                            orders > 0
                                ? sales / orders
                                : 0;

                        return Card(
                          margin:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.teal,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(region),
                            subtitle: Text(
                              'المبيعات: '
                              '${sales.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.all(
                                        12),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      'عدد الطلبات',
                                      orders.toString(),
                                    ),
                                    _buildInfoRow(
                                      'عدد العملاء',
                                      customers.toString(),
                                    ),
                                    _buildInfoRow(
                                      'متوسط الطلب',
                                      avgOrder
                                          .toStringAsFixed(
                                              2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color),

              const SizedBox(height: 6),

              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(title),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}