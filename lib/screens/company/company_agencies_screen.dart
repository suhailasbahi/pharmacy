import 'package:flutter/material.dart';
import '../../models/dummy_products.dart';
import '../../models/agency_model.dart';
import '../../models/product_model.dart';
import '../../widgets/company_product_card.dart';

class CompanyAgenciesScreen extends StatefulWidget {
  @override
  State<CompanyAgenciesScreen> createState() => _CompanyAgenciesScreenState();
}

class _CompanyAgenciesScreenState extends State<CompanyAgenciesScreen> {
  List<AgencyModel> agencies = [];

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  void _loadAgencies() {
    setState(() {
      agencies = dummyAgencies.where((a) => a.companyId == 'comp_001').toList();
    });
  }

  void _addAgency() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة وكالة جديدة'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'اسم الوكالة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال اسم الوكالة'), backgroundColor: Colors.orange),
                );
                return;
              }
              final newAgency = AgencyModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                companyId: 'comp_001',
                companyName: 'شركة الأدوية العربية',
                products: [],
                isActive: true,
              );
              setState(() {
                agencies.add(newAgency);
                dummyAgencies.add(newAgency);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إضافة الوكالة بنجاح'), backgroundColor: Colors.green),
              );
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الوكالات (${agencies.length})'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAgency,
            tooltip: 'إضافة وكالة',
          ),
        ],
      ),
      body: agencies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد وكالات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('أضف وكالة جديدة بالضغط على زر +', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: agencies.length,
              itemBuilder: (context, index) {
                final agency = agencies[index];
                return AgencyCard(agency: agency);
              },
            ),
    );
  }
}

class AgencyCard extends StatelessWidget {
  final AgencyModel agency;

  const AgencyCard({Key? key, required this.agency}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.store, color: Colors.teal),
        ),
        title: Text(
          agency.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${agency.products.length} منتج'),
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
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('لا توجد منتجات في هذه الوكالة', style: TextStyle(color: Colors.grey)),
                        ),
                      )
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
                        itemBuilder: (context, index) {
                          final product = agency.products[index];
                          return CompanyProductCard(product: product);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}