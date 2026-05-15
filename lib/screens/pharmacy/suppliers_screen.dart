import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../models/account_model.dart';
import 'supplier_statement_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<SupplierAccount> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final pharmacyId = auth.currentPharmacyId;
    
    if (pharmacyId == null || auth.currentUserType != 'pharmacy') {
      setState(() => _isLoading = false);
      return;
    }
    
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    await accountProvider.loadSuppliersForPharmacy(pharmacyId);
    
    setState(() {
      _suppliers = accountProvider.suppliers;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadSuppliers();
  }

  void _makePayment(SupplierAccount supplier) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('سداد دفعة لـ ${supplier.companyName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'ملاحظة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              
              final transaction = LedgerTransaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                amount: amount,
                date: DateTime.now(),
                note: noteController.text.trim(),
                type: 'payment',
              );
              
              await Provider.of<AccountProvider>(context, listen: false)
                  .addSupplierTransaction(supplier.id, transaction);
              
              Navigator.pop(ctx);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تسجيل سداد بمبلغ $amount')),
              );
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('حسابات الموردين'), backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('حسابات الموردين'), backgroundColor: Colors.teal),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _suppliers.isEmpty
            ? const Center(child: Text('لا توجد موردين'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = _suppliers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      title: Text(supplier.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الرصيد: ${supplier.balance.toStringAsFixed(2)}'),
                      leading: CircleAvatar(
                        backgroundColor: supplier.balance > 0 ? Colors.red.shade100 : Colors.green.shade100,
                        child: Text('${supplier.balance.toStringAsFixed(0)}'),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الهاتف: ${supplier.phone}'),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SupplierStatementScreen(supplier: supplier),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.receipt),
                                    label: const Text('كشف حساب'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _makePayment(supplier),
                                    icon: const Icon(Icons.payment),
                                    label: const Text('سداد دفعة'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('ملاحظة: الرصيد الموجب يعني دين عليك للمورد',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 12),
                              const Text('سجل المعاملات:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: supplier.transactions.length,
                                itemBuilder: (ctx, idx) {
                                  final t = supplier.transactions[idx];
                                  return ListTile(
                                    title: Text('${t.type == 'payment' ? 'سداد' : 'مشتريات'}: ${t.amount.toStringAsFixed(2)}'),
                                    subtitle: Text(t.note),
                                    trailing: Text(_formatDate(t.date)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}