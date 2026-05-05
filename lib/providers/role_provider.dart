import 'package:flutter/material.dart';
import '../models/role_model.dart';
import '../models/permissions.dart';

class RoleProvider extends ChangeNotifier {
  List<RoleModel> _roles = [];

  List<RoleModel> get roles => _roles;

  RoleProvider() {
    _loadSampleRoles();
  }

  void _loadSampleRoles() {
    _roles = [
      RoleModel(
        id: 'role_owner',
        name: 'مدير (Owner)',
        description: 'يمتلك كل الصلاحيات',
        defaultPermissions: defaultRolePermissions['owner'] ?? [],
      ),
      RoleModel(
        id: 'role_sales_manager',
        name: 'مدير مبيعات',
        description: 'يدير الطلبات ويوافق عليها',
        defaultPermissions: defaultRolePermissions['sales_manager'] ?? [],
      ),
      RoleModel(
        id: 'role_accountant',
        name: 'محاسب',
        description: 'يدير المنتجات والتقارير المالية',
        defaultPermissions: defaultRolePermissions['accountant'] ?? [],
      ),
      RoleModel(
        id: 'role_inventory_manager',
        name: 'مسؤول مخزون',
        description: 'يدير المخزون ويشاهد الطلبات المقبولة',
        defaultPermissions: defaultRolePermissions['inventory_manager'] ?? [],
      ),
      RoleModel(
        id: 'role_sales_rep',
        name: 'مندوب مبيعات',
        description: 'يدير العملاء ويضيف طلبات',
        defaultPermissions: defaultRolePermissions['sales_rep'] ?? [],
      ),
      RoleModel(
        id: 'role_branch_manager',
        name: 'مدير فرع',
        description: 'يدير موظفي فرعه وطلبات فرعه',
        defaultPermissions: defaultRolePermissions['branch_manager'] ?? [],
      ),
    ];
    notifyListeners();
  }

  void addRole(RoleModel role) {
    _roles.add(role);
    notifyListeners();
  }

  void updateRole(RoleModel role) {
    final index = _roles.indexWhere((r) => r.id == role.id);
    if (index != -1) {
      _roles[index] = role;
      notifyListeners();
    }
  }

  void deleteRole(String id) {
    _roles.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  RoleModel? getRoleById(String id) {
    try {
      return _roles.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}