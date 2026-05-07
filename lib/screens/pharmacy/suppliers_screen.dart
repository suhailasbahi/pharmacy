import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
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
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    await accountProvider.loadSuppliers();
    setState(() {
      _suppliers = accountProvider.suppliers;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadSuppliers();
  }

  void _addSupplier() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مورد جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني (اختياري)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final newSupplier = SupplierAccount(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                balance: 0,
                createdAt: DateTime.now(),
              );
              await Provider.of<AccountProvider>(context, listen: false).addSupplier(newSupplier);
              Navigator.pop(ctx);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المورد')));
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editSupplier(SupplierAccount supplier) {
    final nameController = TextEditingController(text: supplier.name);
    final phoneController = TextEditingController(text: supplier.phone);
    final emailController = TextEditingController(text: supplier.email ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل المورد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final updated = SupplierAccount(
                id: supplier.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                balance: supplier.balance,
                createdAt: supplier.createdAt,
                transactions: supplier.transactions,
              );
              await Provider.of<AccountProvider>(context, listen: false).updateSupplier(updated);
              Navigator.pop(ctx);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteSupplier(SupplierAccount supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المورد'),
        content: Text('هل أنت متأكد من حذف ${supplier.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<AccountProvider>(context, listen: false).deleteSupplier(supplier.id);
              Navigator.pop(ctx);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _addTransaction(SupplierAccount supplier) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسديد دفعة لـ ${supplier.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'ملاحظة')),
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
              await Provider.of<AccountProvider>(context, listen: false).addSupplierTransaction(supplier.id, transaction);
              Navigator.pop(ctx);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تسجيل دفعة بقيمة $amount')));
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
        appBar: AppBar(title: const Text('حسابات الموردين'), centerTitle: true, backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابات الموردين'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
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
                      title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الرصيد: ${supplier.balance.toStringAsFixed(2)}'),
                      leading: CircleAvatar(
                        backgroundColor: supplier.balance > 0 ? Colors.green.shade100 : Colors.red.shade100,
                        child: Text('${supplier.balance.toStringAsFixed(0)}'),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الهاتف: ${supplier.phone}'),
                              if (supplier.email != null) Text('البريد: ${supplier.email}'),
                              const Divider(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.receipt, color: Colors.teal),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierStatementScreen(supplier: supplier)));
                                    },
                                    tooltip: 'كشف حساب',
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _addTransaction(supplier),
                                    icon: const Icon(Icons.payment),
                                    label: const Text('تسديد'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _editSupplier(supplier),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('تعديل'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _deleteSupplier(supplier),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('حذف'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('سجل المعاملات:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: supplier.transactions.length,
                                itemBuilder: (ctx, idx) {
                                  final t = supplier.transactions[idx];
                                  return ListTile(
                                    title: Text('${t.amount > 0 ? '+' : ''}${t.amount.toStringAsFixed(2)}'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addSupplier,
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}