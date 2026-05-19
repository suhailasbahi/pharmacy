import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class ProductMovementScreen extends StatefulWidget {
  const ProductMovementScreen({Key? key}) : super(key: key);

  @override
  State<ProductMovementScreen> createState() =>
      _ProductMovementScreenState();
}

class _ProductMovementScreenState
    extends State<ProductMovementScreen> {
  DateTimeRange? _dateRange;

  List<OrderModel> _allOrders = [];

  bool _isLoading = true;

  String _movementType = 'fast';
  // fast | slow | stagnant

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

    // فقط الطلبات الفعلية
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
          title: const Text('حركة الأصناف'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // =====================================
    // تجميع حركة المنتجات
    // =====================================

    Map<String, Map<String, dynamic>> products = {};

    for (var order in _allOrders) {
      for (var item in order.items) {
        if (!products.containsKey(item.productId)) {
          products[item.productId] = {
            'name': item.productName,
            'scientificName': item.scientificName,
            'quantity': 0.0,
            'sales': 0.0,
            'orders': 0,
            'lastSale': order.date,
          };
        }

        products[item.productId]!['quantity'] +=
            item.quantity.toDouble();

        products[item.productId]!['sales'] +=
            item.totalPrice;

        products[item.productId]!['orders'] += 1;

        if (order.date.isAfter(
          products[item.productId]!['lastSale'],
        )) {
          products[item.productId]!['lastSale'] =
              order.date;
        }
      }
    }

    final entries = products.entries.toList();

    // =====================================
    // تصنيف الحركة
    // =====================================

    entries.sort((a, b) {
      final q1 = b.value['quantity'] as double;
      final q2 = a.value['quantity'] as double;
      return q1.compareTo(q2);
    });

    List<MapEntry<String, Map<String, dynamic>>>
        filteredEntries = [];

    if (_movementType == 'fast') {
      filteredEntries = entries.take(20).toList();
    } else if (_movementType == 'slow') {
      filteredEntries =
          entries.reversed.take(20).toList();
    } else {
      filteredEntries = entries.where((entry) {
        final lastSale =
            entry.value['lastSale'] as DateTime;

        return DateTime.now()
                .difference(lastSale)
                .inDays >
            30;
      }).toList();
    }

    double totalSales = filteredEntries.fold(
      0.0,
      (sum, e) => sum + (e.value['sales'] as double),
    );

    double totalQuantity = filteredEntries.fold(
      0.0,
      (sum, e) => sum + (e.value['quantity'] as double),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة الأصناف'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _movementType = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'fast',
                child: Text('سريع الحركة'),
              ),
              const PopupMenuItem(
                value: 'slow',
                child: Text('بطيء الحركة'),
              ),
              const PopupMenuItem(
                value: 'stagnant',
                child: Text('راكد'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                        setState(() => _dateRange = null);
                        await _loadData();
                      },
                      child: const Text('إلغاء'),
                    ),
                  ],
                ),
              ),

            // =====================================
            // ملخص علوي
            // =====================================

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildSummaryCard(
                    'الأصناف',
                    filteredEntries.length.toString(),
                    Icons.medication,
                    Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'الكمية',
                    totalQuantity.toStringAsFixed(0),
                    Icons.inventory,
                    Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'المبيعات',
                    totalSales.toStringAsFixed(0),
                    Icons.attach_money,
                    Colors.green,
                  ),
                ],
              ),
            ),

            // =====================================
            // القائمة
            // =====================================

            Expanded(
              child: filteredEntries.isEmpty
                  ? const Center(
                      child: Text('لا توجد بيانات'),
                    )
                  : ListView.builder(
                      itemCount:
                          filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry =
                            filteredEntries[index];

                        final data = entry.value;

                        final quantity =
                            data['quantity'] as double;

                        final sales =
                            data['sales'] as double;

                        final orders =
                            data['orders'] as int;

                        final lastSale =
                            data['lastSale']
                                as DateTime;

                        final percent =
                            totalQuantity > 0
                                ? (quantity /
                                        totalQuantity) *
                                    100
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
                                          _getMovementColor(),
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
                                            data[
                                                'scientificName'],
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

                                    _buildMovementBadge(),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceAround,
                                  children: [
                                    _buildInfoItem(
                                      'الكمية',
                                      quantity
                                          .toStringAsFixed(
                                              0),
                                      Colors.orange,
                                    ),
                                    _buildInfoItem(
                                      'الطلبات',
                                      orders.toString(),
                                      Colors.blue,
                                    ),
                                    _buildInfoItem(
                                      'المبيعات',
                                      sales
                                          .toStringAsFixed(
                                              0),
                                      Colors.green,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Text(
                                      'آخر بيع: ${_formatDate(lastSale)}',
                                      style: TextStyle(
                                        color: Colors
                                            .grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${percent.toStringAsFixed(1)}%',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

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
                                        AlwaysStoppedAnimation(
                                      _getMovementColor(),
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

  Widget _buildMovementBadge() {
    Color color;
    String text;

    switch (_movementType) {
      case 'fast':
        color = Colors.green;
        text = 'سريع';
        break;

      case 'slow':
        color = Colors.orange;
        text = 'بطيء';
        break;

      default:
        color = Colors.red;
        text = 'راكد';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getMovementColor() {
    switch (_movementType) {
      case 'fast':
        return Colors.green;

      case 'slow':
        return Colors.orange;

      default:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}