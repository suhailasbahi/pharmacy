import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';

class CustomerSalesScreen extends StatefulWidget {
  const CustomerSalesScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSalesScreen> createState() => _CustomerSalesScreenState();
}

class _CustomerSalesScreenState extends State<CustomerSalesScreen> {
  DateTimeRange? _dateRange;
  List<OrderModel> _allOrders = [];
  List<CustomerAccount> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final auth = Provider.of<AuthService>(context, listen: false);
  final companyId = auth.currentCompanyId;
  if (companyId == null) {
    setState(() => _isLoading = false);
    return;
  }

  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
  List<OrderModel> orders = await orderProvider.getOrdersForCompany(companyId);
  
  if (_dateRange != null) {
    orders = orders.where((o) =>
        o.date.isAfter(_dateRange!.start) &&
        o.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
  }

  final accountProvider = Provider.of<AccountProvider>(context, listen: false);
  await accountProvider.loadCustomersForCompany(companyId);
  
  setState(() {
    _allOrders = orders;
    _customers = accountProvider.customers;
    _isLoading = false;
  });
}

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      await _loadData();
    }
  }

 @override
Widget build(BuildContext context) {
  final auth = Provider.of<AuthService>(context);
  final companyId = auth.currentCompanyId ?? '';
  
  if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('المبيعات حسب العميل'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // تجميع المبيعات لكل عميل
    Map<String, Map<String, double>> customerSales = {};

    for (var order in _allOrders) {
      final customerId = order.pharmacyId;
      final customerName = order.pharmacyName;
      final amount = order.totalPrice;
      final paymentType = order.paymentType;

      if (!customerSales.containsKey(customerId)) {
        customerSales[customerId] = {
          'name': 0.0,
          'total': 0.0,
          'cash': 0.0,
          'credit': 0.0,
        };
        customerSales[customerId]!['name'] = 0.0; // مؤقتاً
      }
      customerSales[customerId]!['total'] = (customerSales[customerId]!['total'] ?? 0) + amount;
      if (paymentType == 'cash') {
        customerSales[customerId]!['cash'] = (customerSales[customerId]!['cash'] ?? 0) + amount;
      } else {
        customerSales[customerId]!['credit'] = (customerSales[customerId]!['credit'] ?? 0) + amount;
      }
    }

    // ربط أسماء العملاء
    for (var customer in _customers) {
      if (customerSales.containsKey(customer.pharmacyId)) {
        customerSales[customer.pharmacyId]!['name'] = double.parse(customer.pharmacyName); // hack مؤقت
      }
    }

    final entries = customerSales.entries.toList();
    entries.sort((a, b) => (b.value['total'] ?? 0).compareTo(a.value['total'] ?? 0));
    final totalSales = entries.fold(0.0, (s, e) => s + (e.value['total'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات حسب العميل'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'تحديد فترة',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            if (_dateRange != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('من ${_formatDate(_dateRange!.start)} إلى ${_formatDate(_dateRange!.end)}'),
                    TextButton(
                      onPressed: () async {
                        setState(() => _dateRange = null);
                        await _loadData();
                      },
                      child: const Text('إلغاء التصفية'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildSummaryCard('إجمالي المبيعات', totalSales, Icons.attach_money, Colors.teal),
                  const SizedBox(width: 12),
                  _buildSummaryCard('عدد العملاء', _customers.length.toDouble(), Icons.people, Colors.blue),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('لا توجد مبيعات'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('اسم العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('إجمالي المشتريات')),
                          DataColumn(label: Text('نقدي')),
                          DataColumn(label: Text('آجل')),
                          DataColumn(label: Text('النسبة')),
                        ],
                        rows: entries.map((entry) {
                          final data = entry.value;
                          final total = data['total'] ?? 0;
                          final cash = data['cash'] ?? 0;
                          final credit = data['credit'] ?? 0;
                          final percentage = totalSales > 0 ? (total / totalSales) * 100 : 0;
                          
                          // البحث عن اسم العميل الحقيقي
                          String customerName = entry.key;
                           final customer = _customers.firstWhere(
  (c) => c.pharmacyId == entry.key,
  orElse: () => CustomerAccount(
    id: '',
    pharmacyId: entry.key,
    pharmacyName: entry.key,
    phone: '',
    balance: 0,
    createdAt: DateTime.now(),
    companyId: companyId ?? '', // أضف هذا السطر
  ),
);
                            
                          
                          if (customer.pharmacyName.isNotEmpty) {
                            customerName = customer.pharmacyName;
                          }
                          
                          return DataRow(cells: [
                            DataCell(Text(customerName)),
                            DataCell(Text('${total.toStringAsFixed(2)}')),
                            DataCell(Text('${cash.toStringAsFixed(2)}')),
                            DataCell(Text('${credit.toStringAsFixed(2)}')),
                            DataCell(Text('${percentage.toStringAsFixed(1)}%')),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text('${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}