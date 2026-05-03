import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'companies_screen.dart';
import 'offers_screen.dart';
import 'reports_screen.dart';
import 'suppliers_screen.dart';
import '../shared/profile_screen.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../screens/splash_screen.dart';
import 'pharmacy_detailed_reports_screen.dart';

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
                  Text('سوق الأدوية', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('الرئيسية'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('سلة المشتريات'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('طلباتي'),
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyDetailedReportsScreen()));
  },
),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.business, color: Colors.teal),
              title: const Text('إدارة الموردين'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen()));
              },
            ),
            const Divider(),
            if (!widget.isGuest)
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'تصفح'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'الشركات'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'عروض'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'السلة'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}