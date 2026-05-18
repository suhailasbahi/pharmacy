import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class OrdersReportScreen extends StatefulWidget {
  const OrdersReportScreen({Key? key}) : super(key: key);

  @override
  State<OrdersReportScreen> createState() =>
      _OrdersReportScreenState();
}

class _OrdersReportScreenState
    extends State<OrdersReportScreen> {

  String _statusFilter = 'all';

  DateTimeRange? _dateRange;

  String _sortBy = 'date';

  bool _isLoading = true;

  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
    if (_dateRange != null) {

      orders = orders.where((order) {

        return order.date.isAfter(
                  _dateRange!.start
                      .subtract(const Duration(days: 1)),
                ) &&
                order.date.isBefore(
                  _dateRange!.end
                      .add(const Duration(days: 1)),
                );

      }).toList();
    }

    // =========================
    // فلترة الحالة
    // =========================
    if (_statusFilter != 'all') {

      orders = orders.where(
        (o) => o.status == _statusFilter,
      ).toList();
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

      case 'status':

        orders.sort(
          (a, b) => a.status.compareTo(b.status),
        );

        break;

      case 'date':

      default:

        orders.sort(
          (a, b) => b.date.compareTo(a.date),
        );
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

      initialDateRange: _dateRange,
    );

    if (picked != null) {

      setState(() {
        _dateRange = picked;
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
    final totalOrders = _orders.length;

    final totalAmount = _orders.fold(
      0.0,
      (sum, order) => sum + order.totalPrice,
    );

    final pendingOrders = _orders
        .where((o) => o.status == 'pending')
        .length;

    final acceptedOrders = _orders
        .where((o) => o.status == 'accepted')
        .length;

    final deliveredOrders = _orders
        .where((o) => o.status == 'delivered')
        .length;

    final rejectedOrders = _orders
        .where((o) => o.status == 'rejected')
        .length;

    if (_isLoading) {

      return Scaffold(

        appBar: AppBar(
          title: const Text('تقرير الطلبات'),
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

        title: const Text('تقرير الطلبات'),

        centerTitle: true,

        backgroundColor: Colors.teal,

        actions: [

          // =========================
          // التاريخ
          // =========================
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),

          // =========================
          // الفلاتر
          // =========================
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
                value: 'pending',
                child: Text('قيد المراجعة'),
              ),

              const PopupMenuItem(
                value: 'accepted',
                child: Text('مقبولة'),
              ),

              const PopupMenuItem(
                value: 'shipped',
                child: Text('تم الشحن'),
              ),

              const PopupMenuItem(
                value: 'delivered',
                child: Text('تم التسليم'),
              ),

              const PopupMenuItem(
                value: 'rejected',
                child: Text('مرفوضة'),
              ),
            ],
          ),

          // =========================
          // الترتيب
          // =========================
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

              const PopupMenuItem(
                value: 'status',
                child: Text('ترتيب بالحالة'),
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
            // الفلاتر الحالية
            // =========================
            if (_dateRange != null ||
                _statusFilter != 'all')

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(10),

                color: Colors.grey.shade100,

                child: Wrap(

                  spacing: 8,
                  runSpacing: 8,

                  children: [

                    if (_dateRange != null)

                      Chip(
                        label: Text(
                          '${_formatDate(_dateRange!.start)}'
                          ' - '
                          '${_formatDate(_dateRange!.end)}',
                        ),

                        onDeleted: () async {

                          setState(() {
                            _dateRange = null;
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

                    ActionChip(
                      label: const Text('مسح الكل'),

                      onPressed: () async {

                        setState(() {

                          _dateRange = null;
                          _statusFilter = 'all';
                        });

                        await _loadData();
                      },
                    ),
                  ],
                ),
              ),

            // =========================
            // الإحصائيات
            // =========================
            Padding(

              padding: const EdgeInsets.all(12),

              child: GridView.count(

                crossAxisCount: 2,

                shrinkWrap: true,

                physics:
                    const NeverScrollableScrollPhysics(),

                mainAxisSpacing: 10,
                crossAxisSpacing: 10,

                childAspectRatio: 1.5,

                children: [

                  _buildStatCard(
                    'إجمالي الطلبات',
                    totalOrders.toString(),
                    Colors.teal,
                    Icons.shopping_bag,
                  ),

                  _buildStatCard(
                    'إجمالي المبلغ',
                    totalAmount.toStringAsFixed(2),
                    Colors.green,
                    Icons.attach_money,
                  ),

                  _buildStatCard(
                    'قيد المراجعة',
                    pendingOrders.toString(),
                    Colors.orange,
                    Icons.pending_actions,
                  ),

                  _buildStatCard(
                    'مقبولة',
                    acceptedOrders.toString(),
                    Colors.blue,
                    Icons.check_circle,
                  ),

                  _buildStatCard(
                    'تم التسليم',
                    deliveredOrders.toString(),
                    Colors.green,
                    Icons.local_shipping,
                  ),

                  _buildStatCard(
                    'مرفوضة',
                    rejectedOrders.toString(),
                    Colors.red,
                    Icons.cancel,
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
                        'لا توجد طلبات',
                      ),
                    )

                  : ListView.builder(

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      itemCount: _orders.length,

                      itemBuilder: (context, index) {

                        final order = _orders[index];

                        return Card(

                          elevation: 2,

                          margin:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),

                          child: InkWell(

                            borderRadius:
                                BorderRadius.circular(16),

                            onTap: () =>
                                _showOrderDetails(order),

                            child: Padding(

                              padding:
                                  const EdgeInsets.all(14),

                              child: Column(

                                children: [

                                  Row(

                                    children: [

                                      CircleAvatar(
                                        backgroundColor:
                                            order.statusColor
                                                .withOpacity(
                                                    0.15),

                                        child: Icon(
                                          Icons.receipt_long,
                                          color:
                                              order.statusColor,
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

                                              isCompany
                                                  ? order
                                                      .pharmacyName
                                                  : order
                                                      .companyName,

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
                                              'طلب #${order.id.substring(0, 8)}',
                                              style:
                                                  TextStyle(
                                                color: Colors
                                                    .grey
                                                    .shade600,
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
                                          color: order
                                              .statusColor
                                              .withOpacity(
                                                  0.12),

                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      20),
                                        ),

                                        child: Text(
                                          order.statusText,

                                          style: TextStyle(
                                            color: order
                                                .statusColor,

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
                                            .spaceBetween,

                                    children: [

                                      _buildInfoItem(
                                        Icons.calendar_today,
                                        _formatDate(
                                            order.date),
                                      ),

                                      _buildInfoItem(
                                        Icons.inventory_2,
                                        '${order.items.length} منتج',
                                      ),

                                      _buildInfoItem(
                                        order.paymentType ==
                                                'cash'
                                            ? Icons.money
                                            : Icons.credit_card,

                                        order.paymentTypeText,
                                      ),
                                    ],
                                  ),

                                  const Divider(
                                      height: 24),

                                  Row(

                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,

                                    children: [

                                      Text(
                                        'الإجمالي',

                                        style: TextStyle(
                                          color: Colors
                                              .grey.shade700,
                                        ),
                                      ),

                                      Text(
                                        order.totalPrice
                                            .toStringAsFixed(
                                                2),

                                        style:
                                            const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {

    return Card(

      color: color.withOpacity(0.08),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: Padding(

        padding: const EdgeInsets.all(12),

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              color: color,
            ),

            const SizedBox(height: 6),

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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String text,
  ) {

    return Row(

      children: [

        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 4),

        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ],
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

                const Text(
                  'تفاصيل الطلب',

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

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
                  'المدينة',
                  order.pharmacyCity,
                ),

                _buildDetailRow(
                  'الحالة',
                  order.statusText,
                ),

                _buildDetailRow(
                  'طريقة الدفع',
                  order.paymentTypeText,
                ),

                _buildDetailRow(
                  'وسيلة الدفع',
                  order.paymentMethodText,
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
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 10),

                ...order.items.map((item) {

                  return Card(

                    child: ListTile(

                      title: Text(item.productName),

                      subtitle: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(
                            item.scientificName,
                          ),

                          Text(
                            '${item.quantity} ${item.unit}',
                          ),
                        ],
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
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.teal,
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

      padding:
          const EdgeInsets.symmetric(vertical: 6),

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

      case 'pending':
        return 'قيد المراجعة';

      case 'accepted':
        return 'مقبولة';

      case 'shipped':
        return 'تم الشحن';

      case 'delivered':
        return 'تم التسليم';

      case 'rejected':
        return 'مرفوضة';

      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {

    return '${date.day}/${date.month}/${date.year}';
  }
}