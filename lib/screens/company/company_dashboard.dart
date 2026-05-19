import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  bool _isLoading = true;

  String _selectedFilter = 'all';
  String _selectedCity = 'all';

  List<OrderModel> _orders = [];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadOrders());
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);

      final auth = Provider.of<AuthService>(context, listen: false);

      final companyId = auth.currentCompanyId;

      if (companyId == null || companyId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final branchId = auth.getEffectiveBranchId();

      final orderProvider =
          Provider.of<OrderProvider>(context, listen: false);

      final orders = await orderProvider.getOrdersForCompany(
        companyId,
        branchId: branchId,
      );

      final citySet = <String>{};

      for (final order in orders) {
        if (order.pharmacyCity.trim().isNotEmpty) {
          citySet.add(order.pharmacyCity);
        }
      }

      if (!mounted) return;

      setState(() {
        _orders = orders;

        _cities = [
          'all',
          ...citySet.toList(),
        ];

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard Error: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحميل البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refresh() async {
    await _loadOrders();
  }

  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      final matchStatus = _selectedFilter == 'all'
          ? true
          : order.status == _selectedFilter;

      final matchCity = _selectedCity == 'all'
          ? true
          : order.pharmacyCity == _selectedCity;

      return matchStatus && matchCity;
    }).toList();
  }

  int get totalOrders => filteredOrders.length;

  double get totalRevenue {
    return filteredOrders.fold(
      0.0,
      (sum, order) => sum + order.totalPrice,
    );
  }

  int _countByStatus(String status) {
    return filteredOrders
        .where((order) => order.status == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [

                  /// الإحصائيات
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [

                        if (auth.canViewSalesReports)
                          _buildStatCard(
                            title: 'إجمالي الطلبات',
                            value: totalOrders.toString(),
                            icon: Icons.shopping_bag,
                            color: Colors.teal,
                          ),

                        if (auth.canViewFinancialReports)
                          _buildStatCard(
                            title: 'الإيرادات',
                            value:
                                '${totalRevenue.toStringAsFixed(2)} جنيه',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),

                        _buildStatCard(
                          title: 'قيد المراجعة',
                          value: _countByStatus('pending').toString(),
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),

                        _buildStatCard(
                          title: 'تم القبول',
                          value: _countByStatus('accepted').toString(),
                          icon: Icons.check,
                          color: Colors.blue,
                        ),

                        _buildStatCard(
                          title: 'تم الشحن',
                          value: _countByStatus('shipped').toString(),
                          icon: Icons.local_shipping,
                          color: Colors.purple,
                        ),

                        _buildStatCard(
                          title: 'تم التسليم',
                          value: _countByStatus('delivered').toString(),
                          icon: Icons.done_all,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  /// الفلاتر
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFilter,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('كل الحالات'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('قيد المراجعة'),
                              ),
                              DropdownMenuItem(
                                value: 'accepted',
                                child: Text('مقبولة'),
                              ),
                              DropdownMenuItem(
                                value: 'shipped',
                                child: Text('مشحونة'),
                              ),
                              DropdownMenuItem(
                                value: 'delivered',
                                child: Text('مكتملة'),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text('مرفوضة'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFilter = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: _cities.map((city) {
                              return DropdownMenuItem(
                                value: city,
                                child: Text(
                                  city == 'all'
                                      ? 'كل المدن'
                                      : city,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// الطلبات
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد طلبات',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              return DashboardOrderCard(
                                order: filteredOrders[index],
                                onStatusChanged: _refresh,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              color: color,
              size: 30,
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
      }
    }
      class DashboardOrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onStatusChanged;

  const DashboardOrderCard({
    Key? key,
    required this.order,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  State<DashboardOrderCard> createState() =>
      _DashboardOrderCardState();
}

class _DashboardOrderCardState
    extends State<DashboardOrderCard> {

  bool _isExpanded = false;

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';

      case 'accepted':
        return 'مقبول';

      case 'shipped':
        return 'تم الشحن';

      case 'delivered':
        return 'تم التسليم';

      case 'rejected':
        return 'مرفوض';

      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'accepted':
        return Colors.blue;

      case 'shipped':
        return Colors.purple;

      case 'delivered':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptOrder() async {
    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);

    final accountProvider =
        Provider.of<AccountProvider>(context, listen: false);

    await orderProvider.acceptOrder(
      widget.order.id,
      accountProvider,
    );

    widget.onStatusChanged();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم قبول الطلب'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);

    await orderProvider.updateOrderStatus(
      widget.order.id,
      status,
    );

    widget.onStatusChanged();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تحديث حالة الطلب'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [

                  Row(
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              '#${widget.order.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              widget.order.pharmacyName,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              widget.order.pharmacyCity,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            widget.order.status,
                          ).withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(
                            widget.order.status,
                          ),
                          style: TextStyle(
                            color: _getStatusColor(
                              widget.order.status,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        '${widget.order.items.length} منتجات',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      Text(
                        '${widget.order.totalPrice.toStringAsFixed(2)} جنيه',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Icon(
                        _isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        _isExpanded
                            ? 'إخفاء التفاصيل'
                            : 'عرض التفاصيل',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'المنتجات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...widget.order.items.map((item) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [

                          Expanded(
                            child: Text(
                              '${item.productName} × ${item.quantity}',
                            ),
                          ),

                          Text(
                            '${(item.price * item.quantity).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(height: 25),

                  if (widget.order.status == 'pending')
                    Row(
                      children: [

                        if (auth.canAcceptOrder)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _acceptOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.teal,
                              ),
                              child: const Text(
                                'قبول الطلب',
                              ),
                            ),
                          ),

                        if (auth.canAcceptOrder)
                          const SizedBox(width: 10),

                        if (auth.canRejectOrder)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _updateStatus(
                                  'rejected',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.red,
                              ),
                              child: const Text(
                                'رفض الطلب',
                              ),
                            ),
                          ),
                      ],
                    ),

                  if (widget.order.status == 'accepted')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateStatus('shipped');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.purple,
                        ),
                        child: const Text(
                          'تأكيد الشحن',
                        ),
                      ),
                    ),

                  if (widget.order.status == 'shipped')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateStatus('delivered');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green,
                        ),
                        child: const Text(
                          'تأكيد التسليم',
                        ),
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
  