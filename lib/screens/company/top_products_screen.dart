import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/report_service.dart';

class TopProductsScreen extends StatefulWidget {
  const TopProductsScreen({Key? key}) : super(key: key);

  @override
  State<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends State<TopProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange? _dateRange;

  final ReportService _reportService = ReportService();

  List<ProductReportModel> _topProducts = [];
  List<ProductReportModel> _topProductsByRevenue = [];

  bool _isLoading = true;

  String _searchQuery = '';

  // =========================================
  // KPI
  // =========================================
  double _totalQuantity = 0;
  double _totalRevenue = 0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================================
  // تحميل البيانات
  // =========================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final companyId = auth.currentCompanyId;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // المنتجات الأكثر مبيعاً (حسب الكمية)
      final topByQuantity = await _reportService.getTopProducts(
        companyId: companyId,
        dateRange: _dateRange,
        sortBy: 'quantity',
        limit: 20,
      );

      // المنتجات الأعلى إيراداً (حسب القيمة)
      final topByRevenue = await _reportService.getTopProducts(
        companyId: companyId,
        dateRange: _dateRange,
        sortBy: 'revenue',
        limit: 20,
      );

      double totalQuantity = 0;
      double totalRevenue = 0;
      int totalOrders = 0;

      for (var product in topByQuantity) {
        totalQuantity += product.quantity;
        totalRevenue += product.revenue;
        totalOrders += product.ordersCount;
      }

      setState(() {
        _topProducts = topByQuantity;
        _topProductsByRevenue = topByRevenue;
        _totalQuantity = totalQuantity;
        _totalRevenue = totalRevenue;
        _totalOrders = totalOrders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('TopProductsScreen Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      await _loadData();
    }
  }

  // =========================================
  // فلترة البحث
  // =========================================
  List<ProductReportModel> _filterProducts(List<ProductReportModel> products) {
    if (_searchQuery.isEmpty) return products;

    return products.where((p) {
      return p.productName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('أكثر المنتجات مبيعاً'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredByQuantity = _filterProducts(_topProducts);
    final filteredByRevenue = _filterProducts(_topProductsByRevenue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أكثر المنتجات مبيعاً'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'تحديد فترة',
            onPressed: _selectDateRange,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.production_quantity_limits), text: 'الأكثر مبيعاً'),
            Tab(icon: Icon(Icons.attach_money), text: 'الأعلى إيراداً'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // =========================================
            // شريط التاريخ والفلاتر
            // =========================================
            if (_dateRange != null || _searchQuery.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.grey.shade100,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_dateRange != null)
                      Chip(
                        label: Text(
                          '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                        ),
                        onDeleted: () async {
                          setState(() => _dateRange = null);
                          await _loadData();
                        },
                      ),
                    if (_searchQuery.isNotEmpty)
                      Chip(
                        label: Text('البحث: $_searchQuery'),
                        onDeleted: () => setState(() => _searchQuery = ''),
                      ),
                    ActionChip(
                      label: const Text('مسح الكل'),
                      onPressed: () async {
                        setState(() {
                          _dateRange = null;
                          _searchQuery = '';
                        });
                        await _loadData();
                      },
                    ),
                  ],
                ),
              ),

            // =========================================
            // KPI Cards
            // =========================================
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildKpiCard(
                    title: 'إجمالي الكمية',
                    value: _totalQuantity.toStringAsFixed(0),
                    unit: 'قطعة',
                    color: Colors.blue,
                    icon: Icons.inventory,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    title: 'إجمالي الإيرادات',
                    value: _totalRevenue.toStringAsFixed(2),
                    unit: '',
                    color: Colors.green,
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    title: 'عدد الطلبات',
                    value: _totalOrders.toString(),
                    unit: '',
                    color: Colors.orange,
                    icon: Icons.receipt_long,
                  ),
                ],
              ),
            ),

            // =========================================
            // البحث
            // =========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // TabBar View
            // =========================================
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // تبويب الأكثر مبيعاً
                  _buildProductList(filteredByQuantity, 'quantity'),
                  // تبويب الأعلى إيراداً
                  _buildProductList(filteredByRevenue, 'revenue'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // قائمة المنتجات
  // =========================================
  Widget _buildProductList(List<ProductReportModel> products, String type) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد بيانات'),
          ],
        ),
      );
    }

    final total = type == 'quantity' ? _totalQuantity : _totalRevenue;

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final percentage = total > 0
            ? (type == 'quantity'
                ? (product.quantity / total) * 100
                : (product.revenue / total) * 100)
            : 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.15),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            title: Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('الكمية: ${product.quantity.toStringAsFixed(0)}'),
                Text('الإيرادات: ${product.revenue.toStringAsFixed(2)}'),
                Text('عدد الطلبات: ${product.ordersCount}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================
  // KPI Card
  // =========================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: TextStyle(fontSize: 10, color: color),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}