import 'package:flutter/material.dart';
import '../../models/dummy_products.dart';
import '../../models/product_model.dart';
import '../../models/agency_model.dart';
import '../../widgets/category_helpers.dart';
import 'edit_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<MapEntry<AgencyModel, ProductModel>> productEntries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    List<MapEntry<AgencyModel, ProductModel>> entries = [];
    final agencies = dummyAgencies.where((a) => a.companyId == 'comp_001').toList();
    for (var agency in agencies) {
      for (var product in agency.products) {
        entries.add(MapEntry(agency, product));
      }
    }
    setState(() {
      productEntries = entries;
    });
  }

  void _deleteProduct(AgencyModel agency, ProductModel product) {
    agency.products.removeWhere((p) => p.id == product.id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المنتج'), backgroundColor: Colors.red),
    );
  }

  void _editProduct(AgencyModel agency, ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProductScreen(product: product, agency: agency)),
    );
    if (result == true) {
      _loadData();
    }
  }

  String _getCategoryFromName(String name) {
    if (name.contains('باراسيتامول') || name.contains('إيبوبروفين') || name.contains('ديكلوفيناك')) return 'مسكنات';
    else if (name.contains('أموكسيسيلين') || name.contains('أزيثروميسين')) return 'مضادات حيوية';
    else if (name.contains('فيتامين')) return 'فيتامينات';
    else return 'أدوية';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('منتجاتي (${productEntries.length})'),
                     automaticallyImplyLeading: false,
                     centerTitle: true, backgroundColor: Colors.teal),

      body: productEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('لا توجد منتجات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('أضف منتج جديد من علامة التبويب إضافة دواء', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: productEntries.length,
              itemBuilder: (context, index) {
                final entry = productEntries[index];
                final product = entry.value;
                final agency = entry.key;
                String category = _getCategoryFromName(product.name);
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
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editProduct(agency, product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('حذف المنتج'),
                                    content: Text('هل أنت متأكد من حذف ${product.name}؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteProduct(agency, product);
                                        },
                                        child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
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
  }
}