import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class CompanyOrdersScreen extends StatefulWidget {
  @override
  State<CompanyOrdersScreen> createState() => _CompanyOrdersScreenState();
}

class _CompanyOrdersScreenState extends State<CompanyOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId ?? 'comp_001';
    final branchId = auth.getEffectiveBranchId();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final orders = await orderProvider.getOrdersForCompany(companyId, branchId: branchId);
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الشراء'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? const Center(child: Text('لا توجد طلبات'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => CompanyOrderCard(
                      order: _orders[index],
                      onStatusChanged: _refresh,
                    ),
                  ),
      ),
    );
  }
}

class CompanyOrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onStatusChanged;
  const CompanyOrderCard({Key? key, required this.order, required this.onStatusChanged}) : super(key: key);

  @override
  State<CompanyOrderCard> createState() => _CompanyOrderCardState();
}

class _CompanyOrderCardState extends State<CompanyOrderCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;  // إضافة منع الضغط المتكرر
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

  Future<void> _acceptOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      await orderProvider.acceptOrder(widget.order.id, accountProvider);
      widget.onStatusChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الطلب'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.rejectOrder(widget.order.id, _rejectReasonController.text, null);
      widget.onStatusChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الطلب'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateShipping() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(widget.order.id, 'shipped');
      widget.onStatusChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد الشحن'), backgroundColor: Colors.purple),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateDelivered() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(widget.order.id, 'delivered');
      widget.onStatusChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسليم الطلب'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    _rejectReasonController.clear();
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
                Navigator.pop(ctx);
                _rejectOrder();
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

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final order = widget.order;
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
                            Text(order.id, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text(order.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('نوع الدفع: ${order.paymentTypeText} - ${order.paymentMethodText}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _getStatusColor(order.status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(_getStatusText(order.status), style: TextStyle(fontSize: 12, color: _getStatusColor(order.status))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('التاريخ: ${_formatDate(order.date)}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${order.items.length} منتجات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${order.totalPrice.toStringAsFixed(2)} جنيه', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.grey),
                    Text(_isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (ctx, idx) {
                      final item = order.items[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.productName} (${item.quantity} ${item.unit == 'carton' ? 'كرتون' : 'باكيت'}) - ${item.quantityInPieces} باكيت', style: const TextStyle(fontSize: 14)),
                            Text('${(item.price * item.quantity).toStringAsFixed(2)} جنيه'),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  if (order.status == 'pending')
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
                  if (order.status == 'accepted' && auth.canShipOrder)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateShipping,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        child: const Text('تأكيد الشحن'),
                      ),
                    ),
                  if (order.status == 'shipped' && auth.canDeliverOrder)
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