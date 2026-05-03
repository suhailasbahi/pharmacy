import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dummy_products.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';
import 'product_details_screen.dart';

class AgenciesScreen extends StatelessWidget {
  final String companyId;
  final String companyName;

  const AgenciesScreen({Key? key, required this.companyId, required this.companyName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final agencies = dummyAgencies.where((a) => a.companyId == companyId).toList();
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';
    return Scaffold(
      appBar: AppBar(
        title: Text(companyName),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: agencies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد وكالات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: agencies.length,
              itemBuilder: (context, index) {
                final agency = agencies[index];
                return AgencyCard(agency: agency, regionId: regionId);
              },
            ),
    );
  }
}

class AgencyCard extends StatelessWidget {
  final dynamic agency;
  final String regionId;

  const AgencyCard({Key? key, required this.agency, required this.regionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.store, size: 24, color: Colors.teal),
        ),
        title: Text(
          agency.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${agency.products.length} منتج', style: TextStyle(fontSize: 12)),
        children: [
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: agency.products.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('لا توجد منتجات في هذه الوكالة', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: agency.products.length,
                    itemBuilder: (context, index) {
                      final product = agency.products[index];
                      final isInCart = cartProvider.isInCart(product.id);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: product, regionId: regionId),
                            ),
                          );
                        },
                        child: ProductCard(
                          product: product,
                          isInCart: isInCart,
                          regionId: regionId,
                          showAddToCart: false, // إخفاء الزر
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}