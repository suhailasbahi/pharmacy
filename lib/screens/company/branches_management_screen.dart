import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/user_management_provider.dart';
import '../../services/auth_service.dart';
import '../../models/branch_model.dart';

class BranchesManagementScreen extends StatefulWidget {
  const BranchesManagementScreen({Key? key}) : super(key: key);

  @override
  State<BranchesManagementScreen> createState() => _BranchesManagementScreenState();
}

class _BranchesManagementScreenState extends State<BranchesManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedManagerId;
  bool _isLoading = false;
  List<BranchModel> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId ?? 'comp_001';
    final branchProvider = Provider.of<BranchProvider>(context, listen: false);
    await branchProvider.loadBranches(companyId);
    setState(() {
      _branches = branchProvider.branches;
    });
  }

  Future<void> _refresh() async {
    await _loadBranches();
  }

  void _addBranch() {
    _nameController.clear();
    _cityController.clear();
    _addressController.clear();
    _phoneController.clear();
    _selectedManagerId = null;
    _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة فرع جديد'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'اسم الفرع'),
                    validator: (v) => v!.isEmpty ? 'أدخل الاسم' : null,
                  ),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'المدينة'),
                    validator: (v) => v!.isEmpty ? 'أدخل المدينة' : null,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'الهاتف'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Consumer<UserManagementProvider>(
                    builder: (context, userProvider, child) {
                      final users = userProvider.subAccounts;
                      return DropdownButtonFormField<String>(
                        value: _selectedManagerId,
                        hint: const Text('اختر مدير الفرع (اختياري)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('بدون مدير')),
                          ...users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                        ],
                        onChanged: (val) => setDialogState(() => _selectedManagerId = val),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setDialogState(() => _isLoading = true);
                        try {
                          final auth = Provider.of<AuthService>(context, listen: false);
                          final newBranch = BranchModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            companyId: auth.currentCompanyId ?? 'comp_001',
                            name: _nameController.text.trim(),
                            regionId: 'sanaa',
                            city: _cityController.text.trim(),
                            address: _addressController.text.trim(),
                            phone: _phoneController.text.trim(),
                            managerUserId: _selectedManagerId,
                            isActive: true,
                          );
                          await Provider.of<BranchProvider>(context, listen: false).addBranch(newBranch);
                          Navigator.pop(ctx);
                          _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إضافة الفرع'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          setDialogState(() => _isLoading = false);
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

  void _editBranch(BranchModel branch) {
    _nameController.text = branch.name;
    _cityController.text = branch.city;
    _addressController.text = branch.address;
    _phoneController.text = branch.phone;
    _selectedManagerId = branch.managerUserId;
    _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('تعديل الفرع'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'اسم الفرع'),
                    validator: (v) => v!.isEmpty ? 'أدخل الاسم' : null,
                  ),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'المدينة'),
                    validator: (v) => v!.isEmpty ? 'أدخل المدينة' : null,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'الهاتف'),
                  ),
                  const SizedBox(height: 12),
                  Consumer<UserManagementProvider>(
                    builder: (context, userProvider, child) {
                      final users = userProvider.subAccounts;
                      return DropdownButtonFormField<String>(
                        value: _selectedManagerId,
                        hint: const Text('اختر مدير الفرع'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('بدون مدير')),
                          ...users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                        ],
                        onChanged: (val) => setDialogState(() => _selectedManagerId = val),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setDialogState(() => _isLoading = true);
                        try {
                          final updatedBranch = BranchModel(
                            id: branch.id,
                            companyId: branch.companyId,
                            name: _nameController.text.trim(),
                            regionId: branch.regionId,
                            city: _cityController.text.trim(),
                            address: _addressController.text.trim(),
                            phone: _phoneController.text.trim(),
                            managerUserId: _selectedManagerId,
                            isActive: branch.isActive,
                          );
                          await Provider.of<BranchProvider>(context, listen: false).updateBranch(updatedBranch);
                          Navigator.pop(ctx);
                          _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم التعديل'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          setDialogState(() => _isLoading = false);
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

  void _deleteBranch(BranchModel branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفرع'),
        content: Text('هل أنت متأكد من حذف فرع "${branch.name}"؟'),
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
      await Provider.of<BranchProvider>(context, listen: false).deleteBranch(branch.id);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الفرع'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _branches.isEmpty
            ? const Center(child: Text('لا توجد فروع'))
            : ListView.builder(
                itemCount: _branches.length,
                itemBuilder: (context, index) {
                  final branch = _branches[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(branch.name),
                      subtitle: Text('${branch.city} | ${branch.phone}'),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBranch,
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}