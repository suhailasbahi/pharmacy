import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/account_provider.dart';
import '../../widgets/category_helpers.dart';
import '../../services/auth_service.dart';
import '../../models/cart_item.dart';
import '../../models/account_model.dart';
import 'pharmacy_home.dart';

class CartScreen extends StatefulWidget {
  final bool isGuest;
  const CartScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, Map<String, dynamic>> _paymentOptions = {};

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, AuthService>(
      builder: (context, cartProvider, authService, child) {
        if (cartProvider.items.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text('سلة المشتريات'), centerTitle: true, backgroundColor: Colors.teal),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('السلة فارغة', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final Map<String, List<CartItem>> itemsByCompany = {};
        for (var item in cartProvider.items) {
          if (!itemsByCompany.containsKey(item.companyId)) {
            itemsByCompany[item.companyId] = [];
            if (!_paymentOptions.containsKey(item.companyId)) {
              _paymentOptions[item.companyId] = {
                'paymentType': 'cash',
                'paymentMethod': 'transfer',
                'creditDays': null,
              };
            }
          }
          itemsByCompany[item.companyId]!.add(item);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('سلة المشتريات (${cartProvider.totalQuantity})'),
            centerTitle: true,
            backgroundColor: Colors.teal,
            actions: [IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => cartProvider.clearCart())],
          ),
          body: Stack(
            children: [
              ListView.builder(
                padding: EdgeInsets.only(bottom: 100),
                itemCount: itemsByCompany.keys.length,
                itemBuilder: (context, companyIndex) {
                  final companyId = itemsByCompany.keys.toList()[companyIndex];
                  final companyItems = itemsByCompany[companyId]!;
                  final companyTotal = companyItems.fold(0.0, (sum, item) => sum + item.totalPrice);
                  final paymentOpt = _paymentOptions[companyId]!;

                  return Card(
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(companyItems.first.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('${companyTotal.toStringAsFixed(2)} جنيه', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: companyItems.length,
                          itemBuilder: (context, index) {
                            final item = companyItems[index];
                            final category = _getCategoryFromName(item.name);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(color: getCategoryColor(category), borderRadius: BorderRadius.circular(10)),
                                          child: Icon(getCategoryIcon(category), color: Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('${item.unitPrice} جنيه', style: const TextStyle(color: Colors.teal)),
                                              if (item.requiresCooling) const Text('يحتاج تبريد', style: TextStyle(fontSize: 10, color: Colors.blue)),
                                              if (item.bonus > 0)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                                  child: Text('🎁 بونص: +${item.bonus} حبة مجانية', style: TextStyle(fontSize: 10, color: Colors.green.shade800)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (item.piecesPerCarton > 0)
                                      Row(
                                        children: [
                                          Text('الوحدة:', style: TextStyle(fontSize: 12)),
                                          SizedBox(width: 8),
                                          DropdownButton<String>(
                                            value: item.unit,
                                            items: const [
                                              DropdownMenuItem(value: 'piece', child: Text('باكيت')),
                                              DropdownMenuItem(value: 'carton', child: Text('كرتون')),
                                            ],
                                            onChanged: (newUnit) {
                                              if (newUnit != null && newUnit != item.unit) {
                                                final isCash = _paymentOptions[companyId]!['paymentType'] == 'cash';
                                                cartProvider.changeUnit(item.id, newUnit, context, isCashOrder: isCash);
                                              }
                                            },
                                            style: TextStyle(color: Colors.black, fontSize: 12),
                                            dropdownColor: Colors.white,
                                            iconEnabledColor: Colors.teal,
                                          ),
                                          Spacer(),
                                          IconButton(onPressed: () => cartProvider.decreaseQuantity(item.id), icon: const Icon(Icons.remove, color: Colors.red, size: 20)),
                                          GestureDetector(
                                            onTap: () => _showQuantityEditDialog(context, cartProvider, item),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ),
                                          ),
                                          IconButton(onPressed: () => cartProvider.increaseQuantity(item.id), icon: const Icon(Icons.add, color: Colors.green, size: 20)),
                                          IconButton(onPressed: () => cartProvider.removeItem(item.id), icon: const Icon(Icons.delete, color: Colors.grey, size: 20)),
                                        ],
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(onPressed: () => cartProvider.decreaseQuantity(item.id), icon: const Icon(Icons.remove, color: Colors.red, size: 20)),
                                          GestureDetector(
                                            onTap: () => _showQuantityEditDialog(context, cartProvider, item),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ),
                                          ),
                                          IconButton(onPressed: () => cartProvider.increaseQuantity(item.id), icon: const Icon(Icons.add, color: Colors.green, size: 20)),
                                          IconButton(onPressed: () => cartProvider.removeItem(item.id), icon: const Icon(Icons.delete, color: Colors.grey, size: 20)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        _buildPaymentOptions(companyId, paymentOpt, cartProvider),
                      ],
                    ),
                  );
                },
              ),
              _buildCheckoutButton(itemsByCompany, cartProvider, authService),
            ],
          ),
        );
      },
    );
  }

  void _showQuantityEditDialog(BuildContext context, CartProvider cartProvider, CartItem item) {
    TextEditingController controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل الكمية'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              int newQty = int.tryParse(controller.text) ?? 1;
              if (newQty < 1) newQty = 1;
              cartProvider.updateQuantity(item.id, newQty);
              Navigator.pop(ctx);
            },
            child: Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(String companyId, Map<String, dynamic> paymentOpt, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: RadioListTile(
                  title: const Text('نقدي'),
                  value: 'cash',
                  groupValue: paymentOpt['paymentType'],
                  onChanged: (value) {
                    setState(() {
                      _paymentOptions[companyId]!['paymentType'] = value;
                    });
                    final isCashOrder = (value == 'cash');
                    cartProvider.updateBonusesForCompany(companyId, isCashOrder);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile(
                  title: const Text('أجل'),
                  value: 'credit',
                  groupValue: paymentOpt['paymentType'],
                  onChanged: (value) {
                    setState(() {
                      _paymentOptions[companyId]!['paymentType'] = value;
                    });
                    final isCashOrder = (value == 'cash');
                    cartProvider.updateBonusesForCompany(companyId, isCashOrder);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (paymentOpt['paymentType'] == 'credit')
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد أيام الأجل', border: OutlineInputBorder()),
              onChanged: (value) => _paymentOptions[companyId]!['creditDays'] = int.tryParse(value),
            ),
          if (paymentOpt['paymentType'] == 'cash') ...[
            const Text('وسيلة الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('حوالة'),
                  selected: paymentOpt['paymentMethod'] == 'transfer',
                  onSelected: (selected) => setState(() => _paymentOptions[companyId]!['paymentMethod'] = selected ? 'transfer' : ''),
                ),
                ChoiceChip(
                  label: const Text('محفظة إلكترونية'),
                  selected: paymentOpt['paymentMethod'] == 'wallet',
                  onSelected: (selected) => setState(() => _paymentOptions[companyId]!['paymentMethod'] = selected ? 'wallet' : ''),
                ),
                ChoiceChip(
                  label: const Text('كاش عند الاستلام'),
                  selected: paymentOpt['paymentMethod'] == 'cash_on_delivery',
                  onSelected: (selected) => setState(() => _paymentOptions[companyId]!['paymentMethod'] = selected ? 'cash_on_delivery' : ''),
                ),
              ],
            ),
          ],
          if (paymentOpt['paymentType'] == 'credit')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('سيتم التواصل معك لتحديد وسيلة الدفع المناسبة', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(Map<String, List<CartItem>> itemsByCompany, CartProvider cartProvider, AuthService authService) {
    final totalPrice = cartProvider.totalPrice;
    final pharmacyId = authService.currentUserId ?? 'pharmacy_demo_123';
    final pharmacyName = authService.currentPharmacyName ?? 'صيدلية تجريبية';
    final pharmacyCity = authService.currentRegionId ?? 'صنعاء';
    final regionId = authService.currentRegionId ?? 'sanaa';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي الكلي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${totalPrice.toStringAsFixed(2)} جنيه', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
                    
                    for (var entry in itemsByCompany.entries) {
                      final items = entry.value;
                      final paymentOpt = _paymentOptions[entry.key]!;
                      final companyName = items.first.companyName;
                      
                      // إضافة الطلب إلى orderProvider
                      orderProvider.addOrders(
                        items,
                        totalPrice,
                        pharmacyId: pharmacyId,
                        pharmacyName: pharmacyName,
                        pharmacyCity: pharmacyCity,
                        regionId: regionId,
                        paymentType: paymentOpt['paymentType'],
                        paymentMethod: paymentOpt['paymentMethod'],
                        creditDays: paymentOpt['creditDays'],
                      );
                      
                      // إذا كان نوع الدفع "أجل"، يتم إضافة دين على الصيدلية للمورد (الشركة)
                      final transactionAmount = (paymentOpt['paymentType'] == 'credit') 
                          ? items.fold(0.0, (sum, item) => sum + item.totalPrice) 
                          : 0.0;
                          
                      if (transactionAmount > 0) {
                        // البحث عن مورد بنفس اسم الشركة
                        final existingSupplier = accountProvider.suppliers.firstWhere(
                          (s) => s.name == companyName,
                          orElse: () => SupplierAccount(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: companyName,
                            phone: '',
                            balance: 0,
                            createdAt: DateTime.now(),
                          ),
                        );
                        
                        final transaction = Transaction(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: transactionAmount,
                          date: DateTime.now(),
                          note: 'شراء أدوية أجل من $companyName',
                          type: 'purchase',
                        );
                        
                        if (existingSupplier.id.isNotEmpty && accountProvider.suppliers.contains(existingSupplier)) {
                          accountProvider.addSupplierTransaction(existingSupplier.id, transaction);
                        } else {
                          final newSupplier = existingSupplier.copyWith(
                            balance: transactionAmount,
                            transactions: [transaction],
                          );
                          accountProvider.addSupplier(newSupplier);
                        }
                      }
                    }
                    
                    cartProvider.clearCart();
                    _paymentOptions.clear();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال الطلبات بنجاح'), backgroundColor: Colors.green),
                      );
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: pharmacyCity, isGuest: widget.isGuest)),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('إتمام الطلبات', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryFromName(String name) {
    if (name.contains('باراسيتامول') || name.contains('إيبوبروفين') || name.contains('ديكلوفيناك')) return 'مسكنات';
    if (name.contains('أموكسيسيلين') || name.contains('أزيثروميسين')) return 'مضادات حيوية';
    if (name.contains('فيتامين')) return 'فيتامينات';
    return 'أدوية';
  }
}