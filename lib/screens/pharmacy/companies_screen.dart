import 'package:flutter/material.dart';
import '../../models/dummy_products.dart';
import 'agencies_screen.dart';

class CompaniesScreen extends StatefulWidget {
  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<MapEntry<String, String>> get filteredCompanies {
    Map<String, String> companies = {};
    for (var agency in dummyAgencies) {
      if (!companies.containsKey(agency.companyId)) {
        companies[agency.companyId] = agency.companyName;
      }
    }
    final entries = companies.entries.toList();
    if (_searchQuery.isEmpty) return entries;
    return entries.where((entry) => entry.value.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companies = filteredCompanies;
    return Scaffold(
      appBar: AppBar(
        title: Text('الشركات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن شركة...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: companies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد شركات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('لم يتم العثور على شركات تطابق "$_searchQuery"', style: TextStyle(color: Colors.grey)),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final companyId = companies[index].key;
                final companyName = companies[index].value;
                final agenciesForCompany = dummyAgencies.where((a) => a.companyId == companyId).toList();
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgenciesScreen(companyId: companyId, companyName: companyName),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.business, size: 28, color: Colors.teal),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  companyName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${agenciesForCompany.length} وكالة',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}