import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dummy_products.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';

class OffersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<ProductModel> allProducts = [];
    for (var agency in dummyAgencies) {
      allProducts.addAll(agency.products);
    }
    final offerProducts = allProducts.where((product) => product.hasOffer).toList();
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';

    return Scaffold(
      appBar: AppBar(
        title: Text('العروض الخاصة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: offerProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد عروض حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('ترقبوا عروضنا القادمة', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: offerProducts.length,
              itemBuilder: (context, index) {
                final product = offerProducts[index];
                final cartProvider = Provider.of<CartProvider>(context);
                final isInCart = cartProvider.isInCart(product.id);
                return Stack(
                  children: [
                    ProductCard(
                      product: product,
                      isInCart: isInCart,
                      regionId: regionId,
                      showAddToCart: true,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('خصم', style: TextStyle(fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}