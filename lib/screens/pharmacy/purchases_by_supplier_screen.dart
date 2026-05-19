import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class PurchasesBySupplierScreen extends StatefulWidget {
  const PurchasesBySupplierScreen({Key? key})
      : super(key: key);

  @override
  State<PurchasesBySupplierScreen> createState() =>
      _PurchasesBySupplierScreenState();
}

class _PurchasesBySupplierScreenState
    extends State<PurchasesBySupplierScreen> {
  String _selectedSupplier = 'all';

  List<String> suppliers = [];

  DateTimeRange? _dateRange;

  List<OrderModel> _allOrders = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =========================================
  // تحميل البيانات
  // =========================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth =
          Provider.of<AuthService>(context,
              listen: false);

      final pharmacyId = auth.currentUserId;

      if (pharmacyId == null ||
          pharmacyId.isEmpty) {
        setState(() {
          _allOrders = [];
          _isLoading = false;
        });

        return;
      }

      final orderProvider =
          Provider.of<OrderProvider>(
        context,
        listen: false,
      );

      List<OrderModel> orders =
          await orderProvider
              .getOrdersForPharmacy(
        pharmacyId,
      );

      // =========================================
      // استبعاد الطلبات المرفوضة
      // =========================================
      orders = orders
          .where(
            (o) => o.status != 'rejected',
          )
          .toList();

      // =========================================
      // فلترة بالتاريخ
      // =========================================
      if (_dateRange != null) {
        orders = orders.where((o) {
          return o.date.isAfter(
                  _dateRange!.start.subtract(
                const Duration(days: 1),
              )) &&
              o.date.isBefore(
                _dateRange!.end.add(
                  const Duration(days: 1),
                ),
              );
        }).toList();
      }

      // =========================================
      // استخراج الموردين
      // =========================================
      final suppliersSet = orders
          .map((o) => o.companyName)
          .toSet()
          .toList();

      suppliersSet.sort();

      // =========================================
      // ترتيب الطلبات
      // =========================================
      orders.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      setState(() {
        _allOrders = orders;

        suppliers = [
          'all',
          ...suppliersSet,
        ];

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'PurchasesBySupplierScreen Error: $e',
      );

      setState(() {
        _allOrders = [];

        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // =========================================
  // اختيار التاريخ
  // =========================================
  Future<void> _selectDateRange() async {
    final picked =
        await showDateRangePicker(
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
          title:
              const Text('المشتريات حسب المورد'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // =========================================
    // الفلترة حسب المورد
    // =========================================
    List<OrderModel> orders = _allOrders;

    if (_selectedSupplier != 'all') {
      orders = orders.where((o) {
        return o.companyName ==
            _selectedSupplier;
      }).toList();
    }

    // =========================================
    // تجميع البيانات
    // =========================================
    Map<String, Map<String, dynamic>>
        supplierStats = {};

    double totalPurchases = 0;

    double totalCash = 0;

    double totalCredit = 0;

    int totalOrders = 0;

    int totalQuantity = 0;

    int totalPieces = 0;

    for (var order in orders) {
      final supplier = order.companyName;

      if (!supplierStats
          .containsKey(supplier)) {
        supplierStats[supplier] = {
          'total': 0.0,
          'cash': 0.0,
          'credit': 0.0,
          'orders': 0,
          'quantity': 0,
          'pieces': 0,
        };
      }

      // =========================================
      // المبالغ
      // =========================================
      supplierStats[supplier]!['total'] +=
          order.totalPrice;

      totalPurchases += order.totalPrice;

      // =========================================
      // نقدي / آجل
      // =========================================
      if (order.paymentType == 'cash') {
        supplierStats[supplier]!['cash'] +=
            order.totalPrice;

        totalCash += order.totalPrice;
      } else {
        supplierStats[supplier]!['credit'] +=
            order.totalPrice;

        totalCredit += order.totalPrice;
      }

      // =========================================
      // عدد الطلبات
      // =========================================
      supplierStats[supplier]!['orders'] += 1;

      totalOrders++;

      // =========================================
      // الكميات والقطع
      // =========================================
      for (var item in order.items) {
        supplierStats[supplier]!['quantity'] +=
            item.quantity;

        supplierStats[supplier]!['pieces'] +=
            item.quantityInPieces;

        totalQuantity += item.quantity;

        totalPieces +=
            item.quantityInPieces;
      }
    }

    // =========================================
    // الترتيب
    // =========================================
    final entries =
        supplierStats.entries.toList();

    entries.sort((a, b) {
      return (b.value['total'] as double)
          .compareTo(
        a.value['total'] as double,
      );
    });

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('المشتريات حسب المورد'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.date_range),
            tooltip: 'تحديد فترة',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // =========================================
            // شريط التاريخ
            // =========================================
            if (_dateRange != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(10),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'من ${_formatDate(_dateRange!.start)} '
                        'إلى ${_formatDate(_dateRange!.end)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          _dateRange = null;
                        });

                        await _loadData();
                      },
                      child:
                          const Text('إلغاء التصفية'),
                    ),
                  ],
                ),
              ),

            // =========================================
            // البطاقات الإحصائية
            // =========================================
            Padding(
              padding:
                  const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildSummaryCard(
                          title:
                              'إجمالي المشتريات',
                          value:
                              totalPurchases
                                  .toStringAsFixed(
                                      2),
                          color: Colors.teal,
                          icon: Icons
                              .shopping_cart,
                        ),
                      ),
                      const SizedBox(
                          width: 8),
                      Expanded(
                        child:
                            _buildSummaryCard(
                          title: 'نقدي',
                          value: totalCash
                              .toStringAsFixed(
                                  2),
                          color: Colors.green,
                          icon: Icons.money,
                        ),
                      ),
                      const SizedBox(
                          width: 8),
                      Expanded(
                        child:
                            _buildSummaryCard(
                          title: 'آجل',
                          value: totalCredit
                              .toStringAsFixed(
                                  2),
                          color:
                              Colors.orange,
                          icon: Icons
                              .credit_card,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildSummaryCard(
                          title:
                              'عدد الطلبات',
                          value:
                              totalOrders
                                  .toString(),
                          color: Colors.blue,
                          icon:
                              Icons.receipt,
                        ),
                      ),
                      const SizedBox(
                          width: 8),
                      Expanded(
                        child:
                            _buildSummaryCard(
                          title: 'الكمية',
                          value:
                              totalQuantity
                                  .toString(),
                          color:
                              Colors.purple,
                          icon: Icons
                              .inventory,
                        ),
                      ),
                      const SizedBox(
                          width: 8),
                      Expanded(
                        child:
                            _buildSummaryCard(
                          title: 'القطع',
                          value:
                              totalPieces
                                  .toString(),
                          color: Colors.red,
                          icon: Icons
                              .medication,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =========================================
            // اختيار المورد
            // =========================================
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child:
                  DropdownButtonFormField<
                      String>(
                value: _selectedSupplier,
                decoration:
                    const InputDecoration(
                  labelText:
                      'تصفية حسب المورد',
                  border:
                      OutlineInputBorder(),
                ),
                items: suppliers.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(
                      s == 'all'
                          ? 'جميع الموردين'
                          : s,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplier =
                        value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // الجدول
            // =========================================
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد مشتريات',
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 22,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'المورد',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label:
                                Text('الإجمالي'),
                          ),
                          DataColumn(
                            label:
                                Text('نقدي'),
                          ),
                          DataColumn(
                            label:
                                Text('آجل'),
                          ),
                          DataColumn(
                            label:
                                Text('طلبات'),
                          ),
                          DataColumn(
                            label:
                                Text('الكمية'),
                          ),
                          DataColumn(
                            label:
                                Text('القطع'),
                          ),
                          DataColumn(
                            label:
                                Text('النسبة'),
                          ),
                        ],
                        rows:
                            entries.map((e) {
                          final supplier =
                              e.key;

                          final total =
                              e.value['total']
                                  as double;

                          final cash =
                              e.value['cash']
                                  as double;

                          final credit =
                              e.value['credit']
                                  as double;

                          final ordersCount =
                              e.value['orders']
                                  as int;

                          final quantity =
                              e.value[
                                      'quantity']
                                  as int;

                          final pieces =
                              e.value['pieces']
                                  as int;

                          final percentage =
                              totalPurchases >
                                      0
                                  ? (total /
                                          totalPurchases) *
                                      100
                                  : 0;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(supplier),
                              ),
                              DataCell(
                                Text(
                                  total
                                      .toStringAsFixed(
                                          2),
                                ),
                              ),
                              DataCell(
                                Text(
                                  cash
                                      .toStringAsFixed(
                                          2),
                                ),
                              ),
                              DataCell(
                                Text(
                                  credit
                                      .toStringAsFixed(
                                          2),
                                ),
                              ),
                              DataCell(
                                Text(
                                  ordersCount
                                      .toString(),
                                ),
                              ),
                              DataCell(
                                Text(
                                  quantity
                                      .toString(),
                                ),
                              ),
                              DataCell(
                                Text(
                                  pieces
                                      .toString(),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // بطاقة ملخص
  // =========================================
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding:
            const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, color: color),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}