import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;
  final String regionId;

  const ProductDetailsScreen({Key? key, required this.product, required this.regionId}) : super(key: key);

  // جلب منتجات مشابهة من Firestore (نفس الاسم العلمي)
  Future<List<ProductModel>> _getSimilarProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('scientificName', isEqualTo: product.scientificName)
          .where('isActive', isEqualTo: true)
          .get();
      
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
      
      // استبعاد المنتج الحالي
      return allProducts.where((p) => p.id != product.id).toList();
    } catch (e) {
      print('Error loading similar products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final effectiveCompanyName = (authService.currentCompanyId == product.companyId && authService.currentCompanyName != null)
        ? authService.currentCompanyName
        : product.companyName;

    final isPharmacy = authService.currentUserType == 'pharmacy';
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(product.id);
    
    // ========== حساب الأسعار بشكل موحد ==========
    final hasOffer = product.hasOfferForRegion(regionId);
    final displayPrice = product.getFinalPriceForRegion(regionId);
    final originalPrice = product.getOriginalPriceForRegion(regionId);
    final currency = product.getCurrencyForRegion(regionId);
    final currencySymbol = currency == 'yemen' ? 'ر.ي' : (currency == 'saudi' ? 'ر.س' : '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.teal.shade50,
              child: Stack(
                children: [
                  Center(
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.file(File(product.imageUrl!), fit: BoxFit.cover, width: double.infinity)
                        : Icon(Icons.medication, size: 80, color: Colors.teal),
                  ),
                  // علامة العرض
                  if (hasOffer)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'عرض خاص',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
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
                  
                  // عرض السعر
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: hasOffer ? Colors.red.shade50 : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('السعر:', style: TextStyle(fontSize: 18)),
                        if (hasOffer)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${displayPrice.toStringAsFixed(2)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '${originalPrice.toStringAsFixed(2)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
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
                            '${displayPrice.toStringAsFixed(2)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
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
                  
                  // معلومات الكرتون
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
                  
                  // البونص النقدي
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
                  
                  // البونص الآجل
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
                  
                  // معلومات إضافية
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
                  
                  // زر الإضافة إلى السلة
                  if (isPharmacy)
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
                            final cartItem = CartItem.fromProduct(product, regionId, overriddenCompanyName: effectiveCompanyName);
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
                  
                  const SizedBox(height: 24),
                  
                  // منتجات مشابهة (جلب من Firestore)
                  FutureBuilder<List<ProductModel>>(
                    future: _getSimilarProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      
                      final similar = snapshot.data ?? [];
                      if (similar.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'منتجات مشابهة (نفس الاسم العلمي)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                final pHasOffer = p.hasOfferForRegion(regionId);
                                
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
                                            child: Stack(
                                              children: [
                                                const Center(child: Icon(Icons.medication, size: 40)),
                                                if (pHasOffer)
                                                  Positioned(
                                                    top: 4,
                                                    left: 4,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'عرض',
                                                        style: TextStyle(color: Colors.white, fontSize: 8),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          if (pHasOffer)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${pPrice.toStringAsFixed(0)} $pSymbol',
                                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                                Text(
                                                  '${p.getOriginalPriceForRegion(regionId).toStringAsFixed(0)} $pSymbol',
                                                  style: const TextStyle(
                                                    decoration: TextDecoration.lineThrough,
                                                    color: Colors.grey,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              '${pPrice.toStringAsFixed(0)} $pSymbol',
                                              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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