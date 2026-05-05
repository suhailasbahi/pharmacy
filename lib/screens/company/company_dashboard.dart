import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class CompanyDashboard extends StatefulWidget {
  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  String _selectedFilter = 'all';
  String _selectedCity = 'all';
  
  List<String> get availableCities {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final companyId = Provider.of<AuthService>(context, listen: false).currentCompanyId ?? 'comp_001';
    final orders = orderProvider.getOrdersForCompany(companyId);
    final cities = orders.map((o) => o.pharmacyCity).toSet().toList();
    return ['all', ...cities];
  }

  List<OrderModel> get filteredOrders {
    final orderProvider = Provider.of<OrderProvider>(context);
    final companyId = Provider.of<AuthService>(context, listen: false).currentCompanyId ?? 'comp_001';
    var companyOrders = orderProvider.getOrdersForCompany(companyId);
    return companyOrders.where((order) {
      if (_selectedFilter != 'all' && order.status != _selectedFilter) return false;
      if (_selectedCity != 'all' && order.pharmacyCity != _selectedCity) return false;
      return true;
    }).toList();
  }

  int get totalOrders => filteredOrders.length;
  double get totalRevenue => filteredOrders.fold(0.0, (sum, order) => sum + order.totalPrice);
  int get pendingCount => filteredOrders.where((o) => o.status == 'pending').length;
  int get acceptedCount => filteredOrders.where((o) => o.status == 'accepted').length;
  int get shippedCount => filteredOrders.where((o) => o.status == 'shipped').length;
  int get deliveredCount => filteredOrders.where((o) => o.status == 'delivered').length;
  int get rejectedCount => filteredOrders.where((o) => o.status == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final orders = filteredOrders;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    if (auth.canViewAllReports || auth.canViewSalesReports)
                      _buildStatCard('إجمالي الطلبات', totalOrders.toString(), Icons.shopping_bag, Colors.teal),
                    if (auth.canViewFinancialReports)
                      _buildStatCard('الإيرادات', '${totalRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                    if (auth.canViewSalesReports)
                      _buildStatCard('قيد المراجعة', pendingCount.toString(), Icons.hourglass_empty, Colors.orange),
                    if (auth.canViewInventoryReports)
                      _buildStatCard('تم الشحن', shippedCount.toString(), Icons.local_shipping, Colors.purple),
                    if (auth.canViewSalesReports)
                      _buildStatCard('تم التسليم', deliveredCount.toString(), Icons.check_circle, Colors.green),
                    if (auth.canViewSalesReports)
                      _buildStatCard('مرفوض', rejectedCount.toString(), Icons.cancel, Colors.red),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('جميع الطلبات')),
                              DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                              DropdownMenuItem(value: 'accepted', child: Text('مقبولة')),
                              DropdownMenuItem(value: 'shipped', child: Text('تم الشحن')),
                              DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
                              DropdownMenuItem(value: 'rejected', child: Text('مرفوضة')),
                            ],
                            onChanged: (value) => setState(() => _selectedFilter = value!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCity,
                            isExpanded: true,
                            items: availableCities.map((city) {
                              return DropdownMenuItem(
                                value: city,
                                child: Text(city == 'all' ? 'جميع المدن' : city),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCity = value!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: orders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('لا توجد طلبات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (context, index) => DashboardOrderCard(order: orders[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class DashboardOrderCard extends StatefulWidget {
  final OrderModel order;
  const DashboardOrderCard({Key? key, required this.order}) : super(key: key);
  @override
  State<DashboardOrderCard> createState() => _DashboardOrderCardState();
}

class _DashboardOrderCardState extends State<DashboardOrderCard> {
  bool _isExpanded = false;
  final TextEditingController _rejectReasonController = TextEditingController();

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد المراجعة';
      case 'accepted': return 'تم القبول';
      case 'rejected': return 'مرفوض';
      case 'shipped': return 'تم الشحن';
      case 'delivered': return 'تم التسليم';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _acceptOrder() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    orderProvider.acceptOrder(widget.order.id, accountProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم قبول الطلب'), backgroundColor: Colors.green),
    );
  }

  void _rejectOrder() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.rejectOrder(widget.order.id, _rejectReasonController.text, null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفض الطلب'), backgroundColor: Colors.red),
    );
  }

  void _updateShipping() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.updateOrderStatus(widget.order.id, 'shipped');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تأكيد الشحن'), backgroundColor: Colors.purple),
    );
  }

  void _updateDelivered() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.updateOrderStatus(widget.order.id, 'delivered');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسليم الطلب'), backgroundColor: Colors.green),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى كتابة سبب الرفض:'),
            const SizedBox(height: 16),
            TextField(controller: _rejectReasonController, decoration: const InputDecoration(hintText: 'مثال: المنتج غير متوفر'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_rejectReasonController.text.isNotEmpty) {
                _rejectOrder();
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى كتابة سبب الرفض'), backgroundColor: Colors.orange),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${widget.order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('صيدلية: ${widget.order.pharmacyName}', style: const TextStyle(fontSize: 12)),
                            Text('المدينة: ${widget.order.pharmacyCity}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('نوع الدفع: ${widget.order.paymentTypeText} - ${widget.order.paymentMethodText}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(widget.order.status),
                          style: TextStyle(fontSize: 12, color: _getStatusColor(widget.order.status)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.order.items.length} منتجات', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${widget.order.totalPrice.toStringAsFixed(2)} جنيه',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.grey),
                      Text(
                        _isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.order.items.length,
                    itemBuilder: (ctx, idx) {
                      final item = widget.order.items[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.productName} (${item.quantity} ${item.unit == 'carton' ? 'كرتون' : 'باكيت'}) - ${item.quantityInPieces} باكيت',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text('${(item.price * item.quantity).toStringAsFixed(2)} جنيه'),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  if (widget.order.status == 'pending')
                    Row(
                      children: [
                        if (auth.canRejectOrder)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _showRejectDialog,
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                              child: const Text('رفض', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        if (auth.canRejectOrder && auth.canAcceptOrder) const SizedBox(width: 8),
                        if (auth.canAcceptOrder)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _acceptOrder,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              child: const Text('قبول'),
                            ),
                          ),
                      ],
                    ),
                  if (widget.order.status == 'accepted' && auth.canShipOrder)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateShipping,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        child: const Text('تأكيد الشحن'),
                      ),
                    ),
                  if (widget.order.status == 'shipped' && auth.canDeliverOrder)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateDelivered,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('تسليم الطلب'),
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