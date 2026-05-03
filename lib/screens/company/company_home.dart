import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_products_screen.dart';
import 'add_product_screen.dart';
import 'company_orders_screen.dart';
import 'company_dashboard.dart';
import 'company_agencies_screen.dart';
import '../shared/profile_screen.dart';
import '../pharmacy/reports_screen.dart';
import '../../services/auth_service.dart';
import '../../screens/splash_screen.dart';
import 'customers_screen.dart';
import 'company_detailed_reports_screen.dart';

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
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الشركة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('القائمة', style: TextStyle(color: Colors.white, fontSize: 24)),
                  SizedBox(height: 8),
                  Text('شركة الأدوية', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('منتجاتي'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('الطلبات'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('إضافة دواء'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('الوكالات'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('لوحة التحكم'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('حسابي'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 5);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.teal),
              title: const Text('التقارير والإحصائيات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              },
            ),
              ListTile(
  leading: const Icon(Icons.assessment, color: Colors.teal),
  title: const Text('تقارير تفصيلية'),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyDetailedReportsScreen()));
  },
),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.teal),
              title: const Text('إدارة العملاء'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await auth.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SplashScreen()),
                );
              },
            ),
          ],
        ),
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