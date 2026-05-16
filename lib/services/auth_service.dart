import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permissions.dart';
import '../models/user_model.dart';
import '../models/region.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUserModel;
  String? _currentUserType;
  String? _currentCompanyId;
  String? _currentPharmacyName;
  String? _currentPharmacyId;
  String? _currentRegionId;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String? _currentRoleId;
  List<String> _currentPermissions = [];
  List<String> _currentCustomPermissions = [];
  String? _currentBranchId;
  String? _currentCompanyName;

  String? get currentUserId => _currentUserModel?.id;
  String? get currentUserType => _currentUserType;
  String? get currentCompanyName => _currentCompanyName;
  String? get currentCompanyId => _currentCompanyId;
  String? get currentPharmacyName => _currentPharmacyName;
  String? get currentPharmacyId => _currentPharmacyId;
  String? get currentRegionId => _currentRegionId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String? get currentRoleId => _currentRoleId;
  String? get currentBranchId => _currentBranchId;
  bool get isCompanyOwner => _currentUserType == 'company';
  bool get isPharmacy => _currentUserType == 'pharmacy';
  bool get isSubAccount => _currentUserType == 'sub_account';

  // ========== دالة مساعدة للتحقق من الصلاحية ==========
  bool hasPermission(String permission) {
    if (isGuest) return false;
    if (isCompanyOwner) return true;
    
    // التحقق من الصلاحيات المخصصة أولاً
    if (_currentCustomPermissions.contains(permission)) return true;
    
    // ثم التحقق من صلاحيات الدور
    return _currentPermissions.contains(permission);
  }

  // ========== صلاحيات المنتجات ==========
  bool get canViewAllProducts => hasPermission('products:view_all');
  bool get canViewOwnProducts => hasPermission('products:view_own');
  bool get canAddProduct => hasPermission('products:add');
  bool get canEditProduct => hasPermission('products:edit');
  bool get canDeleteProduct => hasPermission('products:delete');

  // ========== صلاحيات الطلبات ==========
  bool get canViewAllOrders => hasPermission('orders:view_all');
  bool get canViewOwnOrders => hasPermission('orders:view_own');
  bool get canAcceptOrder => hasPermission('orders:accept');
  bool get canRejectOrder => hasPermission('orders:reject');
  bool get canShipOrder => hasPermission('orders:ship');
  bool get canDeliverOrder => hasPermission('orders:deliver');

  // ========== صلاحيات العملاء ==========
  bool get canViewAllCustomers => hasPermission('customers:view_all');
  bool get canViewOwnCustomers => hasPermission('customers:view_own');
  bool get canAddCustomer => hasPermission('customers:add');
  bool get canEditCustomer => hasPermission('customers:edit');
  bool get canDeleteCustomer => hasPermission('customers:delete');

  // ========== صلاحيات التقارير ==========
  bool get canViewFinancialReports => hasPermission('reports:view_financial');
  bool get canViewSalesReports => hasPermission('reports:view_sales');
  bool get canViewInventoryReports => hasPermission('reports:view_inventory');
  bool get canViewAllReports => hasPermission('reports:view_all');

  // ========== صلاحيات الإدارة ==========
  bool get canManageUsers => hasPermission('users:manage');
  bool get canManageBranches => hasPermission('branches:manage');
  bool get canManageRoles => hasPermission('roles:manage');

  // ========== صلاحيات المخزون ==========
  bool get canViewInventory => hasPermission('inventory:view');
  bool get canAdjustInventory => hasPermission('inventory:adjust');

  // ========== دوال الفرع والمناطق ==========
  bool get isBranchManager => _currentRoleId == 'role_branch_manager' && _currentBranchId != null;
  String? getEffectiveBranchId() => isBranchManager ? _currentBranchId : null;

  List<String> getEffectiveRegions() {
    if (isCompanyOwner) {
      return Region.allRegions.map((r) => r.id).toList();
    }
    return _currentUserModel?.assignedRegions ?? [];
  }

  // ========== Guest mode ==========
  void enterAsGuest(String regionId) {
    _isGuest = true;
    _isLoggedIn = false;
    _currentRegionId = regionId;
    _currentUserModel = null;
    _currentUserType = null;
    _currentCompanyId = null;
    _currentPharmacyName = null;
    _currentRoleId = null;
    _currentPermissions = [];
    _currentCustomPermissions = [];
    _currentBranchId = null;
    _currentCompanyName = null;
    notifyListeners();
  }

  // ========== تسجيل الدخول ==========
  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception('المستخدم غير موجود في قاعدة البيانات');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data['isDeleted'] == true) {
        throw Exception('هذا الحساب محذوف. يرجى التواصل مع الدعم.');
      }

      _currentUserModel = UserModel.fromMap(uid, data);
      _currentUserType = _currentUserModel!.userType;
      _currentCompanyId = _currentUserModel!.companyId;
      _currentPharmacyName = _currentUserModel!.name;
      _currentPharmacyId = _currentUserModel!.id;
      _currentRegionId = _currentUserModel!.regionId ?? 'sanaa';
      _currentRoleId = _currentUserModel!.roleId;
      _currentCustomPermissions = _currentUserModel!.customPermissions;
      _currentBranchId = _currentUserModel!.branchId;
      _currentCompanyName = _currentUserModel!.name;
      
      // تحميل صلاحيات الدور
      _currentPermissions = await _getRolePermissions(_currentRoleId!);
      
      _isLoggedIn = true;
      _isGuest = false;

      notifyListeners();
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: ${e.toString()}');
    }
  }

  // ========== إنشاء حساب جديد ==========
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
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      String? companyId;
      String? pharmacyId;

      if (userType == 'company') {
        companyId = uid;
        pharmacyId = null;
      } else if (userType == 'pharmacy') {
        companyId = null;
        pharmacyId = uid;
      } else {
        companyId = null;
        pharmacyId = null;
      }

      UserModel newUser = UserModel(
        id: uid,
        email: email,
        name: name,
        phone: phone,
        userType: userType,
        parentCompanyId: null,
        branchId: null,
        roleId: userType == 'company' ? 'role_owner' : 'role_pharmacy_owner',
        customPermissions: [],
        isActive: true,
        createdAt: DateTime.now(),
        licenseNumber: licenseNumber,
        isApproved: userType == 'pharmacy' ? false : true,
        address: address ?? '',
        companyId: companyId,
        pharmacyId: pharmacyId,
        regionId: regionId,
        assignedRegions: userType == 'company' ? Region.allRegions.map((r) => r.id).toList() : [],
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      await login(email, password);
    } catch (e) {
      throw Exception('فشل إنشاء الحساب: ${e.toString()}');
    }
  }

  // ========== تسجيل الخروج ==========
  Future<void> logout() async {
    await _auth.signOut();
    _currentUserModel = null;
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
    _currentCompanyName = null;
    notifyListeners();
  }

  // ========== جلب صلاحيات الدور من Firestore ==========
  Future<List<String>> _getRolePermissions(String roleId) async {
    try {
      DocumentSnapshot roleDoc = await _firestore.collection('roles').doc(roleId).get();
      if (roleDoc.exists) {
        Map<String, dynamic> data = roleDoc.data() as Map<String, dynamic>;
        return List<String>.from(data['defaultPermissions'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading role permissions: $e');
    }
    return [];
  }
}