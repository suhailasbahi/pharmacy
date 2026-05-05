import 'package:flutter/material.dart';
import '../models/permissions.dart';

class AuthService extends ChangeNotifier {
  String? _currentUserId;
  String? _currentUserType;
  String? _currentCompanyId;
  String? _currentPharmacyName;
  String? _currentRegionId;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String? _currentRoleId;
  List<String> _currentPermissions = [];
  String? _currentBranchId;
  List<String> _currentCustomPermissions = [];

  String? get currentUserId => _currentUserId;
  String? get currentUserType => _currentUserType;
  String? get currentCompanyId => _currentCompanyId;
  String? get currentPharmacyName => _currentPharmacyName;
  String? get currentRegionId => _currentRegionId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String? get currentRoleId => _currentRoleId;
  String? get currentBranchId => _currentBranchId;
  bool get isCompanyOwner => _currentUserType == 'company' && _currentCompanyId != null;

  List<String> get permissions {
    if (isCompanyOwner) return allPermissions;
    Set<String> perms = {};
    perms.addAll(_currentPermissions);
    perms.addAll(_currentCustomPermissions);
    return perms.toList();
  }

  bool hasPermission(String permission) {
    if (isCompanyOwner) return true;
    return permissions.contains(permission);
  }

  bool get canViewAllProducts => hasPermission('products:view_all');
  bool get canViewOwnProducts => hasPermission('products:view_own');
  bool get canAddProduct => hasPermission('products:add');
  bool get canEditProduct => hasPermission('products:edit');
  bool get canDeleteProduct => hasPermission('products:delete');
  bool get canViewAllOrders => hasPermission('orders:view_all');
  bool get canViewOwnOrders => hasPermission('orders:view_own');
  bool get canAcceptOrder => hasPermission('orders:accept');
  bool get canRejectOrder => hasPermission('orders:reject');
  bool get canShipOrder => hasPermission('orders:ship');
  bool get canDeliverOrder => hasPermission('orders:deliver');
  bool get canViewAllCustomers => hasPermission('customers:view_all');
  bool get canViewOwnCustomers => hasPermission('customers:view_own');
  bool get canAddCustomer => hasPermission('customers:add');
  bool get canEditCustomer => hasPermission('customers:edit');
  bool get canDeleteCustomer => hasPermission('customers:delete');
  bool get canViewFinancialReports => hasPermission('reports:view_financial');
  bool get canViewSalesReports => hasPermission('reports:view_sales');
  bool get canViewInventoryReports => hasPermission('reports:view_inventory');
  bool get canViewAllReports => hasPermission('reports:view_all');
  bool get canManageUsers => hasPermission('users:manage');
  bool get canManageBranches => hasPermission('branches:manage');
  bool get canManageRoles => hasPermission('roles:manage');
  bool get canViewInventory => hasPermission('inventory:view');
  bool get canAdjustInventory => hasPermission('inventory:adjust');

  void enterAsGuest(String regionId) {
    _isGuest = true;
    _isLoggedIn = false;
    _currentRegionId = regionId;
    _currentUserId = null;
    _currentUserType = null;
    _currentCompanyId = null;
    _currentPharmacyName = null;
    _currentRoleId = null;
    _currentPermissions = [];
    _currentCustomPermissions = [];
    _currentBranchId = null;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await Future.delayed(Duration(seconds: 1));
    if (email.contains('company')) {
      _currentUserId = 'user_company_1';
      _currentUserType = 'company';
      _currentCompanyId = 'comp_001';
      _currentPharmacyName = null;
      _currentRegionId = 'sanaa';
      _currentRoleId = 'role_owner';
      _currentPermissions = defaultRolePermissions['owner'] ?? [];
      _currentCustomPermissions = [];
      _currentBranchId = null;
    } else if (email.contains('manager')) {
      _currentUserId = 'sub_1';
      _currentUserType = 'sub_account';
      _currentCompanyId = 'comp_001';
      _currentRegionId = 'sanaa';
      _currentRoleId = 'role_sales_manager';
      _currentPermissions = defaultRolePermissions['sales_manager'] ?? [];
      _currentCustomPermissions = [];
      _currentBranchId = 'branch_1';
    } else if (email.contains('accountant')) {
      _currentUserId = 'sub_2';
      _currentUserType = 'sub_account';
      _currentCompanyId = 'comp_001';
      _currentRoleId = 'role_accountant';
      _currentPermissions = defaultRolePermissions['accountant'] ?? [];
      _currentCustomPermissions = [];
      _currentBranchId = 'branch_1';
    } else {
      _currentUserId = 'pharmacy_demo_123';
      _currentUserType = 'pharmacy';
      _currentCompanyId = null;
      _currentPharmacyName = 'صيدلية التجريبية';
      _currentRegionId = 'sanaa';
      _currentRoleId = null;
      _currentPermissions = [];
      _currentCustomPermissions = [];
      _currentBranchId = null;
    }
    _isLoggedIn = true;
    _isGuest = false;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
    required String licenseNumber,
    required String regionId,
    String? address,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    if (userType == 'company') {
      _currentUserId = 'user_company_1';
      _currentUserType = 'company';
      _currentCompanyId = 'comp_001';
      _currentPharmacyName = null;
    } else {
      _currentUserId = 'pharmacy_demo_123';
      _currentUserType = 'pharmacy';
      _currentCompanyId = null;
      _currentPharmacyName = name;
    }
    _currentRegionId = regionId;
    _isLoggedIn = true;
    _isGuest = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentUserType = null;
    _currentCompanyId = null;
    _currentPharmacyName = null;
    _currentRegionId = null;
    _isLoggedIn = false;
    _isGuest = false;
    _currentRoleId = null;
    _currentPermissions = [];
    _currentCustomPermissions = [];
    _currentBranchId = null;
    notifyListeners();
  }
}