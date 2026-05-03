import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../screens/pharmacy/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isInCart;
  final String regionId;
  final bool showAddToCart; // لن نستخدمه

  const ProductCard({
    Key? key,
    required this.product,
    required this.isInCart,
    required this.regionId,
    this.showAddToCart = true,
  }) : super(key: key);

  String _getCategoryFromName(String name) {
    if (name.contains('باراسيتامول') || name.contains('إيبوبروفين') || name.contains('ديكلوفيناك')) {
      return 'مسكنات';
    } else if (name.contains('أموكسيسيلين') || name.contains('أزيثروميسين')) {
      return 'مضادات حيوية';
    } else if (name.contains('فيتامين')) {
      return 'فيتامينات';
    } else {
      return 'أدوية';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'مسكنات': return Colors.red.shade400;
      case 'مضادات حيوية': return Colors.blue.shade400;
      case 'فيتامينات': return Colors.green.shade400;
      default: return Colors.teal.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _getCategoryFromName(product.name);
    final price = product.getFinalPriceForRegion(regionId);
    final currency = product.getCurrencyForRegion(regionId);
    final currencySymbol = currency == 'yemen' ? 'ر.ي' : (currency == 'saudi' ? 'ر.س' : '\$');
    final maxBonus = (product.bonusCash?.percentage ?? 0) > (product.bonusCredit?.percentage ?? 0)
        ? (product.bonusCash?.percentage ?? 0)
        : (product.bonusCredit?.percentage ?? 0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product, regionId: regionId)),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Center(
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.file(File(product.imageUrl!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Icon(Icons.medication, size: 40, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.concentration,
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        if (product.hasOffer && product.offerPrice != null)
                          Row(
                            children: [
                              Text(
                                '${product.offerPrice!.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${price.toStringAsFixed(0)}',
                                style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 10),
                              ),
                              Text(
                                currencySymbol,
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                ' / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          )
                        else
                          Text(
                            '${price.toStringAsFixed(0)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        if (maxBonus > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'بونص يصل إلى ${maxBonus.toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 7, color: Colors.amber.shade800),
                            ),
                          ),
                      ],
                    ),
                    // تمت إزالة زر "أضف إلى السلة" نهائياً
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}