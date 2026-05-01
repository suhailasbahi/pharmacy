import 'package:flutter/material.dart';
import 'my_products_screen.dart';
import 'add_product_screen.dart';
import 'company_orders_screen.dart';
import 'company_dashboard.dart';
import 'company_agencies_screen.dart';
import '../shared/profile_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({Key? key}) : super(key: key);

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    MyProductsScreen(),
    CompanyOrdersScreen(),
    AddProductScreen(),
    CompanyAgenciesScreen(),
    CompanyDashboard(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة الشركة'),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'منتجاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'إضافة دواء'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'الوكالات'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'لوحة التحكم'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}