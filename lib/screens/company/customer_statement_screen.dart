import 'package:flutter/material.dart';
import '../../models/account_model.dart';

class CustomerStatementScreen extends StatelessWidget {
  final CustomerAccount customer;

  const CustomerStatementScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // نسخ المعاملات وترتيبها تصاعدياً حسب التاريخ
    final transactions = List<Transaction>.from(customer.transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0;
    List<Map<String, dynamic>> statementRows = [];

    for (var t in transactions) {
      double debit = 0; // مدين (ما يزيد الدين على العميل)
      double credit = 0; // دائن (ما يقلل الدين)
      if (t.type == 'purchase') {
        debit = t.amount;
        runningBalance += t.amount;
      } else if (t.type == 'payment') {
        credit = t.amount;
        runningBalance -= t.amount;
      } else {
        // adjustment - حسب الإشارة
        if (t.amount > 0) {
          debit = t.amount;
          runningBalance += t.amount;
        } else {
          credit = -t.amount;
          runningBalance -= -t.amount;
        }
      }
      statementRows.add({
        'date': t.date,
        'note': t.note,
        'debit': debit,
        'credit': credit,
        'balance': runningBalance,
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('كشف حساب ${customer.pharmacyName}'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // ملخص سريع
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCard('إجمالي المشتريات', 
                    customer.transactions.where((t) => t.type == 'purchase').fold(0.0, (s, t) => s + t.amount).toStringAsFixed(2)),
                _infoCard('إجمالي المدفوعات', 
                    customer.transactions.where((t) => t.type == 'payment').fold(0.0, (s, t) => s + t.amount).toStringAsFixed(2)),
                _infoCard('الرصيد الحالي', customer.balance.toStringAsFixed(2)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // الجدول
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
                          DataCell(SizedBox(width: 150, child: Text(row['note'] as String))),
                          DataCell(Text(((row['debit'] as double) > 0 ? (row['debit'] as double).toStringAsFixed(2) : '--'))),
                          DataCell(Text(((row['credit'] as double) > 0 ? (row['credit'] as double).toStringAsFixed(2) : '--'))),
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