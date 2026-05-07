import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role_model.dart';
import '../models/permissions.dart';

class RoleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<RoleModel> _roles = [];

  List<RoleModel> get roles => _roles;

  Future<void> loadRoles() async {
    final snapshot = await _firestore.collection('roles').get();
    _roles = snapshot.docs.map((doc) => RoleModel.fromMap(doc.id, doc.data())).toList();
    if (_roles.isEmpty) {
      await _loadSampleRoles();
    }
    notifyListeners();
  }

  Future<void> _loadSampleRoles() async {
    final batch = _firestore.batch();
    for (var role in _getSampleRoles()) {
      final docRef = _firestore.collection('roles').doc(role.id);
      batch.set(docRef, role.toMap());
    }
    await batch.commit();
    _roles = _getSampleRoles();
  }

  List<RoleModel> _getSampleRoles() {
    return [
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
  }

  Future<void> addRole(RoleModel role) async {
    await _firestore.collection('roles').doc(role.id).set(role.toMap());
    _roles.add(role);
    notifyListeners();
  }

  Future<void> updateRole(RoleModel role) async {
    await _firestore.collection('roles').doc(role.id).update(role.toMap());
    final index = _roles.indexWhere((r) => r.id == role.id);
    if (index != -1) _roles[index] = role;
    notifyListeners();
  }

  Future<void> deleteRole(String id) async {
    await _firestore.collection('roles').doc(id).delete();
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