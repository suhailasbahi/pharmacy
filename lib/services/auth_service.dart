import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  String? _currentUserId;
  String? _currentUserType;
  String? _currentCompanyId;
  String? _currentPharmacyName;
  String? _currentRegionId;
  bool _isLoggedIn = false;
  bool _isGuest = false;

  String? get currentUserId => _currentUserId;
  String? get currentUserType => _currentUserType;
  String? get currentCompanyId => _currentCompanyId;
  String? get currentPharmacyName => _currentPharmacyName;
  String? get currentRegionId => _currentRegionId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;

  // Guest mode: only browse, cannot checkout
  void enterAsGuest(String regionId) {
    _isGuest = true;
    _isLoggedIn = false;
    _currentRegionId = regionId;
    _currentUserId = null;
    _currentUserType = null;
    _currentCompanyId = null;
    _currentPharmacyName = null;
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
    } else {
      _currentUserId = 'pharmacy_demo_123';
      _currentUserType = 'pharmacy';
      _currentCompanyId = null;
      _currentPharmacyName = 'صيدلية التجريبية';
      _currentRegionId = 'sanaa';
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
    notifyListeners();
  }
}