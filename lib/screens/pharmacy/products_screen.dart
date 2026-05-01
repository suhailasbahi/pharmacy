import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dummy_products.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  bool _showFilters = false;

  List<String> get categories {
    Set<String> cats = {'الكل'};
    for (var agency in dummyAgencies) {
      for (var product in agency.products) {
        if (product.isActive) {
          cats.add(_getCategoryFromName(product.name));
        }
      }
    }
    return cats.toList();
  }

  List<ProductModel> get filteredProducts {
    List<ProductModel> allProducts = [];
    for (var agency in dummyAgencies) {
      allProducts.addAll(agency.products);
    }
    return allProducts.where((product) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('تصفح الأدوية'),
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
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
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
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: categories.map((category) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
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
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد نتائج', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('حاول تغيير كلمة البحث أو التصنيف', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'الكل';
                        _searchController.clear();
                      });
                    },
                    child: Text('مسح الفلترة'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}