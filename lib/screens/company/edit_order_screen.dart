import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;
  const EditOrderScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late List<OrderItem> _items;
  late double _totalPrice;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.order.items);
    _totalPrice = widget.order.totalPrice;
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      final item = _items[index];
      final newItem = OrderItem(
        productId: item.productId,
        productName: item.productName,
        scientificName: item.scientificName,
        quantity: newQuantity,
        quantityInPieces: item.unit == 'carton'
            ? newQuantity * (item.piecesPerCarton ?? 1)
            : newQuantity,
        unit: item.unit,
        piecesPerCarton: item.piecesPerCarton,
        price: item.price,
        bonusReceived: item.bonusReceived,
        totalPrice: item.price * newQuantity,
      );
      _items[index] = newItem;
      _recalculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _recalculateTotal();
    });
  }

  void _changeUnit(int index, String newUnit) {
    setState(() {
      final item = _items[index];
      if (item.unit == newUnit) return;
      if (item.piecesPerCarton == null || item.piecesPerCarton! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن تغيير الوحدة لهذا المنتج'), backgroundColor: Colors.orange),
        );
        return;
      }
      int newQuantity;
      if (item.unit == 'piece' && newUnit == 'carton') {
        newQuantity = (item.quantity / item.piecesPerCarton!).ceil();
        if (newQuantity < 1) newQuantity = 1;
      } else if (item.unit == 'carton' && newUnit == 'piece') {
        newQuantity = item.quantity * item.piecesPerCarton!;
      } else {
        return;
      }
      final newItem = OrderItem(
        productId: item.productId,
        productName: item.productName,
        scientificName: item.scientificName,
        quantity: newQuantity,
        quantityInPieces: newUnit == 'carton'
            ? newQuantity * (item.piecesPerCarton ?? 1)
            : newQuantity,
        unit: newUnit,
        piecesPerCarton: item.piecesPerCarton,
        price: item.price,
        bonusReceived: item.bonusReceived,
        totalPrice: item.price * newQuantity,
      );
      _items[index] = newItem;
      _recalculateTotal();
    });
  }

  void _recalculateTotal() {
    _totalPrice = _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _saveChanges() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.updateOrderItems(widget.order.id, _items, _totalPrice);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعديل الطلب بنجاح'), backgroundColor: Colors.green),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الطلب'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('لا توجد منتجات في الطلب'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('السعر: ${item.price.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('الوحدة:'),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: item.unit,
                              items: const [
                                DropdownMenuItem(value: 'piece', child: Text('باكيت')),
                                DropdownMenuItem(value: 'carton', child: Text('كرتون')),
                              ],
                              onChanged: (newUnit) {
                                if (newUnit != null) {
                                  _changeUnit(index, newUnit);
                                }
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  _updateQuantity(index, item.quantity - 1);
                                }
                              },
                            ),
                            Text(item.quantity.toString(), style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(index, item.quantity + 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('الإجمالي: ${item.totalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.teal.shade50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('الإجمالي الكلي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${_totalPrice.toStringAsFixed(2)} جنيه', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}