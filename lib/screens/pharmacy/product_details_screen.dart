import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../models/dummy_products.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;
  final String regionId;

  const ProductDetailsScreen({Key? key, required this.product, required this.regionId}) : super(key: key);

  List<ProductModel> get similarProducts {
    List<ProductModel> all = [];
    for (var agency in dummyAgencies) {
      all.addAll(agency.products);
    }
    return all.where((p) => p.id != product.id && p.scientificName == product.scientificName && p.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isCompany = authService.currentUserType == 'company';
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(product.id);
    final price = product.getFinalPriceForRegion(regionId);
    final currency = product.getCurrencyForRegion(regionId);
    final currencySymbol = currency == 'yemen' ? 'ر.ي' : (currency == 'saudi' ? 'ر.س' : '\$');
    final similar = similarProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
        backgroundColor: Colors.teal,
        // تم إزالة automaticallyImplyLeading false لإبقاء سهم العودة
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.teal.shade50,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.file(File(product.imageUrl!), fit: BoxFit.cover, width: double.infinity)
                  : Icon(Icons.medication, size: 80, color: Colors.teal),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.scientificName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.concentration,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: product.hasOffer ? Colors.red.shade50 : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('السعر:', style: TextStyle(fontSize: 18)),
                        if (product.hasOffer && product.offerPrice != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product.offerPrice!.toStringAsFixed(2)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '${price.toStringAsFixed(2)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '${price.toStringAsFixed(2)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (product.piecesPerCarton > 0 && product.defaultUnit == 'carton')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'الكرتون الواحد يحتوي على ${product.piecesPerCarton} باكيت\nيمكنك شراء الباكيت بسعر ${product.pricePerPiece} $currencySymbol',
                              style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (product.bonusCash != null && product.bonusCash!.percentage > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.percent, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'بونص نقدي: ${product.bonusCash!.percentage}% على الكمية',
                              style: TextStyle(color: Colors.amber.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (product.bonusCredit != null && product.bonusCredit!.percentage > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.percent, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'بونص آجل: ${product.bonusCredit!.percentage}% على الكمية',
                              style: TextStyle(color: Colors.amber.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow('شركة الأدوية:', product.companyName),
                          _buildInfoRow('تاريخ الصلاحية:', _formatDate(product.expiryDate)),
                          _buildInfoRow('يحتاج تبريد:', product.requiresCooling ? 'نعم' : 'لا'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // إخفاء زر الإضافة إذا كان المستخدم شركة
                  if (!isCompany)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isInCart) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} موجود بالفعل في السلة')),
                            );
                          } else {
                            final cartItem = CartItem.fromProduct(product, regionId);
                            cartProvider.addToCart(cartItem, isCashOrder: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم إضافة ${product.name} إلى السلة'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? Colors.grey : Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isInCart ? 'المنتج موجود في السلة' : 'أضف إلى السلة',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  if (similar.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'منتجات مشابهة (نفس الاسم العلمي)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: similar.length,
                        itemBuilder: (ctx, idx) {
                          final p = similar[idx];
                          final pPrice = p.getFinalPriceForRegion(regionId);
                          final pCurrency = p.getCurrencyForRegion(regionId);
                          final pSymbol = pCurrency == 'yemen' ? 'ر.ي' : (pCurrency == 'saudi' ? 'ر.س' : '\$');
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(product: p, regionId: regionId),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 80,
                                      width: double.infinity,
                                      color: Colors.teal.shade100,
                                      child: const Center(child: Icon(Icons.medication, size: 40)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    Text('$pPrice $pSymbol', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}