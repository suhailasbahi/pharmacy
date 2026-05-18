import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  State<SalesReportScreen> createState() =>
      _SalesReportScreenState();
}

class _SalesReportScreenState
    extends State<SalesReportScreen> {

  DateTimeRange? _selectedDateRange;

  List<OrderModel> _orders = [];

  bool _isLoading = true;

  String _statusFilter = 'all';

  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _isCompletedOrder(OrderModel order) {
    return order.status == 'accepted' ||
        order.status == 'shipped' ||
        order.status == 'delivered';
  }

  Future<void> _loadData() async {

    setState(() => _isLoading = true);

    final auth =
        Provider.of<AuthService>(context, listen: false);

    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);

    final bool isCompany =
        auth.currentUserType == 'company';

    List<OrderModel> orders;

    if (isCompany) {
      orders = await orderProvider.getOrdersForCompany(
        auth.currentCompanyId ?? '',
      );
    } else {
      orders = await orderProvider.getOrdersForPharmacy(
        auth.currentUserId ?? '',
      );
    }

    // =========================
    // فلترة التاريخ
    // =========================
    if (_selectedDateRange != null) {
      orders = orders.where((order) {

        return order.date.isAfter(
                  _selectedDateRange!.start
                      .subtract(const Duration(days: 1)),
                ) &&
                order.date.isBefore(
                  _selectedDateRange!.end
                      .add(const Duration(days: 1)),
                );

      }).toList();
    }

    // =========================
    // فلترة الحالة
    // =========================
    if (_statusFilter != 'all') {

      if (_statusFilter == 'completed') {

        orders = orders
            .where(_isCompletedOrder)
            .toList();

      } else {

        orders = orders
            .where((o) => o.status == _statusFilter)
            .toList();
      }
    }

    // =========================
    // الترتيب
    // =========================
    switch (_sortBy) {

      case 'price':

        orders.sort(
          (a, b) =>
              b.totalPrice.compareTo(a.totalPrice),
        );

        break;

      case 'date':

        orders.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        break;
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
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {

      setState(() {
        _selectedDateRange = picked;
      });

      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {

    final auth = Provider.of<AuthService>(context);

    final bool isCompany =
        auth.currentUserType == 'company';

    // =========================
    // الإحصائيات
    // =========================
    final completedOrders =
        _orders.where(_isCompletedOrder).toList();

    final totalSales = completedOrders.fold(
      0.0,
      (sum, order) => sum + order.totalPrice,
    );

    final avgOrderValue =
        completedOrders.isEmpty
            ? 0
            : totalSales / completedOrders.length;

    final cashSales = completedOrders
        .where((o) => o.paymentType == 'cash')
        .fold(
          0.0,
          (sum, o) => sum + o.totalPrice,
        );

    final creditSales = completedOrders
        .where((o) => o.paymentType == 'credit')
        .fold(
          0.0,
          (sum, o) => sum + o.totalPrice,
        );

    if (_isLoading) {

      return Scaffold(
        appBar: AppBar(
          title: const Text('تقرير المبيعات'),
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
        title: const Text('تقرير المبيعات'),
        centerTitle: true,
        backgroundColor: Colors.teal,

        actions: [

          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),

          PopupMenuButton<String>(

            icon: const Icon(Icons.filter_list),

            onSelected: (value) async {

              setState(() {
                _statusFilter = value;
              });

              await _loadData();
            },

            itemBuilder: (_) => [

              const PopupMenuItem(
                value: 'all',
                child: Text('كل الطلبات'),
              ),

              const PopupMenuItem(
                value: 'completed',
                child: Text('الطلبات المكتملة'),
              ),

              const PopupMenuItem(
                value: 'pending',
                child: Text('قيد المراجعة'),
              ),

              const PopupMenuItem(
                value: 'rejected',
                child: Text('المرفوضة'),
              ),
            ],
          ),

          PopupMenuButton<String>(

            icon: const Icon(Icons.sort),

            onSelected: (value) async {

              setState(() {
                _sortBy = value;
              });

              await _loadData();
            },

            itemBuilder: (_) => [

              const PopupMenuItem(
                value: 'date',
                child: Text('ترتيب بالتاريخ'),
              ),

              const PopupMenuItem(
                value: 'price',
                child: Text('ترتيب بالقيمة'),
              ),
            ],
          ),
        ],
      ),

      body: RefreshIndicator(

        onRefresh: _refresh,

        child: Column(

          children: [

            // =========================
            // شريط الفلاتر
            // =========================
            if (_selectedDateRange != null ||
                _statusFilter != 'all')

              Container(

                padding: const EdgeInsets.all(10),

                color: Colors.grey.shade100,

                child: Row(

                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    Expanded(

                      child: Wrap(

                        spacing: 8,

                        runSpacing: 8,

                        children: [

                          if (_selectedDateRange != null)

                            Chip(
                              label: Text(
                                '${_formatDate(_selectedDateRange!.start)}'
                                ' - '
                                '${_formatDate(_selectedDateRange!.end)}',
                              ),

                              onDeleted: () async {

                                setState(() {
                                  _selectedDateRange = null;
                                });

                                await _loadData();
                              },
                            ),

                          if (_statusFilter != 'all')

                            Chip(
                              label: Text(
                                _getStatusText(_statusFilter),
                              ),

                              onDeleted: () async {

                                setState(() {
                                  _statusFilter = 'all';
                                });

                                await _loadData();
                              },
                            ),
                        ],
                      ),
                    ),

                    TextButton(
                      onPressed: () async {

                        setState(() {

                          _selectedDateRange = null;
                          _statusFilter = 'all';
                        });

                        await _loadData();
                      },

                      child: const Text('مسح'),
                    ),
                  ],
                ),
              ),

            // =========================
            // الإحصائيات
            // =========================
            Padding(

              padding: const EdgeInsets.all(12),

              child: Column(

                children: [

                  Row(

                    children: [

                      Expanded(
                        child: _buildStatCard(
                          'إجمالي المبيعات',
                          totalSales.toStringAsFixed(2),
                          Colors.teal,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildStatCard(
                          'متوسط الطلب',
                          avgOrderValue.toStringAsFixed(2),
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(

                    children: [

                      Expanded(
                        child: _buildStatCard(
                          'نقدي',
                          cashSales.toStringAsFixed(2),
                          Colors.green,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildStatCard(
                          'آجل',
                          creditSales.toStringAsFixed(2),
                          Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =========================
            // قائمة الطلبات
            // =========================
            Expanded(

              child: _orders.isEmpty

                  ? const Center(
                      child: Text(
                        'لا توجد بيانات',
                      ),
                    )

                  : ListView.builder(

                      padding: const EdgeInsets.all(8),

                      itemCount: _orders.length,

                      itemBuilder: (context, index) {

                        final order = _orders[index];

                        return Card(

                          elevation: 2,

                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),

                          child: ListTile(

                            contentPadding:
                                const EdgeInsets.all(12),

                            leading: CircleAvatar(
                              backgroundColor:
                                  order.statusColor
                                      .withOpacity(0.15),

                              child: Icon(
                                Icons.receipt_long,
                                color: order.statusColor,
                              ),
                            ),

                            title: Text(
                              isCompany
                                  ? order.pharmacyName
                                  : order.companyName,

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                const SizedBox(height: 6),

                                Text(
                                  'التاريخ: '
                                  '${_formatDate(order.date)}',
                                ),

                                Text(
                                  'الحالة: '
                                  '${order.statusText}',
                                  style: TextStyle(
                                    color: order.statusColor,
                                  ),
                                ),

                                Text(
                                  'الدفع: '
                                  '${order.paymentTypeText}',
                                ),

                                Text(
                                  '${order.items.length} منتج',
                                ),
                              ],
                            ),

                            trailing: Column(

                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              children: [

                                Text(
                                  order.totalPrice
                                      .toStringAsFixed(2),

                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                ),
                              ],
                            ),

                            onTap: () =>
                                _showOrderDetails(order),
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

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
  ) {

    return Card(

      color: color.withOpacity(0.08),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: Padding(

        padding: const EdgeInsets.all(14),

        child: Column(

          children: [

            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (_) {

        return Padding(

          padding: const EdgeInsets.all(20),

          child: SingleChildScrollView(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'تفاصيل الطلب',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 16),

                _buildDetailRow(
                  'رقم الطلب',
                  order.id.substring(0, 8),
                ),

                _buildDetailRow(
                  'الصيدلية',
                  order.pharmacyName,
                ),

                _buildDetailRow(
                  'الشركة',
                  order.companyName,
                ),

                _buildDetailRow(
                  'الحالة',
                  order.statusText,
                ),

                _buildDetailRow(
                  'طريقة الدفع',
                  order.paymentTypeText,
                ),

                if (order.creditDays != null)

                  _buildDetailRow(
                    'مدة الأجل',
                    '${order.creditDays} يوم',
                  ),

                const SizedBox(height: 20),

                const Text(
                  'المنتجات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                ...order.items.map((item) {

                  return Card(

                    child: ListTile(

                      title: Text(item.productName),

                      subtitle: Text(
                        '${item.quantity} ${item.unit}',
                      ),

                      trailing: Text(
                        item.totalPrice
                            .toStringAsFixed(2),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                Align(

                  alignment: Alignment.centerRight,

                  child: Text(

                    'الإجمالي: '
                    '${order.totalPrice.toStringAsFixed(2)}',

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String title,
    String value,
  ) {

    return Padding(

      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),

      child: Row(

        children: [

          Text(
            '$title : ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {

    switch (status) {

      case 'completed':
        return 'الطلبات المكتملة';

      case 'pending':
        return 'قيد المراجعة';

      case 'rejected':
        return 'المرفوضة';

      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {

    return '${date.day}/${date.month}/${date.year}';
  }
}