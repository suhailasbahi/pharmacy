import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'companies_screen.dart';
import 'offers_screen.dart';
import '../shared/profile_screen.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';

class PharmacyHomeScreen extends StatefulWidget {
  final String selectedCity;
  final bool isGuest;
  const PharmacyHomeScreen({Key? key, required this.selectedCity, required this.isGuest}) : super(key: key);

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ProductsScreen(),
      CompaniesScreen(),
      OffersScreen(),
      CartScreen(isGuest: widget.isGuest),
      MyOrdersScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final title = widget.isGuest ? 'تصفح كزائر - ${widget.selectedCity}' : (auth.currentPharmacyName ?? 'صيدليتي') + ' - ${widget.selectedCity}';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'تصفح'),
          const BottomNavigationBarItem(icon: Icon(Icons.business), label: 'الشركات'),
          const BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'عروض'),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) {
                return Badge(
                  label: Text('${cart.totalQuantity}'),
                  child: child!,
                );
              },
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'السلة',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'طلباتي'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}