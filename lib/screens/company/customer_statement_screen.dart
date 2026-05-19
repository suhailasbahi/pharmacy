import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../payments/add_payment_screen.dart';

class CustomerStatementScreen extends StatefulWidget {
  final CustomerAccount customer;

  const CustomerStatementScreen({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  State<CustomerStatementScreen> createState() =>
      _CustomerStatementScreenState();
}

class _CustomerStatementScreenState
    extends State<CustomerStatementScreen> {
  List<LedgerTransaction> _transactions = [];
  double _currentBalance = 0;

  bool _isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final accountProvider =
          Provider.of<AccountProvider>(context, listen: false);

      final transactions =
          await accountProvider.getAccountTransactions(
        widget.customer.id,
      );

      final balance =
          await accountProvider.getAccountBalance(
        widget.customer.id,
      );

      setState(() {
        _transactions = transactions;
        _currentBalance = balance;
      });
    } catch (e) {
      debugPrint('Customer Statement Error: $e');
    }

    setState(() => _isLoading = false);
  }

  List<LedgerTransaction> get _filteredTransactions {
    return _transactions.where((transaction) {
      if (_startDate != null) {
        if (transaction.date.isBefore(_startDate!)) {
          return false;
        }
      }

      if (_endDate != null) {
        final end =
            DateTime(
              _endDate!.year,
              _endDate!.month,
              _endDate!.day,
              23,
              59,
              59,
            );

        if (transaction.date.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    final sortedTransactions =
        List<LedgerTransaction>.from(transactions)
          ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0;

    final rows = <Map<String, dynamic>>[];

    for (var t in sortedTransactions) {
      double debit = 0;
      double credit = 0;

      if (t.type == 'purchase') {
        debit = t.amount;
        runningBalance += t.amount;
      } else {
        credit = t.amount;
        runningBalance -= t.amount;
      }

      rows.add({
        'date': t.date,
        'note': t.note,
        'debit': debit,
        'credit': credit,
        'balance': runningBalance,
      });
    }

    final totalPurchases = transactions
        .where((t) => t.type == 'purchase')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalPayments = transactions
        .where((t) => t.type == 'payment')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'كشف حساب ${widget.customer.pharmacyName}',
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.payments),
        label: const Text('سداد'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPaymentScreen(
                accountId: widget.customer.id,
                accountType: 'customer',
                companyId: widget.customer.companyId,
                pharmacyId: widget.customer.pharmacyId,
                accountName: widget.customer.pharmacyName,
              ),
            ),
          );

          _loadData();
        },
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [

                // FILTERS
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _startDate == null
                                ? 'من تاريخ'
                                : _formatDate(_startDate!),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickEndDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _endDate == null
                                ? 'إلى تاريخ'
                                : _formatDate(_endDate!),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ),

                // SUMMARY
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [

                      _infoCard(
                        'المبيعات',
                        totalPurchases.toStringAsFixed(0),
                        Colors.orange,
                      ),

                      _infoCard(
                        'المدفوعات',
                        totalPayments.toStringAsFixed(0),
                        Colors.green,
                      ),

                      _infoCard(
                        'الرصيد',
                        _currentBalance.toStringAsFixed(0),
                        Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: rows.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد معاملات',
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 18,
                            headingRowColor:
                                MaterialStateProperty.all(
                              Colors.teal.shade100,
                            ),
                            columns: const [

                              DataColumn(
                                label: Text('التاريخ'),
                              ),

                              DataColumn(
                                label: Text('البيان'),
                              ),

                              DataColumn(
                                label: Text('مدين'),
                                numeric: true,
                              ),

                              DataColumn(
                                label: Text('دائن'),
                                numeric: true,
                              ),

                              DataColumn(
                                label: Text('الرصيد'),
                                numeric: true,
                              ),
                            ],
                            rows: rows.map((row) {
                              return DataRow(
                                cells: [

                                  DataCell(
                                    Text(
                                      _formatDate(
                                        row['date'],
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    SizedBox(
                                      width: 240,
                                      child: Text(
                                        row['note'],
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      row['debit'] > 0
                                          ? row['debit']
                                              .toStringAsFixed(0)
                                          : '--',
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.red,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      row['credit'] > 0
                                          ? row['credit']
                                              .toStringAsFixed(0)
                                          : '--',
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.green,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      row['balance']
                                          .toStringAsFixed(
                                              0),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
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
    );
  }

  Widget _infoCard(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [

        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}