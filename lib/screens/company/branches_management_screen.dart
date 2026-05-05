import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/branch_model.dart';
import '../../services/auth_service.dart';
import '../../providers/user_management_provider.dart';

class BranchesManagementScreen extends StatefulWidget {
  const BranchesManagementScreen({Key? key}) : super(key: key);

  @override
  State<BranchesManagementScreen> createState() => _BranchesManagementScreenState();
}

class _BranchesManagementScreenState extends State<BranchesManagementScreen> {
  List<BranchModel> branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  void _loadBranches() {
    setState(() {
      branches = [
        BranchModel(
          id: 'branch_1',
          companyId: 'comp_001',
          name: 'فرع صنعاء',
          regionId: 'sanaa',
          city: 'صنعاء',
          address: 'شارع التعاون',
          phone: '0123456789',
          managerUserId: 'sub_1',
          isActive: true,
        ),
        BranchModel(
          id: 'branch_2',
          companyId: 'comp_001',
          name: 'فرع عدن',
          regionId: 'aden',
          city: 'عدن',
          address: 'خور مكسر',
          phone: '9876543210',
          managerUserId: null,
          isActive: true,
        ),
      ];
    });
  }

  void _addBranch() {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedManagerId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة فرع جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الفرع')),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: 'المدينة')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
            Consumer<UserManagementProvider>(
              builder: (context, userProvider, child) {
                final users = userProvider.subAccounts;
                return DropdownButtonFormField<String>(
                  value: selectedManagerId,
                  hint: const Text('اختر مدير الفرع (اختياري)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون مدير')),
                    ...users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                  ],
                  onChanged: (val) => selectedManagerId = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newBranch = BranchModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                companyId: 'comp_001',
                name: nameController.text.trim(),
                regionId: 'sanaa',
                city: cityController.text.trim(),
                address: addressController.text.trim(),
                phone: phoneController.text.trim(),
                managerUserId: selectedManagerId,
                isActive: true,
              );
              setState(() => branches.add(newBranch));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الفرع')));
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editBranch(BranchModel branch) {
    final nameController = TextEditingController(text: branch.name);
    final cityController = TextEditingController(text: branch.city);
    final addressController = TextEditingController(text: branch.address);
    final phoneController = TextEditingController(text: branch.phone);
    String? selectedManagerId = branch.managerUserId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الفرع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الفرع')),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: 'المدينة')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
            Consumer<UserManagementProvider>(
              builder: (context, userProvider, child) {
                final users = userProvider.subAccounts;
                return DropdownButtonFormField<String>(
                  value: selectedManagerId,
                  hint: const Text('اختر مدير الفرع'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون مدير')),
                    ...users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                  ],
                  onChanged: (val) => selectedManagerId = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final index = branches.indexWhere((b) => b.id == branch.id);
              if (index != -1) {
                branches[index] = BranchModel(
                  id: branch.id,
                  companyId: branch.companyId,
                  name: nameController.text.trim(),
                  regionId: branch.regionId,
                  city: cityController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
                  managerUserId: selectedManagerId,
                  isActive: branch.isActive,
                );
                setState(() {});
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteBranch(BranchModel branch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفرع'),
        content: Text('هل أنت متأكد من حذف فرع "${branch.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() => branches.removeWhere((b) => b.id == branch.id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (!auth.canManageBranches) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير مصرح'), backgroundColor: Colors.red),
        body: const Center(child: Text('ليس لديك صلاحية لعرض هذه الصفحة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الفروع'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: branches.isEmpty
          ? const Center(child: Text('لا توجد فروع'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text(branch.name),
                    subtitle: Text('${branch.city} - ${branch.phone}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editBranch(branch),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBranch(branch),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBranch,
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}