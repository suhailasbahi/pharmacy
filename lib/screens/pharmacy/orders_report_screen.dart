import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class OrdersReportScreen extends StatefulWidget {
  const OrdersReportScreen({Key? key}) : super(key: key);

  @override
  State<OrdersReportScreen> createState() => _OrdersReportScreenState();
}

class _OrdersReportScreenState extends State<OrdersReportScreen> {
  String _statusFilter = 'all';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isCompany = auth.currentUserType == 'company';
    final orderProvider = Provider.of<OrderProvider>(context);
    
    List<OrderModel> orders = isCompany
        ? orderProvider.getOrdersForCompany(auth.currentCompanyId ?? 'comp_001')
        : orderProvider.getOrdersForPharmacy(auth.currentUserId ?? 'pharmacy_demo_123');
    
    // تطبيق الفلاتر
    if (_statusFilter != 'all') {
      orders = orders.where((o) => o.status == _statusFilter).toList();
    }
    if (_dateRange != null) {
      orders = orders.where((o) =>
          o.date.isAfter(_dateRange!.start) &&
          o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الطلبات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusFilter != 'all' || _dateRange != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_statusFilter != 'all')
                        Chip(
                          label: Text('الحالة: ${_getStatusText(_statusFilter)}'),
                          onDeleted: () => setState(() => _statusFilter = 'all'),
                        ),
                      if (_dateRange != null)
                        Chip(
                          label: Text('من ${_formatDate(_dateRange!.start)} إلى ${_formatDate(_dateRange!.end)}'),
                          onDeleted: () => setState(() => _dateRange = null),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _statusFilter = 'all';
                      _dateRange = null;
                    }),
                    child: const Text('مسح الكل'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('لا توجد طلبات تطابق المعايير'))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ExpansionTile(
                          title: Text('طلب #${order.id.substring(0, 8)} - ${order.pharmacyName}'),
                          subtitle: Text('التاريخ: ${_formatDate(order.date)} - ${order.totalPrice.toStringAsFixed(2)}'),
                          leading: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: order.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الحالة: ${order.statusText}', style: TextStyle(color: order.statusColor)),
                                  const SizedBox(height: 8),
                                  Text('نوع الدفع: ${order.paymentTypeText} - ${order.paymentMethodText}'),
                                  if (order.creditDays != null) Text('أيام الأجل: ${order.creditDays}'),
                                  const Divider(),
                                  const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...order.items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text('${item.productName} (${item.quantity} ${item.unit}) - ${item.totalPrice.toStringAsFixed(2)}'),
                                  )),
                                  if (order.rejectionReason != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('سبب الرفض: ${order.rejectionReason}', style: const TextStyle(color: Colors.red)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفية الطلبات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('الكل')),
                DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                DropdownMenuItem(value: 'accepted', child: Text('مقبولة')),
                DropdownMenuItem(value: 'shipped', child: Text('تم الشحن')),
                DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
                DropdownMenuItem(value: 'rejected', child: Text('مرفوضة')),
              ],
              onChanged: (value) => setState(() => _statusFilter = value!),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) setState(() => _dateRange = range);
                Navigator.pop(ctx);
              },
              child: const Text('اختر نطاق تاريخ'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد المراجعة';
      case 'accepted': return 'مقبولة';
      case 'rejected': return 'مرفوضة';
      case 'shipped': return 'تم الشحن';
      case 'delivered': return 'تم التسليم';
      default: return status;
    }
  }
  
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}