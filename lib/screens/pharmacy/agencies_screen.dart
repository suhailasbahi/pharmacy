import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';
import '../../models/product_model.dart';
import 'product_details_screen.dart';
import '../../models/agency_model.dart';

class AgenciesScreen extends StatelessWidget {
  final String companyId;
  final String companyName;

  const AgenciesScreen({Key? key, required this.companyId, required this.companyName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';
    return Scaffold(
      appBar: AppBar(
        title: Text(companyName),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('agencies')
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
                  Icon(Icons.store, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد وكالات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          final agencies = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: agencies.length,
            itemBuilder: (context, index) {
              final agencyDoc = agencies[index];
              final agencyData = agencyDoc.data() as Map<String, dynamic>;
              final agency = AgencyModel.fromMap(agencyDoc.id, agencyData);
              return AgencyCard(agency: agency, regionId: regionId);
            },
          );
        },
      ),
    );
  }
}

class AgencyCard extends StatelessWidget {
  final AgencyModel agency;
  final String regionId;

  const AgencyCard({Key? key, required this.agency, required this.regionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.store, size: 24, color: Colors.teal),
        ),
        title: Text(
          agency.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: FutureBuilder<int>(
          future: _countProducts(agency.id),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text('$count منتج', style: const TextStyle(fontSize: 12));
          },
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: FutureBuilder<List<ProductModel>>(
              future: _loadProducts(agency.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('لا توجد منتجات في هذه الوكالة', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
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
                        showAddToCart: false,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _countProducts(String agencyId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('agencyId', isEqualTo: agencyId)
        .get();
    return snapshot.docs.length;
  }

  Future<List<ProductModel>> _loadProducts(String agencyId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('agencyId', isEqualTo: agencyId)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }
}

// أضف هذه الفئة إذا لم تكن موجودة (AgencyModel) - يجب أن تكون مستوردة بالفعل
// وإلا أنشئها: class AgencyModel { ... }