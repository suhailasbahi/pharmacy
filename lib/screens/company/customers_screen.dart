import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../models/account_model.dart';

import 'customer_statement_screen.dart';
import '../payments/add_payment_screen.dart';

class CustomersScreen extends StatefulWidget {
  final String companyId;

  const CustomersScreen({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CustomersScreen> createState() =>
      _CustomersScreenState();
}

class _CustomersScreenState
    extends State<CustomersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    try {
      final provider =
          Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      await provider.loadCustomersForCompany(
        widget.companyId,
      );
    } catch (e) {
      debugPrint('Load Customers Error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<AccountProvider>(context);

    final customers = provider.customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابات العملاء'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : customers.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد حسابات عملاء',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer =
                        customers[index];

                    return FutureBuilder<double>(
                      future: provider
                          .getAccountBalance(
                        customer.id,
                      ),
                      builder: (context, snapshot) {
                        final balance =
                            snapshot.data ?? 0;

                        return Card(
                          elevation: 3,
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            child: Column(
                              children: [

                                Row(
                                  children: [

                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor:
                                          Colors.teal
                                              .shade100,
                                      child: const Icon(
                                        Icons.person,
                                        color:
                                            Colors.teal,
                                      ),
                                    ),

                                    const SizedBox(
                                        width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [

                                          Text(
                                            customer
                                                .pharmacyName,
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  17,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),

                                          const SizedBox(
                                              height:
                                                  4),

                                          Text(
                                            customer
                                                    .phone
                                                    .isEmpty
                                                ? 'بدون رقم'
                                                : customer
                                                    .phone,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors
                                                      .grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: balance >
                                                0
                                            ? Colors.red
                                                .shade50
                                            : Colors.green
                                                .shade50,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                      ),
                                      child: Column(
                                        children: [

                                          const Text(
                                            'الرصيد',
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  12,
                                            ),
                                          ),

                                          Text(
                                            balance
                                                .toStringAsFixed(
                                                    0),
                                            style:
                                                TextStyle(
                                              color: balance >
                                                      0
                                                  ? Colors
                                                      .red
                                                  : Colors
                                                      .green,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                    height: 16),

                                Row(
                                  children: [

                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style:
                                            ElevatedButton
                                                .styleFrom(
                                          backgroundColor:
                                              Colors.teal,
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical:
                                                12,
                                          ),
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon:
                                            const Icon(
                                          Icons.receipt_long,
                                        ),
                                        label:
                                            const Text(
                                          'كشف الحساب',
                                        ),
                                        onPressed:
                                            () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      CustomerStatementScreen(
                                                customer:
                                                    customer,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(
                                        width: 12),

                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style:
                                            ElevatedButton
                                                .styleFrom(
                                          backgroundColor:
                                              Colors.orange,
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical:
                                                12,
                                          ),
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon:
                                            const Icon(
                                          Icons.payments,
                                        ),
                                        label:
                                            const Text(
                                          'سداد',
                                        ),
                                        onPressed:
                                            () async {
                                          await Navigator
                                              .push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      AddPaymentScreen(
                                                accountId:
                                                    customer
                                                        .id,
                                                accountType:
                                                    'customer',
                                                companyId:
                                                    customer
                                                        .companyId,
                                                pharmacyId:
                                                    customer
                                                        .pharmacyId,
                                                accountName:
                                                    customer
                                                        .pharmacyName,
                                              ),
                                            ),
                                          );

                                          _loadCustomers();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}