import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class CashCreditSalesScreen extends StatefulWidget {
  const CashCreditSalesScreen({Key? key}) : super(key: key);

  @override
  State<CashCreditSalesScreen> createState() =>
      _CashCreditSalesScreenState();
}

class _CashCreditSalesScreenState
    extends State<CashCreditSalesScreen> {
  bool _isLoading = true;

  DateTimeRange? _dateRange;

  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth =
          Provider.of<AuthService>(context, listen: false);

      final orderProvider =
          Provider.of<OrderProvider>(context, listen: false);

      final companyId = auth.currentCompanyId;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      List<OrderModel> orders =
          await orderProvider.getOrdersForCompany(
        companyId,
      );

      // الطلبات المعتمدة فقط
      orders = orders.where((o) {
        return o.status == 'accepted' ||
            o.status == 'shipped' ||
            o.status == 'delivered';
      }).toList();

      // فلترة التاريخ
      if (_dateRange != null) {
        orders = orders.where((o) {
          return o.date.isAfter(
                  _dateRange!.start.subtract(
                      const Duration(days: 1))) &&
              o.date.isBefore(
                  _dateRange!.end.add(
                      const Duration(days: 1)));
        }).toList();
      }

      // ترتيب بالأحدث
      orders.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CashCreditSalesScreen Error: $e');

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

  @override
  Widget build(BuildContext context) {
    // ===============================
    // التحليلات
    // ===============================

    double totalCashSales = 0;

    double totalCreditSales = 0;

    int cashOrdersCount = 0;

    int creditOrdersCount = 0;

    Map<String, double> paymentMethods = {};

    for (var order in _orders) {
      // =====================
      // نقدي
      // =====================

      if (order.paymentType == 'cash') {
        totalCashSales += order.totalPrice;

        cashOrdersCount++;
      }

      // =====================
      // آجل
      // =====================

      if (order.paymentType == 'credit') {
        totalCreditSales += order.totalPrice;

        creditOrdersCount++;
      }

      // =====================
      // طرق الدفع
      // =====================

      final method = order.paymentMethodText;

      paymentMethods[method] =
          (paymentMethods[method] ?? 0) +
              order.totalPrice;
    }

    final totalSales =
        totalCashSales + totalCreditSales;

    final double cashPercent = totalSales > 0
        ? (totalCashSales / totalSales) * 100
        : 0;

    final double creditPercent = totalSales > 0
        ? (totalCreditSales / totalSales) * 100
        : 0;

    final avgCashOrder = cashOrdersCount > 0
        ? totalCashSales / cashOrdersCount
        : 0;

    final avgCreditOrder = creditOrdersCount > 0
        ? totalCreditSales / creditOrdersCount
        : 0;

    final paymentEntries =
        paymentMethods.entries.toList();

    paymentEntries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'المبيعات النقدية والآجلة',
          ),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المبيعات النقدية والآجلة',
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // ==========================
            // التاريخ
            // ==========================

            if (_dateRange != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'من ${_formatDate(_dateRange!.start)} '
                      'إلى ${_formatDate(_dateRange!.end)}',
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(
                            () => _dateRange = null);

                        await _loadData();
                      },
                      child: const Text(
                        'إلغاء التصفية',
                      ),
                    ),
                  ],
                ),
              ),

            // ==========================
            // الملخص الرئيسي
            // ==========================

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildSummaryCard(
                    'النقدي',
                    totalCashSales,
                    Icons.money,
                    Colors.green,
                  ),

                  const SizedBox(width: 12),

                  _buildSummaryCard(
                    'الآجل',
                    totalCreditSales,
                    Icons.credit_card,
                    Colors.orange,
                  ),
                ],
              ),
            ),

            // ==========================
            // النسب
            // ==========================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildProgressItem(
                        'نسبة النقدي',
                        cashPercent,
                        Colors.green,
                      ),

                      const SizedBox(height: 12),

                      _buildProgressItem(
                        'نسبة الآجل',
                        creditPercent,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================
            // تفاصيل إضافية
            // ==========================

            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'عدد الطلبات النقدية',
                        cashOrdersCount.toString(),
                      ),

                      _buildInfoRow(
                        'عدد الطلبات الآجلة',
                        creditOrdersCount.toString(),
                      ),

                      _buildInfoRow(
                        'متوسط الطلب النقدي',
                        avgCashOrder
                            .toStringAsFixed(2),
                      ),

                      _buildInfoRow(
                        'متوسط الطلب الآجل',
                        avgCreditOrder
                            .toStringAsFixed(2),
                      ),

                      _buildInfoRow(
                        'إجمالي المبيعات',
                        totalSales.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================
            // طرق الدفع
            // ==========================

            Expanded(
              child: paymentEntries.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات',
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          paymentEntries.length,
                      itemBuilder:
                          (context, index) {
                        final entry =
                            paymentEntries[index];

                        final method =
                            entry.key;

                        final amount =
                            entry.value;

                        final percent =
                            totalSales > 0
                                ? (amount /
                                        totalSales) *
                                    100
                                : 0;

                        return Card(
                          margin:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.teal,
                              child: Text(
                                '${index + 1}',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                            title: Text(method),
                            subtitle: Text(
                              amount
                                  .toStringAsFixed(
                                      2),
                            ),
                            trailing: Text(
                              '${percent.toStringAsFixed(1)}%',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color),

              const SizedBox(height: 8),

              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(
    String title,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(title),

            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        LinearProgressIndicator(
          value: percent / 100,
          minHeight: 10,
          backgroundColor:
              color.withOpacity(0.15),
          valueColor:
              AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(title),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}