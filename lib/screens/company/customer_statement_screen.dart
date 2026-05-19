import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';

class CustomerStatementScreen extends StatefulWidget {
  final CustomerAccount customer;

  const CustomerStatementScreen({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerStatementScreen> createState() => _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  List<LedgerTransaction> _transactions = [];
  double _currentBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  try {
    setState(() => _isLoading = true);

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

    if (!mounted) return;

    setState(() {
      _transactions = transactions;
      _currentBalance = balance;
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('Statement load error: $e');

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('كشف حساب ${widget.customer.pharmacyName}'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ترتيب المعاملات من الأقدم إلى الأحدث لعرض كشف الحساب
    final sortedTransactions = List<LedgerTransaction>.from(_transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0;
    List<Map<String, dynamic>> statementRows = [];

    for (var t in sortedTransactions) {
      double debit = 0;  // مدين (ما عليه)
      double credit = 0; // دائن (ما دفعه)
      
      if (t.type == 'purchase') {
        debit = t.amount;
        runningBalance += t.amount;
      } else if (t.type == 'payment') {
        credit = t.amount;
        runningBalance -= t.amount;
      }

      statementRows.add({
        'date': t.date,
        'note': t.note,
        'debit': debit,
        'credit': credit,
        'balance': runningBalance,
      });
    }

    // حساب إجمالي المشتريات والمدفوعات
    final totalPurchases = _transactions
        .where((t) => t.type == 'purchase')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalPayments = _transactions
        .where((t) => t.type == 'payment')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('كشف حساب ${widget.customer.pharmacyName}'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // بطاقة الملخص
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCard('إجمالي المشتريات', totalPurchases.toStringAsFixed(2)),
                _infoCard('إجمالي المدفوعات', totalPayments.toStringAsFixed(2)),
                _infoCard('الرصيد الحالي', _currentBalance.toStringAsFixed(2)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // جدول كشف الحساب
          Expanded(
            child: statementRows.isEmpty
                ? const Center(child: Text('لا توجد معاملات'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('التاريخ')),
                        DataColumn(label: Text('البيان')),
                        DataColumn(label: Text('مدين'), numeric: true),
                        DataColumn(label: Text('دائن'), numeric: true),
                        DataColumn(label: Text('الرصيد'), numeric: true),
                      ],
                      rows: statementRows.map((row) {
                        return DataRow(cells: [
                          DataCell(Text(_formatDate(row['date'] as DateTime))),
                          DataCell(SizedBox(width: 200, child: Text(row['note'] as String))),
                          DataCell(Text((row['debit'] as double) > 0 ? (row['debit'] as double).toStringAsFixed(2) : '--')),
                          DataCell(Text((row['credit'] as double) > 0 ? (row['credit'] as double).toStringAsFixed(2) : '--')),
                          DataCell(Text((row['balance'] as double).toStringAsFixed(2))),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}