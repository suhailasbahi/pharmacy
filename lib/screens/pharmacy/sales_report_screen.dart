import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedCompany = 'all'; // للشركة: تصفية حسب الشركة

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isCompany = auth.currentUserType == 'company';
    final orderProvider = Provider.of<OrderProvider>(context);
    
    List<OrderModel> orders = isCompany
        ? orderProvider.getOrdersForCompany(auth.currentCompanyId ?? 'comp_001')
        : orderProvider.getOrdersForPharmacy(auth.currentUserId ?? 'pharmacy_demo_123');
    
    // تصفية حسب التاريخ
    if (_selectedDateRange != null) {
      orders = orders.where((order) =>
          order.date.isAfter(_selectedDateRange!.start) &&
          order.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)))).toList();
    }
    
    // حساب الإجماليات
    final totalSales = orders.fold(0.0, (sum, o) => sum + o.totalPrice);
    final avgOrderValue = orders.isEmpty ? 0 : totalSales / orders.length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المبيعات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _selectDateRange(),
            tooltip: 'تصفية حسب التاريخ',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط الفلترة
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedDateRange == null
                    ? 'كل الفترات'
                    : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'),
                if (_selectedDateRange != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDateRange = null),
                    child: const Text('إلغاء التصفية'),
                  ),
              ],
            ),
          ),
          // بطاقات الإجماليات
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('إجمالي المبيعات', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${totalSales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('متوسط قيمة الطلب', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${avgOrderValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // قائمة الطلبات
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('لا توجد مبيعات في هذه الفترة'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: order.statusColor.withOpacity(0.2),
                            child: Text('${index+1}'),
                          ),
                          title: Text(isCompany ? order.pharmacyName : order.companyName),
                          subtitle: Text('التاريخ: ${_formatDate(order.date)} - ${order.items.length} منتج'),
                          trailing: Text('${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () => _showOrderDetails(order),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }
  
  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تفاصيل الطلب #${order.id.substring(0, 8)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الصيدلية: ${order.pharmacyName}'),
              Text('الشركة: ${order.companyName}'),
              const Divider(),
              const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${item.productName} × ${item.quantity} ${item.unit} - ${item.totalPrice.toStringAsFixed(2)}'),
              )),
              const Divider(),
              Text('الإجمالي: ${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}