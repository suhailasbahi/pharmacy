import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _subAccounts = [];

  List<UserModel> get subAccounts => _subAccounts;

  Future<void> loadSubAccounts(String companyId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('parentCompanyId', isEqualTo: companyId)
        .where('userType', isEqualTo: 'sub_account')
        .get();
    _subAccounts = snapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList();
    notifyListeners();
  }

  Future<void> addSubAccount(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
    _subAccounts.add(user);
    notifyListeners();
  }

  Future<void> updateSubAccount(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
    final index = _subAccounts.indexWhere((u) => u.id == user.id);
    if (index != -1) _subAccounts[index] = user;
    notifyListeners();
  }

  Future<void> deleteSubAccount(String id) async {
    await _firestore.collection('users').doc(id).delete();
    _subAccounts.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  Future<List<UserModel>> getSubAccountsForBranch(String branchId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('branchId', isEqualTo: branchId)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> loadSampleData(String companyId) async {
    await loadSubAccounts(companyId);
  }
}