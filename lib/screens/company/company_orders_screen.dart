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
  @override
  Widget build(BuildContext context) {
    final companyId = Provider.of<AuthService>(context).currentCompanyId ?? 'comp_001';
    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات الشراء'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final orders = orderProvider.getOrdersForCompany(companyId);
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد طلبات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) => CompanyOrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class CompanyOrderCard extends StatefulWidget {
  final OrderModel order;
  const CompanyOrderCard({Key? key, required this.order}) : super(key: key);
  @override
  State<CompanyOrderCard> createState() => _CompanyOrderCardState();
}

class _CompanyOrderCardState extends State<CompanyOrderCard> {
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
      SnackBar(content: Text('تم قبول الطلب'), backgroundColor: Colors.green),
    );
  }

  void _rejectOrder() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.rejectOrder(widget.order.id, _rejectReasonController.text, null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم رفض الطلب'), backgroundColor: Colors.red),
    );
  }

  void _showRejectDialog() {
    _rejectReasonController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('رفض الطلب', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('يرجى كتابة سبب الرفض:'),
            SizedBox(height: 16),
            TextField(controller: _rejectReasonController, decoration: InputDecoration(hintText: 'مثال: المنتج غير متوفر'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_rejectReasonController.text.isNotEmpty) {
                _rejectOrder();
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى كتابة سبب الرفض'), backgroundColor: Colors.orange));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
  }

  void _updateShipping() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.updateOrderStatus(widget.order.id, 'shipped');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تأكيد الشحن'), backgroundColor: Colors.purple),
    );
  }

  void _updateDelivered() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.updateOrderStatus(widget.order.id, 'delivered');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تسليم الطلب'), backgroundColor: Colors.green),
    );
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.all(16),
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
                            SizedBox(height: 4),
                            Text(order.pharmacyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('نوع الدفع: ${order.paymentTypeText} - ${order.paymentMethodText}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _getStatusColor(order.status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(_getStatusText(order.status), style: TextStyle(fontSize: 12, color: _getStatusColor(order.status))),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('التاريخ: ${_formatDate(order.date)}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${order.items.length} منتجات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${order.totalPrice.toStringAsFixed(2)} جنيه', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  SizedBox(height: 8),
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (ctx, idx) {
                      final item = order.items[idx];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.productName} (${item.quantity} ${item.unit == 'carton' ? 'كرتون' : 'باكيت'}) - ${item.quantityInPieces} باكيت', style: TextStyle(fontSize: 14)),
                            Text('${(item.price * item.quantity).toStringAsFixed(2)} جنيه'),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(),
                  if (order.status == 'pending')
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _showRejectDialog, style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red)), child: Text('رفض', style: TextStyle(color: Colors.red)))),
                        SizedBox(width: 8),
                        Expanded(child: ElevatedButton(onPressed: _acceptOrder, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), child: Text('قبول'))),
                      ],
                    ),
                  if (order.status == 'accepted')
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _updateShipping, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), child: Text('تأكيد الشحن'))),
                  if (order.status == 'shipped')
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _updateDelivered, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text('تسليم الطلب'))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}