import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../screens/pharmacy/product_details_screen.dart';

class CompanyProductCard extends StatelessWidget {
  final ProductModel product;

  const CompanyProductCard({Key? key, required this.product}) : super(key: key);

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
    final samplePrice = product.regionPrices.isNotEmpty ? product.regionPrices.first.price : 0;
    final currencySymbol = product.regionPrices.isNotEmpty
        ? (product.regionPrices.first.currency == 'yemen' ? 'ر.ي' : (product.regionPrices.first.currency == 'saudi' ? 'ر.س' : '\$'))
        : 'ر.ي';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product, regionId: 'sanaa'),
          ),
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
                        Text(
                          '${samplePrice.toStringAsFixed(0)} $currencySymbol / ${product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت'}',
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        if ((product.bonusCash?.percentage ?? 0) > 0 || (product.bonusCredit?.percentage ?? 0) > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'بونص',
                              style: TextStyle(fontSize: 7, color: Colors.amber.shade800),
                            ),
                          ),
                      ],
                    ),
                    // لا يوجد زر "أضف إلى السلة"
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