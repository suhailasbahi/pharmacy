import 'package:flutter/material.dart';
import 'sales_by_region_screen.dart';
import 'product_sales_by_region_screen.dart';
import 'cash_credit_sales_screen.dart';

class CompanyDetailedReportsScreen extends StatelessWidget {
  const CompanyDetailedReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير تفصيلية - الشركة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.map, color: Colors.teal),
              title: const Text('المبيعات حسب المحافظة'),
              subtitle: const Text('عرض إجمالي المبيعات لكل محافظة مع تفصيل نقدي/آجل'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesByRegionScreen()));
              },
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication, color: Colors.teal),
              title: const Text('مبيعات صنف معين حسب المحافظة'),
              subtitle: const Text('اختر دواء لرؤية مبيعاته في كل محافظة'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductSalesByRegionScreen()));
              },
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payment, color: Colors.teal),
              title: const Text('تفصيل المبيعات (نقدي / آجل)'),
              subtitle: const Text('عرض إجمالي المبيعات نقداً وآجلاً مع نسب'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CashCreditSalesScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}