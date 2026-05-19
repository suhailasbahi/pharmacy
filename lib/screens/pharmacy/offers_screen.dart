import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';

class OffersScreen extends StatefulWidget {
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<ProductModel> _offerProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferProducts();
  }

  Future<void> _loadOfferProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final regionId = authService.currentRegionId ?? 'sanaa';
      
      // جلب جميع المنتجات النشطة من Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
      
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
      
      // تصفية المنتجات التي لديها عرض
      final offers = allProducts.where((product) {
        // 1. عرض عام على المنتج
        if (product.hasOffer && product.offerPrice != null) {
          return true;
        }
        
        // 2. عرض خاص بمنطقة معينة (من regionPrices)
        final hasRegionalOffer = product.regionPrices.any((p) => p.hasOffer);
        if (hasRegionalOffer) {
          return true;
        }
        
        // 3. عرض خاص بالمنطقة الحالية
        final pricing = product.getPricingForRegion(regionId);
        if (pricing != null && pricing.hasOffer) {
          return true;
        }
        
        return false;
      }).toList();
      
      setState(() {
        _offerProducts = offers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading offer products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadOfferProducts();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('العروض الخاصة'),
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('العروض الخاصة'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _offerProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_offer, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('لا توجد عروض حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('ترقبوا عروضنا القادمة', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('تحديث'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _offerProducts.length,
                itemBuilder: (context, index) {
                  final product = _offerProducts[index];
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.local_offer, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('عرض', style: TextStyle(fontSize: 10, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}