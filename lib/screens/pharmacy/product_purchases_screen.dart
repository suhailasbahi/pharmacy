import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class ProductPurchasesScreen extends StatefulWidget {
  const ProductPurchasesScreen({Key? key}) : super(key: key);

  @override
  State<ProductPurchasesScreen> createState() =>
      _ProductPurchasesScreenState();
}

class _ProductPurchasesScreenState
    extends State<ProductPurchasesScreen> {
  String? _selectedProductId;

  DateTimeRange? _dateRange;

  List<OrderModel> _allOrders = [];

  bool _isLoading = true;

  String _searchQuery = '';

  // =========================================
  // المنتجات المستخرجة من الطلبات
  // =========================================
  Map<String, Map<String, dynamic>> _products = {};

  List<String> _filteredProductIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =========================================
  // تحميل البيانات
  // =========================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth =
          Provider.of<AuthService>(context, listen: false);

      final pharmacyId = auth.currentUserId;

      if (pharmacyId == null || pharmacyId.isEmpty) {
        setState(() {
          _allOrders = [];
          _isLoading = false;
        });
        return;
      }

      final orderProvider =
          Provider.of<OrderProvider>(context,
              listen: false);

      List<OrderModel> orders =
          await orderProvider.getOrdersForPharmacy(
        pharmacyId,
      );

      // =========================================
      // استبعاد الطلبات المرفوضة
      // =========================================
      orders = orders
          .where((o) => o.status != 'rejected')
          .toList();

      // =========================================
      // فلترة بالتاريخ
      // =========================================
      if (_dateRange != null) {
        orders = orders.where((o) {
          return o.date.isAfter(
                  _dateRange!.start.subtract(
                const Duration(days: 1),
              )) &&
              o.date.isBefore(
                _dateRange!.end.add(
                  const Duration(days: 1),
                ),
              );
        }).toList();
      }

      // =========================================
      // استخراج المنتجات من الطلبات
      // =========================================
      final Map<String, Map<String, dynamic>>
          extractedProducts = {};

      for (var order in orders) {
        for (var item in order.items) {
          extractedProducts[item.productId] = {
            'name': item.productName,
            'scientificName': item.scientificName,
          };
        }
      }

      final productIds =
          extractedProducts.keys.toList();

      setState(() {
        _allOrders = orders;

        _products = extractedProducts;

        _filteredProductIds = productIds;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
          'ProductPurchasesScreen Error: $e');

      setState(() {
        _allOrders = [];
        _isLoading = false;
      });
    }
  }

  // =========================================
  // تحديث الشاشة
  // =========================================
  Future<void> _refresh() async {
    await _loadData();
  }

  // =========================================
  // اختيار فترة زمنية
  // =========================================
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
  // البحث
  // =========================================
  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;

      if (query.trim().isEmpty) {
        _filteredProductIds =
            _products.keys.toList();

        return;
      }

      _filteredProductIds = _products.entries
          .where((entry) {
        final name =
            entry.value['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final scientific =
            entry.value['scientificName']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return name.contains(
                  query.toLowerCase(),
                ) ||
            scientific.contains(
              query.toLowerCase(),
            );
      }).map((e) => e.key).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('مشتريات صنف حسب المورد'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // =========================================
    // تجميع البيانات
    // =========================================
    Map<String, Map<String, dynamic>>
        supplierStats = {};

    double totalAmount = 0;

    int totalQuantity = 0;

    int totalPieces = 0;

    if (_selectedProductId != null) {
      for (var order in _allOrders) {
        for (var item in order.items) {
          if (item.productId ==
              _selectedProductId) {
            final supplier = order.companyName;

            if (!supplierStats
                .containsKey(supplier)) {
              supplierStats[supplier] = {
                'amount': 0.0,
                'quantity': 0,
                'pieces': 0,
              };
            }

            supplierStats[supplier]!['amount'] +=
                item.totalPrice;

            supplierStats[supplier]!['quantity'] +=
                item.quantity;

            supplierStats[supplier]!['pieces'] +=
                item.quantityInPieces;

            totalAmount += item.totalPrice;

            totalQuantity += item.quantity;

            totalPieces += item.quantityInPieces;
          }
        }
      }
    }

    final entries = supplierStats.entries.toList();

    // =========================================
    // ترتيب حسب أعلى مبلغ
    // =========================================
    entries.sort((a, b) {
      return (b.value['amount'] as double)
          .compareTo(
        a.value['amount'] as double,
      );
    });

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('مشتريات صنف حسب المورد'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'تحديد فترة',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // =========================================
            // شريط التاريخ
            // =========================================
            if (_dateRange != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'من ${_formatDate(_dateRange!.start)} '
                        'إلى ${_formatDate(_dateRange!.end)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(
                            () => _dateRange = null);

                        await _loadData();
                      },
                      child:
                          const Text('إلغاء التصفية'),
                    ),
                  ],
                ),
              ),

            // =========================================
            // البحث
            // =========================================
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  prefixIcon:
                      const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                  Icons.clear),
                              onPressed: () =>
                                  _filterProducts(''),
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onChanged: _filterProducts,
              ),
            ),

            // =========================================
            // اختيار المنتج
            // =========================================
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child:
                  DropdownButtonFormField<String>(
                value: _selectedProductId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'اختر المنتج',
                  border: OutlineInputBorder(),
                ),
                items: _filteredProductIds
                    .map((productId) {
                  final product =
                      _products[productId];

                  return DropdownMenuItem(
                    value: productId,
                    child: Text(
                      product?['name'] ??
                          'منتج',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductId = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // الإحصائيات
            // =========================================
            if (_selectedProductId != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'إجمالي المبلغ',
                        value: totalAmount
                            .toStringAsFixed(2),
                        color: Colors.teal,
                        icon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'الكمية',
                        value:
                            totalQuantity.toString(),
                        color: Colors.blue,
                        icon: Icons.inventory,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'القطع',
                        value:
                            totalPieces.toString(),
                        color: Colors.orange,
                        icon: Icons.medication,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // =========================================
            // الجدول
            // =========================================
            Expanded(
              child: _selectedProductId == null
                  ? const Center(
                      child: Text(
                        'اختر منتجاً لعرض التقرير',
                      ),
                    )
                  : entries.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد بيانات',
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'المورد',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'المبلغ',
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'الكمية',
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'القطع',
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'النسبة',
                                ),
                              ),
                            ],
                            rows: entries.map((e) {
                              final supplier =
                                  e.key;

                              final amount =
                                  e.value['amount']
                                      as double;

                              final quantity =
                                  e.value['quantity']
                                      as int;

                              final pieces =
                                  e.value['pieces']
                                      as int;

                              final percentage =
                                  totalAmount > 0
                                      ? (amount /
                                              totalAmount) *
                                          100
                                      : 0;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(supplier),
                                  ),
                                  DataCell(
                                    Text(
                                      amount
                                          .toStringAsFixed(
                                              2),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      quantity
                                          .toString(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      pieces
                                          .toString(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // بطاقة ملخص
  // =========================================
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, color: color),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}