import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../services/report_service.dart';

class PurchasesBySupplierScreen extends StatefulWidget {
  const PurchasesBySupplierScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesBySupplierScreen> createState() => _PurchasesBySupplierScreenState();
}

class _PurchasesBySupplierScreenState extends State<PurchasesBySupplierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange? _dateRange;
  String _searchQuery = '';
  bool _isLoading = true;

  // =========================================
  // بيانات التقرير
  // =========================================
  List<SupplierReportModel> _suppliers = [];
  double _totalAmount = 0;
  double _totalCash = 0;
  double _totalCredit = 0;
  int _totalOrders = 0;

  final ReportService _reportService = ReportService();

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
      final pharmacyId = auth.currentUserId;

      if (pharmacyId == null || pharmacyId.isEmpty) {
        setState(() {
          _suppliers = [];
          _isLoading = false;
        });
        return;
      }

      final suppliers = await _reportService.getPurchasesBySupplier(
        pharmacyId: pharmacyId,
        dateRange: _dateRange,
      );

      // حساب الإحصائيات الإجمالية
      double totalAmount = 0;
      double totalCash = 0;
      double totalCredit = 0;
      int totalOrders = 0;

      for (var supplier in suppliers) {
        totalAmount += supplier.total;
        totalCash += supplier.cash;
        totalCredit += supplier.credit;
        totalOrders += supplier.ordersCount;
      }

      setState(() {
        _suppliers = suppliers;
        _totalAmount = totalAmount;
        _totalCash = totalCash;
        _totalCredit = totalCredit;
        _totalOrders = totalOrders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PurchasesBySupplierScreen Error: $e');
      setState(() {
        _suppliers = [];
        _isLoading = false;
      });
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
  List<SupplierReportModel> get _filteredSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers.where((s) =>
        s.supplierName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // =========================================
  // بناء KPI Card
  // =========================================
  Widget _buildKpiCard({
    required String title,
    required String value,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('المشتريات حسب المورد'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredSuppliers = _filteredSuppliers;
    final filteredTotal = filteredSuppliers.fold(0.0, (sum, s) => sum + s.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشتريات حسب المورد'),
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
            Tab(icon: Icon(Icons.list_alt), text: 'قائمة الموردين'),
            Tab(icon: Icon(Icons.bar_chart), text: 'الرسم البياني'),
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
                          'من ${_formatDate(_dateRange!.start)} إلى ${_formatDate(_dateRange!.end)}',
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
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildKpiCard(
                        title: 'إجمالي المشتريات',
                        value: _totalAmount.toStringAsFixed(2),
                        color: Colors.teal,
                        icon: Icons.attach_money,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'عدد الطلبات',
                        value: _totalOrders.toString(),
                        color: Colors.blue,
                        icon: Icons.receipt_long,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'عدد الموردين',
                        value: _suppliers.length.toString(),
                        color: Colors.orange,
                        icon: Icons.business,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildKpiCard(
                        title: 'مشتريات نقدي',
                        value: _totalCash.toStringAsFixed(2),
                        color: Colors.green,
                        icon: Icons.money,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'مشتريات آجل',
                        value: _totalCredit.toStringAsFixed(2),
                        color: Colors.deepOrange,
                        icon: Icons.credit_card,
                      ),
                      const SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'نسبة نقدي',
                        value: _totalAmount > 0
                            ? '${((_totalCash / _totalAmount) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        color: Colors.purple,
                        icon: Icons.pie_chart,
                      ),
                    ],
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
                  hintText: 'ابحث عن مورد...',
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
                  // تبويب قائمة الموردين
                  _buildSuppliersList(filteredSuppliers, filteredTotal),
                  // تبويب الرسم البياني
                  _buildChartView(filteredSuppliers, filteredTotal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // قائمة الموردين
  // =========================================
  Widget _buildSuppliersList(List<SupplierReportModel> suppliers, double total) {
    if (suppliers.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        final percentage = total > 0 ? (supplier.total / total) * 100 : 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ExpansionTile(
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
              supplier.supplierName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('إجمالي المشتريات: ${supplier.total.toStringAsFixed(2)}'),
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
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('إجمالي المشتريات', '${supplier.total.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildDetailRow('المشتريات النقدية', '${supplier.cash.toStringAsFixed(2)}'),
                    _buildDetailRow('المشتريات الآجلة', '${supplier.credit.toStringAsFixed(2)}'),
                    _buildDetailRow('عدد الطلبات', supplier.ordersCount.toString()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================
  // الرسم البياني
  // =========================================
  Widget _buildChartView(List<SupplierReportModel> suppliers, double total) {
    if (suppliers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد بيانات'),
          ],
        ),
      );
    }

    // ترتيب الموردين تنازلياً
    final sortedSuppliers = List<SupplierReportModel>.from(suppliers)
      ..sort((a, b) => b.total.compareTo(a.total));

    // أخذ أول 10 موردين فقط للرسم البياني
    final topSuppliers = sortedSuppliers.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'أكبر 10 موردين',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: total,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topSuppliers.length) {
                          return RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              topSuppliers[index].supplierName,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 80,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 60),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups: List.generate(topSuppliers.length, (index) {
                  final supplier = topSuppliers[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: supplier.total,
                        color: Colors.teal,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'تفصيل المدفوعات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: topSuppliers.fold(0.0, (max, s) => s.total > max ? s.total : max),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topSuppliers.length) {
                          return RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              topSuppliers[index].supplierName,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 80,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 60),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups: List.generate(topSuppliers.length, (index) {
                  final supplier = topSuppliers[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: supplier.cash,
                        color: Colors.green,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: supplier.credit,
                        color: Colors.deepOrange,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                groupsSpace: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('نقدي', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('آجل', Colors.deepOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}