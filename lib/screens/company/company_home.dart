import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../screens/splash_screen.dart';

import '../shared/profile_screen.dart';

import 'company_dashboard.dart';
import 'company_orders_screen.dart';
import 'my_products_screen.dart';
import 'add_product_screen.dart';
import 'company_agencies_screen.dart';

import 'customers_screen.dart';

import '../pharmacy/reports_screen.dart';
import 'company_detailed_reports_screen.dart';

import 'branches_management_screen.dart';
import 'roles_management_screen.dart';
import 'manage_sub_accounts_screen.dart';

import 'customer_sales_screen.dart';
import 'top_products_screen.dart';
import 'sales_trend_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({Key? key}) : super(key: key);

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      CompanyDashboard(),
      CompanyOrdersScreen(),
      MyProductsScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    final companyId = auth.currentCompanyId ?? '';

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
              auth.currentCompanyName ?? 'لوحة الشركة',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'نظام إدارة الشركة',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        auth.currentCompanyName ?? 'شركة الأدوية',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'لوحة تحكم الشركة',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ================= العمليات =================
            _buildSectionTitle('العمليات'),

            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'الرئيسية',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),

            _buildDrawerItem(
              icon: Icons.shopping_bag,
              title: 'الطلبات',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),

            _buildDrawerItem(
              icon: Icons.inventory_2,
              title: 'المنتجات',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),

            _buildDrawerItem(
              icon: Icons.store,
              title: 'الوكالات',
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyAgenciesScreen(),
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
                    builder: (_) => ReportsScreen(),
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
                        CompanyDetailedReportsScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.people,
              title: 'المبيعات حسب العميل',
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerSalesScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.trending_up,
              title: 'أفضل المنتجات',
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopProductsScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.show_chart,
              title: 'اتجاه المبيعات',
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalesTrendScreen(),
                  ),
                );
              },
            ),

            const Divider(height: 30),

            // ================= الحسابات =================
            _buildSectionTitle('الحسابات'),

            _buildDrawerItem(
              icon: Icons.groups,
              title: 'إدارة العملاء',
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomersScreen(
                      companyId: companyId,
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 30),

            // ================= الإدارة =================
            if (auth.canManageBranches ||
                auth.canManageRoles ||
                auth.canManageUsers) ...[

              _buildSectionTitle('الإدارة'),

              if (auth.canManageBranches)
                _buildDrawerItem(
                  icon: Icons.account_tree,
                  title: 'إدارة الفروع',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BranchesManagementScreen(),
                      ),
                    );
                  },
                ),

              if (auth.canManageRoles)
                _buildDrawerItem(
                  icon: Icons.security,
                  title: 'إدارة الصلاحيات',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RolesManagementScreen(),
                      ),
                    );
                  },
                ),

              if (auth.canManageUsers)
                _buildDrawerItem(
                  icon: Icons.manage_accounts,
                  title: 'إدارة المستخدمين',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ManageSubAccountsScreen(),
                      ),
                    );
                  },
                ),

              const Divider(height: 30),
            ],

            // ================= تسجيل الخروج =================
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
                    builder: (_) => SplashScreen(),
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

      // ================= FAB =================
      floatingActionButton:
          _currentIndex == 2
              ? FloatingActionButton.extended(
                  backgroundColor: Colors.teal,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة منتج'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(),
                      ),
                    );
                  },
                )
              : null,

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
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'الطلبات',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'المنتجات',
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
      leading: Icon(icon, color: iconColor),
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