import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/role_provider.dart';
import '../../models/role_model.dart';
import '../../models/permissions.dart';
import '../../services/auth_service.dart';

class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({Key? key}) : super(key: key);

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (!auth.canManageRoles) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير مصرح'), backgroundColor: Colors.red),
        body: const Center(child: Text('ليس لديك صلاحية لعرض هذه الصفحة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأدوار'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Consumer<RoleProvider>(
        builder: (context, provider, child) {
          final roles = provider.roles;
          if (roles.isEmpty) {
            return const Center(child: Text('لا توجد أدوار'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(role.description),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الصلاحيات:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: role.defaultPermissions.map((perm) {
                              return Chip(
                                label: Text(_getPermissionLabel(perm)),
                                backgroundColor: Colors.teal.shade50,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _editRole(context, role, provider),
                                icon: const Icon(Icons.edit),
                                label: const Text('تعديل'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              if (role.id != 'role_owner')
                                ElevatedButton.icon(
                                  onPressed: () => _deleteRole(context, role, provider),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('حذف'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRole(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _addRole(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    List<String> selectedPermissions = [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة دور جديد'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الدور')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'الوصف')),
              const SizedBox(height: 12),
              const Text('اختر الصلاحيات:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allPermissions.length,
                  itemBuilder: (ctx, idx) {
                    final perm = allPermissions[idx];
                    return CheckboxListTile(
                      title: Text(_getPermissionLabel(perm)),
                      value: selectedPermissions.contains(perm),
                      onChanged: (val) {
                        if (val == true) {
                          selectedPermissions.add(perm);
                        } else {
                          selectedPermissions.remove(perm);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newRole = RoleModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                description: descController.text.trim(),
                defaultPermissions: selectedPermissions,
              );
              Provider.of<RoleProvider>(context, listen: false).addRole(newRole);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الدور')));
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editRole(BuildContext context, RoleModel role, RoleProvider provider) {
    final nameController = TextEditingController(text: role.name);
    final descController = TextEditingController(text: role.description);
    List<String> selectedPermissions = List.from(role.defaultPermissions);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الدور'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الدور')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'الوصف')),
              const SizedBox(height: 12),
              const Text('الصلاحيات:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allPermissions.length,
                  itemBuilder: (ctx, idx) {
                    final perm = allPermissions[idx];
                    return CheckboxListTile(
                      title: Text(_getPermissionLabel(perm)),
                      value: selectedPermissions.contains(perm),
                      onChanged: (val) {
                        if (val == true) {
                          selectedPermissions.add(perm);
                        } else {
                          selectedPermissions.remove(perm);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final updatedRole = RoleModel(
                id: role.id,
                name: nameController.text.trim(),
                description: descController.text.trim(),
                defaultPermissions: selectedPermissions,
              );
              provider.updateRole(updatedRole);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteRole(BuildContext context, RoleModel role, RoleProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الدور'),
        content: Text('هل أنت متأكد من حذف دور "${role.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              provider.deleteRole(role.id);
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