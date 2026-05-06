import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_management_provider.dart';
import '../../providers/role_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/permissions.dart';

class ManageSubAccountsScreen extends StatefulWidget {
  const ManageSubAccountsScreen({Key? key}) : super(key: key);

  @override
  State<ManageSubAccountsScreen> createState() => _ManageSubAccountsScreenState();
}

class _ManageSubAccountsScreenState extends State<ManageSubAccountsScreen> {
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId ?? 'comp_001';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserManagementProvider>(context, listen: false).loadSampleData(companyId);
    });
  }

  @override
Widget build(BuildContext context) {
  final auth = Provider.of<AuthService>(context);
  if (!auth.canManageUsers) {
    return Scaffold(
      appBar: AppBar(title: const Text('غير مصرح'), backgroundColor: Colors.red),
      body: const Center(child: Text('ليس لديك صلاحية لعرض هذه الصفحة')),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('إدارة الحسابات الفرعية'),
      centerTitle: true,
      backgroundColor: Colors.teal,
    ),
    body: Consumer2<UserManagementProvider, RoleProvider>(
      builder: (context, userProvider, roleProvider, child) {
        List<UserModel> users = userProvider.subAccounts;
        // تصفية حسب الفرع إذا كان المستخدم مدير فرع
        final effectiveBranchId = auth.getEffectiveBranchId();
        if (effectiveBranchId != null) {
          users = users.where((u) => u.branchId == effectiveBranchId).toList();
        }
        if (users.isEmpty) {
          return const Center(child: Text('لا توجد حسابات فرعية'));
        }
        
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final role = roleProvider.getRoleById(user.roleId);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.isActive ? Colors.green : Colors.red,
                    child: Text(user.name[0]),
                  ),
                  title: Text(user.name),
                  subtitle: Text('${user.email} | ${role?.name ?? 'بدون دور'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editUser(context, user, roleProvider, userProvider),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(context, user, userProvider),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addUser(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _addUser(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedRoleId;
    List<String> customPermissions = [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة حساب فرعي'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              final roleProvider = Provider.of<RoleProvider>(context, listen: false);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(labelText: 'الدور'),
                    items: roleProvider.roles.map((role) {
                      return DropdownMenuItem(value: role.id, child: Text(role.name));
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => selectedRoleId = val),
                  ),
                  if (selectedRoleId != null)
                    Column(
                      children: [
                        const Divider(),
                        const Text('صلاحيات إضافية (اختيارية)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          child: ListView.builder(
                            itemCount: allPermissions.length,
                            itemBuilder: (ctx2, idx) {
                              final perm = allPermissions[idx];
                              return CheckboxListTile(
                                title: Text(_getPermissionLabel(perm)),
                                value: customPermissions.contains(perm),
                                onChanged: (val) {
                                  if (val == true) {
                                    customPermissions.add(perm);
                                  } else {
                                    customPermissions.remove(perm);
                                  }
                                  setStateDialog(() {});
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final auth = Provider.of<AuthService>(context, listen: false);
              final newUser = UserModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                email: emailController.text.trim(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                userType: 'sub_account',
                parentCompanyId: auth.currentCompanyId,
                branchId: null,
                roleId: selectedRoleId!,
                customPermissions: customPermissions,
                createdAt: DateTime.now(),
              );
              Provider.of<UserManagementProvider>(context, listen: false).addSubAccount(newUser);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الحساب')));
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editUser(BuildContext context, UserModel user, RoleProvider roleProvider, UserManagementProvider userProvider) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    String? selectedRoleId = user.roleId;
    List<String> customPermissions = List.from(user.customPermissions);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل حساب فرعي'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(labelText: 'الدور'),
                    items: roleProvider.roles.map((role) {
                      return DropdownMenuItem(value: role.id, child: Text(role.name));
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => selectedRoleId = val),
                  ),
                  const Divider(),
                  const Text('الصلاحيات الإضافية', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: allPermissions.length,
                      itemBuilder: (ctx2, idx) {
                        final perm = allPermissions[idx];
                        return CheckboxListTile(
                          title: Text(_getPermissionLabel(perm)),
                          value: customPermissions.contains(perm),
                          onChanged: (val) {
                            if (val == true) {
                              customPermissions.add(perm);
                            } else {
                              customPermissions.remove(perm);
                            }
                            setStateDialog(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final updatedUser = UserModel(
                id: user.id,
                email: emailController.text.trim(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                userType: user.userType,
                parentCompanyId: user.parentCompanyId,
                branchId: user.branchId,
                roleId: selectedRoleId!,
                customPermissions: customPermissions,
                isActive: user.isActive,
                createdAt: user.createdAt,
              );
              userProvider.updateSubAccount(updatedUser);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(BuildContext context, UserModel user, UserManagementProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف حساب فرعي'),
        content: Text('هل أنت متأكد من حذف حساب "${user.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              userProvider.deleteSubAccount(user.id);
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

  String _getPermissionLabel(String perm) {
    switch (perm) {
      case 'products:view_all': return 'عرض كل المنتجات';
      case 'products:view_own': return 'عرض منتجاته فقط';
      case 'products:add': return 'إضافة منتج';
      case 'products:edit': return 'تعديل منتج';
      case 'products:delete': return 'حذف منتج';
      case 'orders:view_all': return 'عرض كل الطلبات';
      case 'orders:view_own': return 'عرض طلباته فقط';
      case 'orders:accept': return 'قبول الطلبات';
      case 'orders:reject': return 'رفض الطلبات';
      case 'orders:ship': return 'تأكيد الشحن';
      case 'orders:deliver': return 'تسليم الطلب';
      case 'customers:view_all': return 'عرض كل العملاء';
      case 'customers:view_own': return 'عرض عملائه فقط';
      case 'customers:add': return 'إضافة عميل';
      case 'customers:edit': return 'تعديل عميل';
      case 'customers:delete': return 'حذف عميل';
      case 'reports:view_financial': return 'تقارير مالية';
      case 'reports:view_sales': return 'تقارير مبيعات';
      case 'reports:view_inventory': return 'تقارير مخزون';
      case 'reports:view_all': return 'كل التقارير';
      case 'users:manage': return 'إدارة المستخدمين';
      case 'branches:manage': return 'إدارة الفروع';
      case 'roles:manage': return 'إدارة الأدوار';
      case 'inventory:view': return 'عرض المخزون';
      case 'inventory:adjust': return 'تعديل المخزون';
      default: return perm;
    }
  }
}