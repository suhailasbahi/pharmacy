import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class MyOrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pharmacyId = Provider.of<AuthService>(context).currentUserId ?? 'pharmacy_demo_123';
    return Scaffold(
      appBar: AppBar(title: Text('طلباتي'), centerTitle: true, backgroundColor: Colors.teal),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final orders = orderProvider.getOrdersForPharmacy(pharmacyId);
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد طلبات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('قم بإتمام طلب من السلة', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) => OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  final OrderModel order;
  const OrderCard({Key? key, required this.order}) : super(key: key);
  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isExpanded = false;

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

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
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
                            Text('#${widget.order.id.substring(0, 8)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                            SizedBox(height: 4),
                            Text(widget.order.companyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('صيدلية: ${widget.order.pharmacyName}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('نوع الدفع: ${widget.order.paymentTypeText} - ${widget.order.paymentMethodText}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _getStatusColor(widget.order.status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(_getStatusText(widget.order.status), style: TextStyle(fontSize: 12, color: _getStatusColor(widget.order.status))),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('التاريخ: ${_formatDate(widget.order.date)}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${widget.order.items.length} منتجات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${widget.order.totalPrice.toStringAsFixed(2)} جنيه', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.grey),
                      Text(_isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.order.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.productName} × ${item.quantity} ${item.unit == 'carton' ? 'كرتون' : 'باكيت'} (${item.quantityInPieces} باكيت)', style: TextStyle(fontSize: 14)),
                            Text('${(item.price * item.quantity).toStringAsFixed(2)} جنيه'),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.order.totalPrice.toStringAsFixed(2)} جنيه', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  if (widget.order.status == 'rejected' && widget.order.rejectionReason != null)
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('سبب الرفض:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          SizedBox(height: 4),
                          Text(widget.order.rejectionReason!),
                        ],
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