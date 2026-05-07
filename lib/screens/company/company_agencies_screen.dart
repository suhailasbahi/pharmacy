import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/agency_model.dart';
import '../../models/product_model.dart';
import '../../widgets/company_product_card.dart';
import '../../services/auth_service.dart';

class CompanyAgenciesScreen extends StatefulWidget {
  @override
  State<CompanyAgenciesScreen> createState() => _CompanyAgenciesScreenState();
}

class _CompanyAgenciesScreenState extends State<CompanyAgenciesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AgencyModel> _agencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  Future<void> _loadAgencies() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId ?? 'comp_001';
    final snapshot = await _firestore.collection('agencies').where('companyId', isEqualTo: companyId).get();
    final agencies = snapshot.docs.map((doc) => AgencyModel.fromMap(doc.id, doc.data())).toList();
    setState(() {
      _agencies = agencies;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadAgencies();
  }

  void _addAgency() {
    final nameController = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة وكالة جديدة'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الوكالة'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isAdding
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى إدخال اسم الوكالة'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        setDialogState(() => isAdding = true);
                        try {
                          final auth = Provider.of<AuthService>(context, listen: false);
                          final newAgency = AgencyModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            companyId: auth.currentCompanyId ?? 'comp_001',
                            companyName: 'شركة الأدوية العربية',
                            products: [],
                            isActive: true,
                          );
                          await _firestore.collection('agencies').doc(newAgency.id).set(newAgency.toMap());
                          Navigator.pop(ctx);
                          await _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إضافة الوكالة بنجاح'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          setDialogState(() => isAdding = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editAgency(AgencyModel agency) {
    final nameController = TextEditingController(text: agency.name);
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('تعديل الوكالة'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الوكالة'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى إدخال اسم الوكالة'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        setDialogState(() => isUpdating = true);
                        try {
                          final updatedAgency = AgencyModel(
                            id: agency.id,
                            name: nameController.text.trim(),
                            companyId: agency.companyId,
                            companyName: agency.companyName,
                            products: agency.products, // الحفاظ على المنتجات
                            isActive: agency.isActive,
                          );
                          await _firestore.collection('agencies').doc(agency.id).update(updatedAgency.toMap());
                          Navigator.pop(ctx);
                          await _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تعديل الوكالة بنجاح'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          setDialogState(() => isUpdating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteAgency(AgencyModel agency) async {
    if (agency.products.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حذف وكالة تحتوي على منتجات. قم بحذف المنتجات أولاً.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // تأكيد الحذف
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الوكالة'),
        content: Text('هل أنت متأكد من حذف الوكالة "${agency.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _firestore.collection('agencies').doc(agency.id).delete();
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الوكالة بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحذف: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('الوكالات'), centerTitle: true, backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('الوكالات (${_agencies.length})'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
        actions: [
          if (auth.canManageBranches)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addAgency,
              tooltip: 'إضافة وكالة',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _agencies.isEmpty
            ? const Center(child: Text('لا توجد وكالات'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _agencies.length,
                itemBuilder: (context, index) => AgencyCard(
                  agency: _agencies[index],
                  onEdit: () => _editAgency(_agencies[index]),
                  onDelete: () => _deleteAgency(_agencies[index]),
                ),
              ),
      ),
    );
  }
}

class AgencyCard extends StatelessWidget {
  final AgencyModel agency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AgencyCard({Key? key, required this.agency, required this.onEdit, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.store, color: Colors.teal),
        ),
        title: Text(agency.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('${agency.products.length} منتج', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
              onPressed: onEdit,
              tooltip: 'تعديل الوكالة',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
              tooltip: 'حذف الوكالة',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('إضافة منتج للوكالة من شاشة إضافة دواء'), backgroundColor: Colors.orange),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة منتج'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                agency.products.isEmpty
                    ? const Center(child: Text('لا توجد منتجات في هذه الوكالة', style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: agency.products.length,
                        itemBuilder: (context, index) => CompanyProductCard(product: agency.products[index]),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}