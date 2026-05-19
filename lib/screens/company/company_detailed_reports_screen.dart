import 'package:flutter/material.dart';

import 'top_products_screen.dart';
import 'sales_trend_screen.dart';
import 'sales_by_region_screen.dart';
import 'cash_credit_sales_screen.dart';
import 'performance_dashboard_screen.dart';

class CompanyDetailedReportsScreen extends StatelessWidget {
  const CompanyDetailedReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير التفصيلية'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          // =========================
          // لوحة الأداء
          // =========================

          _buildReportCard(
            context: context,
            title: 'لوحة الأداء',
            subtitle:
            'تحليل الأداء العام والمبيعات والعملاء',
            icon: Icons.dashboard,
            color: Colors.indigo,
            screen: const PerformanceDashboardScreen(),
          ),

          // =========================
          // أكثر المنتجات مبيعاً
          // =========================

          _buildReportCard(
            context: context,
            title: 'أكثر المنتجات مبيعاً',
            subtitle:
            'تحليل المنتجات الأعلى مبيعاً حسب الكمية والقيمة',
            icon: Icons.local_fire_department,
            color: Colors.deepOrange,
            screen: const TopProductsScreen(),
          ),

          // =========================
          // اتجاه المبيعات
          // =========================

          _buildReportCard(
            context: context,
            title: 'اتجاه المبيعات',
            subtitle:
            'تحليل تطور المبيعات حسب الأيام والشهور',
            icon: Icons.show_chart,
            color: Colors.green,
            screen: const SalesTrendScreen(),
          ),

          // =========================
          // المبيعات حسب المناطق
          // =========================

          _buildReportCard(
            context: context,
            title: 'المبيعات حسب المناطق',
            subtitle:
            'عرض أفضل المحافظات والمدن في المبيعات',
            icon: Icons.map,
            color: Colors.purple,
            screen: const SalesByRegionScreen(),
          ),

          // =========================
          // النقدي والآجل
          // =========================

          _buildReportCard(
            context: context,
            title: 'تحليل النقدي والآجل',
            subtitle:
            'تحليل المدفوعات النقدية والآجلة',
            icon: Icons.payments,
            color: Colors.orange,
            screen: const CashCreditSalesScreen(),
          ),

          const SizedBox(height: 30),

          // =========================
          // قسم مستقبلي
          // =========================

          Card(
            color: Colors.teal.withOpacity(0.08),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            child: const Padding(
              padding: EdgeInsets.all(18),

              child: Column(
                children: [

                  Icon(
                    Icons.auto_graph,
                    color: Colors.teal,
                    size: 38,
                  ),

                  SizedBox(height: 12),

                  Text(
                    'سيتم إضافة المزيد من التحليلات الاحترافية قريباً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'تقارير الأرباح - الذكاء التجاري - التنبؤ بالمبيعات - تحليل العملاء',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),

      elevation: 3,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.15),

          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),

          child: Text(
            subtitle,
            style: const TextStyle(height: 1.4),
          ),
        ),

        trailing: const Icon(Icons.arrow_forward_ios),

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