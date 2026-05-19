import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';

class AddPaymentScreen extends StatefulWidget {
  final String accountId;

  final String accountType;
  // customer | supplier

  final String companyId;
  final String pharmacyId;

  final String accountName;

  const AddPaymentScreen({
    Key? key,
    required this.accountId,
    required this.accountType,
    required this.companyId,
    required this.pharmacyId,
    required this.accountName,
  }) : super(key: key);

  @override
  State<AddPaymentScreen> createState() =>
      _AddPaymentScreenState();
}

class _AddPaymentScreenState
    extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController =
      TextEditingController();

  final _noteController =
      TextEditingController();

  bool _isSaving = false;

  String _paymentMethod = 'cash';

  final PaymentService _paymentService =
      PaymentService();

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isSaving = true);

      final payment = PaymentModel(
        id: const Uuid().v4(),

        accountId: widget.accountId,

        accountType: widget.accountType,

        companyId: widget.companyId,

        pharmacyId: widget.pharmacyId,

        amount: double.parse(
          _amountController.text.trim(),
        ),

        paymentMethod: _paymentMethod,

        note: _noteController.text.trim().isEmpty
            ? 'دفعة سداد'
            : _noteController.text.trim(),

        createdAt: DateTime.now(),
      );

      await _paymentService.addPayment(
        payment: payment,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الدفعة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة دفعة'),
        centerTitle: true,
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            // =========================
            // اسم الحساب
            // =========================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        widget.accountName,

                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // المبلغ
            // =========================

            TextFormField(
              controller: _amountController,

              keyboardType:
                  TextInputType.number,

              decoration: InputDecoration(
                labelText: 'المبلغ',

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                prefixIcon:
                    const Icon(Icons.money),
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'أدخل المبلغ';
                }

                final amount =
                    double.tryParse(value);

                if (amount == null ||
                    amount <= 0) {
                  return 'مبلغ غير صالح';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // =========================
            // طريقة الدفع
            // =========================

            DropdownButtonFormField<String>(
              value: _paymentMethod,

              decoration: InputDecoration(
                labelText: 'طريقة الدفع',

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Text('نقدي'),
                ),

                DropdownMenuItem(
                  value: 'transfer',
                  child: Text('حوالة'),
                ),

                DropdownMenuItem(
                  value: 'wallet',
                  child: Text('محفظة إلكترونية'),
                ),
              ],

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paymentMethod = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // =========================
            // ملاحظة
            // =========================

            TextFormField(
              controller: _noteController,

              maxLines: 3,

              decoration: InputDecoration(
                labelText: 'ملاحظة',

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 30),

            // =========================
            // زر الحفظ
            // =========================

            SizedBox(
              height: 55,

              child: ElevatedButton.icon(
                onPressed:
                    _isSaving ? null : _savePayment,

                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),

                label: Text(
                  _isSaving
                      ? 'جارٍ الحفظ...'
                      : 'حفظ الدفعة',
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.teal,

                  foregroundColor:
                      Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}