import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../widgets/category_helpers.dart';
import 'edit_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final companyId = auth.currentCompanyId ?? 'comp_001';

    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('companyId', isEqualTo: companyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد منتجات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          final products = snapshot.data!.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final category = _getCategoryFromName(product.name);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(color: getCategoryColor(category), borderRadius: BorderRadius.circular(10)),
                          child: Icon(getCategoryIcon(category), color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(product.concentration, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: Text('${product.getBasePriceForRegion('sanaa')} ${product.currencySymbol}', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                    child: Text('المتبقي: ${product.stockQuantity}', style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                              if ((product.bonusCash?.percentage ?? 0) > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text('بونص نقدي: ${product.bonusCash!.percentage}%', style: TextStyle(fontSize: 10, color: Colors.amber.shade800)),
                                ),
                              if ((product.bonusCredit?.percentage ?? 0) > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text('بونص آجل: ${product.bonusCredit!.percentage}%', style: TextStyle(fontSize: 10, color: Colors.amber.shade800)),
                                ),
                              if (product.hasOffer)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text('عرض: ${product.offerPrice} جنيه بدلاً من ${product.getBasePriceForRegion('sanaa')}', style: const TextStyle(fontSize: 10, color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            if (auth.canEditProduct)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProductScreen(product: product, agencyId: product.agencyId),
                                    ),
                                  );
                                  if (result == true) {
                                    // التحديث التلقائي سيحدث عبر StreamBuilder
                                  }
                                },
                              ),
                            if (auth.canDeleteProduct)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('حذف المنتج'),
                                      content: Text('هل أنت متأكد من حذف ${product.name}؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم حذف المنتج'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _getCategoryFromName(String name) {
    if (name.contains('بنادول') || name.contains('بروفين') || name.contains('ديكلوفيناك')) return 'مسكنات';
    else if (name.contains('أموكسيل') || name.contains('زيتروماكس')) return 'مضادات حيوية';
    else if (name.contains('فيتامين')) return 'فيتامينات';
    else return 'أدوية';
  }
}