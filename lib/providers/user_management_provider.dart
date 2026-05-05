import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/permissions.dart';

class UserManagementProvider extends ChangeNotifier {
  List<UserModel> _subAccounts = [];

  List<UserModel> get subAccounts => _subAccounts;

  // تحميل بيانات تجريبية (في الحقيقة ستأتي من قاعدة بيانات أو SharedPreferences)
  void loadSampleData(String companyId) {
    _subAccounts = [
      UserModel(
        id: 'sub_1',
        email: 'manager@example.com',
        name: 'أحمد المدير',
        phone: '777111222',
        userType: 'sub_account',
        parentCompanyId: companyId,
        branchId: 'branch_1',
        roleId: 'role_sales_manager',
        customPermissions: [],
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'sub_2',
        email: 'accountant@example.com',
        name: 'محمد المحاسب',
        phone: '777333444',
        userType: 'sub_account',
        parentCompanyId: companyId,
        branchId: 'branch_1',
        roleId: 'role_accountant',
        customPermissions: [],
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'sub_3',
        email: 'inventory@example.com',
        name: 'خالد المخزون',
        phone: '777555666',
        userType: 'sub_account',
        parentCompanyId: companyId,
        branchId: 'branch_1',
        roleId: 'role_inventory_manager',
        customPermissions: [],
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'sub_4',
        email: 'rep@example.com',
        name: 'سالم المندوب',
        phone: '777777888',
        userType: 'sub_account',
        parentCompanyId: companyId,
        branchId: 'branch_1',
        roleId: 'role_sales_rep',
        customPermissions: [],
        createdAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  void addSubAccount(UserModel user) {
    _subAccounts.add(user);
    notifyListeners();
  }

  void updateSubAccount(UserModel user) {
    final index = _subAccounts.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _subAccounts[index] = user;
      notifyListeners();
    }
  }

  void deleteSubAccount(String id) {
    _subAccounts.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  List<UserModel> getSubAccountsForBranch(String branchId) {
    return _subAccounts.where((u) => u.branchId == branchId).toList();
  }

  UserModel? getSubAccountById(String id) {
    try {
      return _subAccounts.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }
}