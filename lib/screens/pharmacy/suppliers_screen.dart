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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).loadSampleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابات الموردين'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          final suppliers = provider.suppliers;
          if (suppliers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد موردين', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addSupplier(context),
                    child: const Text('إضافة مورد'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _addTransaction(context, supplier),
                                icon: const Icon(Icons.payment),
                                label: const Text('تسديد'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _editSupplier(context, supplier),
                                icon: const Icon(Icons.edit),
                                label: const Text('تعديل'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _deleteSupplier(context, supplier),
                                icon: const Icon(Icons.delete),
                                label: const Text('حذف'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
IconButton(
  icon: const Icon(Icons.receipt, color: Colors.teal),
  onPressed: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierStatementScreen(supplier: supplier)));
  },
  tooltip: 'كشف حساب',
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSupplier(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _addSupplier(BuildContext context) {
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
            onPressed: () {
              final supplier = SupplierAccount(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                balance: 0,
                createdAt: DateTime.now(),
              );
              Provider.of<AccountProvider>(context, listen: false).addSupplier(supplier);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المورد')));
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editSupplier(BuildContext context, SupplierAccount supplier) {
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
            onPressed: () {
              final updated = SupplierAccount(
                id: supplier.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                balance: supplier.balance,
                createdAt: supplier.createdAt,
                transactions: supplier.transactions,
              );
              Provider.of<AccountProvider>(context, listen: false).updateSupplier(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteSupplier(BuildContext context, SupplierAccount supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المورد'),
        content: Text('هل أنت متأكد من حذف ${supplier.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Provider.of<AccountProvider>(context, listen: false).deleteSupplier(supplier.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _addTransaction(BuildContext context, SupplierAccount supplier) {
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
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              final transaction = Transaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                amount: amount, // سالب لتقليل الرصيد المستحق للمورد
                date: DateTime.now(),
                note: noteController.text.trim(),
                type: 'payment',
              );
              Provider.of<AccountProvider>(context, listen: false).addSupplierTransaction(supplier.id, transaction);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تسجيل دفعة بقيمة $amount')));
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}