import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../models/account_model.dart';
import 'customer_statement_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<CustomerAccount> _customers = [];
  bool _isLoading = true;
  Map<String, double> _balances = {};

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId;
    
    if (companyId == null || auth.currentUserType != 'company') {
      setState(() => _isLoading = false);
      return;
    }
    
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    await accountProvider.loadCustomersForCompany(companyId);
    
    final customers = accountProvider.customers;
    
    // جلب الأرصدة لكل عميل
    final Map<String, double> tempBalances = {};
    for (var customer in customers) {
      final balance = await accountProvider.getAccountBalance(customer.id);
      tempBalances[customer.id] = balance;
    }
    
    setState(() {
      _customers = customers;
      _balances = tempBalances;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadCustomers();
  }

  void _receivePayment(CustomerAccount customer) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('استلام دفعة من ${customer.pharmacyName}'),
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
              
              final accountProvider = Provider.of<AccountProvider>(context, listen: false);
              
              // استخدام createOrderLedgerEntry للتسديد
              await accountProvider.createOrderLedgerEntry(
                orderId: DateTime.now().millisecondsSinceEpoch.toString(),
                accountId: customer.id,
                accountType: 'customer',
                amount: amount,
                direction: 'payment',
                companyId: customer.companyId,
                pharmacyId: customer.pharmacyId,
              );
              
              Navigator.pop(ctx);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم استلام مبلغ $amount')),
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
    final auth = Provider.of<AuthService>(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('حسابات العملاء'), backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (auth.currentUserType != 'company') {
      return Scaffold(
        appBar: AppBar(title: const Text('غير مصرح'), backgroundColor: Colors.red),
        body: const Center(child: Text('هذه الصفحة مخصصة للشركات فقط')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('حسابات العملاء'), backgroundColor: Colors.teal),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _customers.isEmpty
            ? const Center(child: Text('لا توجد عملاء'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  final balance = _balances[customer.id] ?? 0;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      title: Text(customer.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الرصيد: ${balance.toStringAsFixed(2)}'),
                      leading: CircleAvatar(
                        backgroundColor: balance > 0 ? Colors.red.shade100 : Colors.green.shade100,
                        child: Text('${balance.toStringAsFixed(0)}'),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الهاتف: ${customer.phone}'),
                              const Divider(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CustomerStatementScreen(customer: customer),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.receipt),
                                    label: const Text('كشف حساب'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _receivePayment(customer),
                                    icon: const Icon(Icons.payment),
                                    label: const Text('استلام دفعة'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('ملاحظة: الرصيد الموجب يعني دين على العميل'),
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
}