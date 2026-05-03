import 'package:flutter/material.dart';
import 'purchases_by_supplier_screen.dart';
import 'product_purchases_screen.dart';

class PharmacyDetailedReportsScreen extends StatelessWidget {
  const PharmacyDetailedReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير تفصيلية - الصيدلية'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.business, color: Colors.teal),
              title: const Text('المشتريات حسب المورد'),
              subtitle: const Text('عرض إجمالي المشتريات من كل مورد مع تفصيل نقدي/آجل'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesBySupplierScreen()));
              },
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication, color: Colors.teal),
              title: const Text('مشتريات صنف معين حسب المورد'),
              subtitle: const Text('اختر دواء لرؤية المشتريات من كل مورد'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPurchasesScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}