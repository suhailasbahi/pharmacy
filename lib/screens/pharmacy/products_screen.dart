import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';
import '../../models/product_model.dart';

class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  bool _showFilters = false;
  List<ProductModel> _products = [];
  List<String> _categories = ['الكل'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    final products = snapshot.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    Set<String> cats = {'الكل'};
    for (var p in products) {
      if (p.isActive) {
        cats.add(_getCategoryFromName(p.name));
      }
    }
    setState(() {
      _products = products;
      _categories = cats.toList();
      _isLoading = false;
    });
  }

  List<ProductModel> get filteredProducts {
    return _products.where((product) {
      if (!product.isActive) return false;
      bool matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.scientificName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.companyName.toLowerCase().contains(_searchQuery.toLowerCase());
      String category = _getCategoryFromName(product.name);
      bool matchesCategory = _selectedCategory == 'الكل' || category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _getCategoryFromName(String name) {
    if (name.contains('بنادول') || name.contains('بروفين') || name.contains('ديكلوفيناك')) return 'مسكنات';
    else if (name.contains('أموكسيل') || name.contains('زيتروماكس')) return 'مضادات حيوية';
    else if (name.contains('فيتامين')) return 'فيتامينات';
    else return 'أدوية';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';
    final products = filteredProducts;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تصفح الأدوية'),
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تصفح الأدوية'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showFilters ? 120 : 80),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن دواء، شركة، أو تركيز...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              if (_showFilters)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: _categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) => setState(() => _selectedCategory = selected ? category : 'الكل'),
                            backgroundColor: Colors.grey.shade200,
                            selectedColor: Colors.teal.shade100,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: products.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('لا توجد نتائج', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('حاول تغيير كلمة البحث أو التصنيف', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedCategory = 'الكل';
                          _searchController.clear();
                        });
                      },
                      child: const Text('مسح الفلترة'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isInCart = cartProvider.isInCart(product.id);
                  return ProductCard(
                    product: product,
                    isInCart: isInCart,
                    regionId: regionId,
                    showAddToCart: true,
                  );
                },
              ),
      ),
    );
  }
}