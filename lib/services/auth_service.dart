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
  String? _currentRegionId;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String? _currentRoleId;
  List<String> _currentPermissions = [];
  String? _currentBranchId;
  List<String> _currentCustomPermissions = [];
  String? _currentCompanyName;

  String? get currentUserId => _currentUserModel?.id;
  String? get currentUserType => _currentUserType;
  String? get currentCompanyName => _currentUserModel?.name;
  String? get currentCompanyId => _currentCompanyId;
  String? get currentPharmacyName => _currentPharmacyName;
  String? get currentRegionId => _currentRegionId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String? get currentRoleId => _currentRoleId;
  String? get currentBranchId => _currentBranchId;
  bool get isCompanyOwner => _currentUserType == 'company';

  // ========== الصلاحيات (مؤقتة، ستُقرأ من Firestore لاحقاً) ==========
  List<String> get permissions => isCompanyOwner ? allPermissions : [];
  bool hasPermission(String permission) => isCompanyOwner;
  bool get canViewAllProducts => isCompanyOwner;
  bool get canViewOwnProducts => false;
  bool get canAddProduct => isCompanyOwner;
  bool get canEditProduct => isCompanyOwner;
  bool get canDeleteProduct => isCompanyOwner;
  bool get canViewAllOrders => isCompanyOwner;
  bool get canViewOwnOrders => false;
  bool get canAcceptOrder => isCompanyOwner;
  bool get canRejectOrder => isCompanyOwner;
  bool get canShipOrder => isCompanyOwner;
  bool get canDeliverOrder => isCompanyOwner;
  bool get canViewAllCustomers => isCompanyOwner;
  bool get canViewOwnCustomers => false;
  bool get canAddCustomer => isCompanyOwner;
  bool get canEditCustomer => isCompanyOwner;
  bool get canDeleteCustomer => isCompanyOwner;
  bool get canViewFinancialReports => isCompanyOwner;
  bool get canViewSalesReports => isCompanyOwner;
  bool get canViewInventoryReports => isCompanyOwner;
  bool get canViewAllReports => isCompanyOwner;
  bool get canManageUsers => isCompanyOwner;
  bool get canManageBranches => isCompanyOwner;
  bool get canManageRoles => isCompanyOwner;
  bool get canViewInventory => isCompanyOwner;
  bool get canAdjustInventory => isCompanyOwner;

  // ========== دوال الفرع والمناطق ==========
  bool get isBranchManager => _currentRoleId == 'role_branch_manager' && _currentBranchId != null;
  String? getEffectiveBranchId() => isBranchManager ? _currentBranchId : null;

  // المناطق المسموحة للمستخدم (إذا كان مدير فرع أو مندوب)
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
      if (!doc.exists) throw Exception('المستخدم غير موجود في قاعدة البيانات');
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['isDeleted'] == true) throw Exception('هذا الحساب محذوف. يرجى التواصل مع الدعم.');

      _currentUserModel = UserModel.fromMap(uid, data);
      _currentUserType = _currentUserModel!.userType;
      _currentCompanyId = _currentUserModel!.parentCompanyId ?? _currentUserModel!.companyId;
      _currentPharmacyName = _currentUserModel!.name;
      _currentRegionId = _currentUserModel!.regionId ?? 'sanaa';
      _currentRoleId = _currentUserModel!.roleId;
      _currentPermissions = await _getRolePermissions(_currentRoleId!);
      _currentCustomPermissions = _currentUserModel!.customPermissions;
      _currentBranchId = _currentUserModel!.branchId;
      _currentCompanyName = _currentUserModel!.name;
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
      UserModel newUser = UserModel(
        id: uid,
        email: email,
        name: name,
        phone: phone,
        userType: userType,
        parentCompanyId: userType == 'sub_account' ? null : uid,
        branchId: null,
        roleId: userType == 'company' ? 'role_owner' : 'role_pharmacy_owner',
        customPermissions: [],
        isActive: true,
        createdAt: DateTime.now(),
        licenseNumber: licenseNumber,
        isApproved: userType == 'pharmacy' ? false : true,
        address: address,
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

  // ========== مساعدة ==========
  Future<List<String>> _getRolePermissions(String roleId) async {
    try {
      DocumentSnapshot roleDoc = await _firestore.collection('roles').doc(roleId).get();
      if (roleDoc.exists) {
        Map<String, dynamic> data = roleDoc.data() as Map<String, dynamic>;
        return List<String>.from(data['defaultPermissions'] ?? []);
      }
    } catch (e) {}
    return [];
  }
}