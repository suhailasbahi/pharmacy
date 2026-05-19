import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class TopPharmaciesScreen extends StatefulWidget {
  const TopPharmaciesScreen({Key? key}) : super(key: key);

  @override
  State<TopPharmaciesScreen> createState() =>
      _TopPharmaciesScreenState();
}

class _TopPharmaciesScreenState
    extends State<TopPharmaciesScreen> {
  DateTimeRange? _dateRange;
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;

  String _sortBy = 'amount';
  // amount | orders | quantity

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

    // فقط الطلبات المكتملة
    orders = orders.where((o) {
      return o.status == 'accepted' ||
          o.status == 'shipped' ||
          o.status == 'delivered';
    }).toList();

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('أفضل الصيدليات'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ===============================
    // تجميع بيانات الصيدليات
    // ===============================

    Map<String, Map<String, dynamic>> pharmacies = {};

    double totalSales = 0;
    int totalOrders = 0;
    double totalQuantity = 0;

    for (var order in _allOrders) {
      final pharmacyId = order.pharmacyId;

      if (!pharmacies.containsKey(pharmacyId)) {
        pharmacies[pharmacyId] = {
          'name': order.pharmacyName,
          'city': order.pharmacyCity,
          'amount': 0.0,
          'orders': 0,
          'quantity': 0.0,
        };
      }

      pharmacies[pharmacyId]!['amount'] += order.totalPrice;
      pharmacies[pharmacyId]!['orders'] += 1;

      totalSales += order.totalPrice;
      totalOrders++;

      for (var item in order.items) {
        pharmacies[pharmacyId]!['quantity'] +=
            item.quantity.toDouble();

        totalQuantity += item.quantity.toDouble();
      }
    }

    final entries = pharmacies.entries.toList();

    // ===============================
    // ترتيب
    // ===============================

    if (_sortBy == 'amount') {
      entries.sort((a, b) => (b.value['amount'] as double)
          .compareTo(a.value['amount'] as double));
    } else if (_sortBy == 'orders') {
      entries.sort((a, b) => (b.value['orders'] as int)
          .compareTo(a.value['orders'] as int));
    } else {
      entries.sort((a, b) => (b.value['quantity'] as double)
          .compareTo(a.value['quantity'] as double));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('أفضل الصيدليات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'amount',
                child: Text('حسب المبيعات'),
              ),
              const PopupMenuItem(
                value: 'orders',
                child: Text('حسب الطلبات'),
              ),
              const PopupMenuItem(
                value: 'quantity',
                child: Text('حسب الكمية'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // ===============================
            // فلترة التاريخ
            // ===============================

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
                        setState(() => _dateRange = null);
                        await _loadData();
                      },
                      child: const Text('إلغاء'),
                    ),
                  ],
                ),
              ),

            // ===============================
            // البطاقات العلوية
            // ===============================

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildSummaryCard(
                    'إجمالي المبيعات',
                    totalSales.toStringAsFixed(0),
                    Icons.attach_money,
                    Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'إجمالي الطلبات',
                    totalOrders.toString(),
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'إجمالي الكمية',
                    totalQuantity.toStringAsFixed(0),
                    Icons.inventory_2,
                    Colors.orange,
                  ),
                ],
              ),
            ),

            // ===============================
            // القائمة
            // ===============================

            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text('لا توجد بيانات'),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];

                        final data = entry.value;

                        final amount =
                            data['amount'] as double;

                        final orders =
                            data['orders'] as int;

                        final quantity =
                            data['quantity'] as double;

                        final percent =
                            totalSales > 0
                                ? (amount / totalSales) * 100
                                : 0;

                        return Card(
                          margin:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.teal,
                                      child: Text(
                                        '${index + 1}',
                                        style:
                                            const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            data['name'],
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          const SizedBox(
                                              height: 4),

                                          Text(
                                            data['city'],
                                            style:
                                                TextStyle(
                                              color: Colors
                                                  .grey
                                                  .shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.teal
                                            .withOpacity(
                                                0.1),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    12),
                                      ),
                                      child: Text(
                                        '${percent.toStringAsFixed(1)}%',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.teal,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceAround,
                                  children: [
                                    _buildInfoItem(
                                      'المبيعات',
                                      amount
                                          .toStringAsFixed(
                                              0),
                                      Colors.green,
                                    ),
                                    _buildInfoItem(
                                      'الطلبات',
                                      orders.toString(),
                                      Colors.blue,
                                    ),
                                    _buildInfoItem(
                                      'الكمية',
                                      quantity
                                          .toStringAsFixed(
                                              0),
                                      Colors.orange,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                          10),
                                  child:
                                      LinearProgressIndicator(
                                    value: percent / 100,
                                    minHeight: 8,
                                    backgroundColor:
                                        Colors.grey
                                            .shade300,
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                      Colors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
        color: color.withOpacity(0.08),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
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
      ),
    );
  }

  Widget _buildInfoItem(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}