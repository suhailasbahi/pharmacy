import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../models/account_model.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
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
        title: const Text('حسابات العملاء'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          final customers = provider.customers;
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد عملاء', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addCustomer(context),
                    child: const Text('إضافة عميل'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  title: Text(customer.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('الرصيد: ${customer.balance.toStringAsFixed(2)}'),
                  leading: CircleAvatar(
                    backgroundColor: customer.balance > 0 ? Colors.red.shade100 : Colors.green.shade100,
                    child: Text('${customer.balance.toStringAsFixed(0)}'),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الهاتف: ${customer.phone}'),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _receivePayment(context, customer),
                                icon: const Icon(Icons.payment),
                                label: const Text('استلام دفعة'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _editCustomer(context, customer),
                                icon: const Icon(Icons.edit),
                                label: const Text('تعديل'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _deleteCustomer(context, customer),
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
                            itemCount: customer.transactions.length,
                            itemBuilder: (ctx, idx) {
                              final t = customer.transactions[idx];
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
        onPressed: () => _addCustomer(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _addCustomer(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عميل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصيدلية')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final customer = CustomerAccount(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                pharmacyId: 'cid_${DateTime.now().millisecondsSinceEpoch}',
                pharmacyName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                balance: 0,
                createdAt: DateTime.now(),
              );
              Provider.of<AccountProvider>(context, listen: false).addCustomer(customer);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة العميل')));
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editCustomer(BuildContext context, CustomerAccount customer) {
    final nameController = TextEditingController(text: customer.pharmacyName);
    final phoneController = TextEditingController(text: customer.phone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل العميل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصيدلية')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final updated = CustomerAccount(
                id: customer.id,
                pharmacyId: customer.pharmacyId,
                pharmacyName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                balance: customer.balance,
                createdAt: customer.createdAt,
                transactions: customer.transactions,
              );
              Provider.of<AccountProvider>(context, listen: false).updateCustomer(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(BuildContext context, CustomerAccount customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text('هل أنت متأكد من حذف ${customer.pharmacyName}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Provider.of<AccountProvider>(context, listen: false).deleteCustomer(customer.id);
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

  void _receivePayment(BuildContext context, CustomerAccount customer) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('استلام دفعة من ${customer.pharmacyName}'),
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
              // إضافة معاملة موجبة (تسديد) تقلل من الرصيد المستحق على العميل
              final transaction = Transaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                amount: amount, // موجب لأن الرصيد ينقص
                date: DateTime.now(),
                note: noteController.text.trim(),
                type: 'payment',
              );
              Provider.of<AccountProvider>(context, listen: false).addCustomerTransaction(customer.id, transaction);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استلام مبلغ $amount')));
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}