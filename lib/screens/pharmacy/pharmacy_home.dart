import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../screens/splash_screen.dart';

import '../../providers/cart_provider.dart';

import '../shared/profile_screen.dart';

import 'products_screen.dart';
import 'offers_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';

import 'suppliers_screen.dart';

import 'reports_screen.dart';
import 'pharmacy_detailed_reports_screen.dart';

class PharmacyHomeScreen extends StatefulWidget {
  final String selectedCity;
  final bool isGuest;

  const PharmacyHomeScreen({
    Key? key,
    required this.selectedCity,
    required this.isGuest,
  }) : super(key: key);

  @override
  State<PharmacyHomeScreen> createState() =>
      _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState
    extends State<PharmacyHomeScreen> {

  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [

      // التصفح
      ProductsScreen(),

      // العروض
      OffersScreen(),

      // الطلبات
      MyOrdersScreen(),

      // السلة
      CartScreen(
        isGuest: widget.isGuest,
      ),

      // الحساب
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {

    final auth = Provider.of<AuthService>(context);

    final pharmacyId =
        auth.currentPharmacyId ?? '';

    final title = widget.isGuest
        ? 'تصفح كزائر - ${widget.selectedCity}'
        : '${auth.currentPharmacyName ?? 'صيدليتي'}';

    return Scaffold(

      backgroundColor: Colors.grey.shade100,

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.teal,

        title: Column(
          children: [

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              widget.selectedCity,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),

        actions: [

          // أيقونة السلة السريعة
          Consumer<CartProvider>(
            builder: (context, cart, child) {

              final count = cart.itemCount;

              return Stack(
                children: [

                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      setState(() => _currentIndex = 3);
                    },
                  ),

                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      // ================= DRAWER =================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            // ================= HEADER =================
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal,
                    Color(0xFF00695C),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [

                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        auth.currentPharmacyName ??
                            'صيدليتي',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        widget.selectedCity,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ================= التصفح =================
            _buildSectionTitle('التصفح'),

            _buildDrawerItem(
              icon: Icons.medication,
              title: 'تصفح الأدوية',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),

            _buildDrawerItem(
              icon: Icons.local_offer,
              title: 'العروض',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),

            _buildDrawerItem(
              icon: Icons.shopping_bag,
              title: 'طلباتي',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),

            _buildDrawerItem(
              icon: Icons.shopping_cart,
              title: 'سلة المشتريات',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),

            const Divider(height: 30),

            // ================= الحسابات =================
            _buildSectionTitle('الحسابات'),

            _buildDrawerItem(
              icon: Icons.business,
              title: 'إدارة الموردين',
              onTap: () {

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuppliersScreen(
                      pharmacyId: pharmacyId,
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 30),

            // ================= التقارير =================
            _buildSectionTitle('التقارير'),

            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'التقارير العامة',
              onTap: () {

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ReportsScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.analytics,
              title: 'التقارير التفصيلية',
              onTap: () {

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PharmacyDetailedReportsScreen(),
                  ),
                );
              },
            ),

            const Divider(height: 30),

            // ================= الحساب =================
            _buildSectionTitle('الحساب'),

            _buildDrawerItem(
              icon: Icons.person,
              title: 'الملف الشخصي',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 4);
              },
            ),

            // ================= تسجيل الخروج =================
            if (!widget.isGuest)
              _buildDrawerItem(
                icon: Icons.logout,
                iconColor: Colors.red,
                textColor: Colors.red,
                title: 'تسجيل الخروج',
                onTap: () async {

                  await auth.logout();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SplashScreen(),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),

      // ================= BODY =================
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(

        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() => _currentIndex = index);
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'تصفح',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'العروض',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'طلباتي',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'السلة',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _buildSectionTitle(String title) {

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 6),

      child: Text(
        title,

        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= DRAWER ITEM =================
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.teal,
    Color textColor = Colors.black87,
  }) {

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),

      title: Text(
        title,

        style: TextStyle(
          color: textColor,
          fontSize: 15,
        ),
      ),

      onTap: onTap,
    );
  }
}