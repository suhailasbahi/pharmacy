import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import 'sales_report_screen.dart';
import 'orders_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isCompany = auth.currentUserType == 'company';
    final orderProvider = Provider.of<OrderProvider>(context);
    
    final orders = isCompany
        ? orderProvider.getOrdersForCompany(auth.currentCompanyId ?? 'comp_001')
        : orderProvider.getOrdersForPharmacy(auth.currentUserId ?? 'pharmacy_demo_123');
    
    final totalOrders = orders.length;
    final totalSpent = orders.fold(0.0, (sum, o) => sum + o.totalPrice);
    final pendingOrders = orders.where((o) => o.status == 'pending').length;
    final deliveredOrders = orders.where((o) => o.status == 'delivered').length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('ملخص سريع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('إجمالي الطلبات', totalOrders.toString(), Icons.shopping_bag, Colors.teal),
                        _buildStatCard('إجمالي المبلغ', '${totalSpent.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('قيد التنفيذ', pendingOrders.toString(), Icons.pending, Colors.orange),
                        _buildStatCard('مكتملة', deliveredOrders.toString(), Icons.check_circle, Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('تقارير متقدمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.teal),
              title: const Text('تقرير المبيعات'),
              subtitle: const Text('عرض المبيعات حسب الفترة'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesReportScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.teal),
              title: const Text('تقرير الطلبات'),
              subtitle: const Text('عرض وتصفية الطلبات'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersReportScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 120,
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}