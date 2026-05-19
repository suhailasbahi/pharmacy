import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../models/account_model.dart';

import 'supplier_statement_screen.dart';
import '../payments/add_payment_screen.dart';

class SuppliersScreen extends StatefulWidget {
  final String pharmacyId;

 const SuppliersScreen({
    Key? key,
    required this.pharmacyId,
  }) : super(key: key);

  @override
  State<SuppliersScreen> createState() =>
      _SuppliersScreenState();
}

class _SuppliersScreenState
    extends State<SuppliersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);

    try {
      final provider =
          Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      await provider.loadSuppliersForPharmacy(
        widget.pharmacyId,
      );
    } catch (e) {
      debugPrint('Load Suppliers Error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<AccountProvider>(context);

    final suppliers = provider.suppliers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابات الموردين'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : suppliers.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد حسابات موردين',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier =
                        suppliers[index];

                    return FutureBuilder<double>(
                      future: provider
                          .getAccountBalance(
                        supplier.id,
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
                                        Icons.business,
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
                                            supplier
                                                .companyName,
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
                                            supplier
                                                    .phone
                                                    .isEmpty
                                                ? 'بدون رقم'
                                                : supplier
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
                                                      SupplierStatementScreen(
                                                supplier:
                                                    supplier,
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
                                                    supplier
                                                        .id,
                                                accountType:
                                                    'supplier',
                                                companyId:
                                                    supplier
                                                        .companyId,
                                                pharmacyId:
                                                    supplier
                                                        .pharmacyId,
                                                accountName:
                                                    supplier
                                                        .companyName,
                                              ),
                                            ),
                                          );

                                          _loadSuppliers();
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