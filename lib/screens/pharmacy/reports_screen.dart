import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

import 'sales_report_screen.dart';
import 'orders_report_screen.dart';
import '../../screens/company/top_products_screen.dart';
import 'pharmacy_detailed_reports_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  bool _isCompletedOrder(OrderModel order) {
    return order.status == 'accepted' ||
        order.status == 'shipped' ||
        order.status == 'delivered';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    final bool isCompany = auth.currentUserType == 'company';

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),

      body: FutureBuilder<List<OrderModel>>(
        future: isCompany
            ? orderProvider.getOrdersForCompany(
                auth.currentCompanyId ?? '',
              )
            : orderProvider.getOrdersForPharmacy(
                auth.currentUserId ?? '',
              ),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('حدث خطأ أثناء تحميل التقارير'),
            );
          }

          final orders = snapshot.data ?? [];

          // =========================
          // الطلبات المكتملة فقط
          // =========================
          final completedOrders =
              orders.where(_isCompletedOrder).toList();

          final totalOrders = orders.length;

          final totalSales = completedOrders.fold(
            0.0,
            (sum, order) => sum + order.totalPrice,
          );

          final pendingOrders = orders
              .where((o) => o.status == 'pending')
              .length;

          final deliveredOrders = orders
              .where((o) => o.status == 'delivered')
              .length;

          final rejectedOrders = orders
              .where((o) => o.status == 'rejected')
              .length;

          final cashOrders = completedOrders
              .where((o) => o.paymentType == 'cash')
              .length;

          final creditOrders = completedOrders
              .where((o) => o.paymentType == 'credit')
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              (context as Element).markNeedsBuild();
            },

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // =========================
                  // عنوان
                  // =========================
                  Text(
                    isCompany
                        ? 'تقارير الشركة'
                        : 'تقارير الصيدلية',

                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // الإحصائيات الرئيسية
                  // =========================
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,

                    children: [

                      _buildStatCard(
                        title: 'إجمالي الطلبات',
                        value: totalOrders.toString(),
                        icon: Icons.shopping_bag,
                        color: Colors.teal,
                      ),

                      _buildStatCard(
                        title: isCompany
                            ? 'إجمالي المبيعات'
                            : 'إجمالي المشتريات',

                        value: totalSales.toStringAsFixed(2),

                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),

                      _buildStatCard(
                        title: 'طلبات معلقة',
                        value: pendingOrders.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),

                      _buildStatCard(
                        title: 'طلبات مكتملة',
                        value: deliveredOrders.toString(),
                        icon: Icons.check_circle,
                        color: Colors.blue,
                      ),

                      _buildStatCard(
                        title: 'طلبات مرفوضة',
                        value: rejectedOrders.toString(),
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),

                      _buildStatCard(
                        title: 'طلبات نقدي',
                        value: cashOrders.toString(),
                        icon: Icons.payments,
                        color: Colors.green,
                      ),

                      _buildStatCard(
                        title: 'طلبات آجل',
                        value: creditOrders.toString(),
                        icon: Icons.credit_card,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // التقارير الأساسية
                  // =========================
                  const Text(
                    'التقارير الأساسية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildReportTile(
                    context,
                    icon: Icons.bar_chart,
                    color: Colors.teal,
                    title: 'تقرير المبيعات',
                    subtitle: 'عرض المبيعات حسب الفترات',
                    screen: const SalesReportScreen(),
                  ),

                  _buildReportTile(
                    context,
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    title: 'تقرير الطلبات',
                    subtitle: 'عرض جميع الطلبات مع التصفية',
                    screen: const OrdersReportScreen(),
                  ),

                  // =========================
                  // تقارير الشركة
                  // =========================
                  if (isCompany) ...[

                    const SizedBox(height: 24),

                    const Text(
                      'تقارير الشركة التفصيلية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildReportTile(
                      context,
                      icon: Icons.local_fire_department,
                      color: Colors.deepOrange,
                      title: 'أكثر المنتجات مبيعاً',
                      subtitle: 'تحليل المنتجات الأعلى مبيعاً',
                      screen: const TopProductsScreen(),
                    ),
                  ],

                  // =========================
                  // تقارير الصيدلية
                  // =========================
                  if (!isCompany) ...[

                    const SizedBox(height: 24),

                    const Text(
                      'التقارير التفصيلية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildReportTile(
                      context,
                      icon: Icons.analytics,
                      color: Colors.purple,
                      title: 'التقارير التفصيلية',
                      subtitle:
                          'تحليل المشتريات والموردين والأصناف',
                      screen:
                          const PharmacyDetailedReportsScreen(),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
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
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              value,
              style: TextStyle(
                fontSize: 22,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {

    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => screen,
            ),
          );
        },
      ),
    );
  }
}