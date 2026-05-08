import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agencies_screen.dart';

class CompaniesScreen extends StatefulWidget {
  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, String>> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance.collection('agencies').get();
    final Map<String, String> companiesMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final companyId = data['companyId'] ?? '';
      final companyName = data['companyName'] ?? '';
      if (companyId.isNotEmpty && !companiesMap.containsKey(companyId)) {
        companiesMap[companyId] = companyName;
      }
    }
    setState(() {
      _companies = companiesMap.entries.map((e) => {'id': e.key, 'name': e.value}).toList();
      _isLoading = false;
    });
  }

  List<Map<String, String>> get filteredCompanies {
    if (_searchQuery.isEmpty) return _companies;
    return _companies.where((c) => c['name']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('الشركات'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final companies = filteredCompanies;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشركات'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن شركة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
      body: RefreshIndicator(
        onRefresh: _loadCompanies,
        child: companies.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد شركات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  final companyId = company['id']!;
                  final companyName = company['name']!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
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
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.business, size: 28, color: Colors.teal),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<int>(
                                    future: _countAgencies(companyId),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data ?? 0;
                                      return Text('$count وكالة', style: const TextStyle(fontSize: 12, color: Colors.grey));
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<int> _countAgencies(String companyId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('agencies')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snapshot.docs.length;
  }
}