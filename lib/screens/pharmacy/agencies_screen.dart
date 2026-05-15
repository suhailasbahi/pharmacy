import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';
import '../../models/product_model.dart';
import '../../models/agency_model.dart';
import '../../providers/product_provider.dart';
import 'product_details_screen.dart';

class AgenciesScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const AgenciesScreen({Key? key, required this.companyId, required this.companyName}) : super(key: key);

  @override
  State<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends State<AgenciesScreen> {
  List<AgencyModel> _agencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // 1. تحميل المنتجات مرة واحدة (لجميع الوكالات)
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.loadProducts(widget.companyId);
    
    // 2. تحميل الوكالات
    final snapshot = await FirebaseFirestore.instance
        .collection('agencies')
        .where('companyId', isEqualTo: widget.companyId)
        .get();
    
    final agencies = snapshot.docs
        .map((doc) => AgencyModel.fromMap(doc.id, doc.data()))
        .toList();
    
    setState(() {
      _agencies = agencies;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.companyName),
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _agencies.isEmpty
            ? const Center(
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
                padding: const EdgeInsets.all(8),
                itemCount: _agencies.length,
                itemBuilder: (context, index) {
                  final agency = _agencies[index];
                  return AgencyCard(agency: agency, regionId: regionId);
                },
              ),
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
    final productProvider = Provider.of<ProductProvider>(context);
    
    // تصفية المنتجات من الذاكرة المحلية (بدون طلب جديد)
    final agencyProducts = productProvider.products
        .where((p) => p.agencyId == agency.id)
        .toList();

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
        subtitle: Text('${agencyProducts.length} منتج', style: const TextStyle(fontSize: 12)),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: agencyProducts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('لا توجد منتجات في هذه الوكالة', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: agencyProducts.length,
                    itemBuilder: (context, index) {
                      final product = agencyProducts[index];
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
                  ),
          ),
        ],
      ),
    );
  }
}