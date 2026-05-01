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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة وكالة جديدة'),
        content: TextField(
          decoration: InputDecoration(labelText: 'اسم الوكالة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('إضافة وكالة قيد التطوير'), backgroundColor: Colors.orange),
              );
            },
            child: Text('إضافة'),
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
            icon: Icon(Icons.add),
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
                  Icon(Icons.store, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد وكالات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('أضف وكالة جديدة بالضغط على زر +', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
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
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.store, color: Colors.teal),
        ),
        title: Text(
          agency.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${agency.products.length} منتج'),
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('إضافة منتج للوكالة من شاشة إضافة دواء'), backgroundColor: Colors.orange),
                        );
                      },
                      icon: Icon(Icons.add, size: 16),
                      label: Text('إضافة منتج'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                agency.products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('لا توجد منتجات في هذه الوكالة', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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