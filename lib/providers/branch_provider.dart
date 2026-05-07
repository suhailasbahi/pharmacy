import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch_model.dart';

class BranchProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BranchModel> _branches = [];

  List<BranchModel> get branches => _branches;

  Stream<List<BranchModel>> streamBranches(String companyId) {
    return _firestore
        .collection('branches')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BranchModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> loadBranches(String companyId) async {
    final snapshot = await _firestore
        .collection('branches')
        .where('companyId', isEqualTo: companyId)
        .get();
    _branches = snapshot.docs
        .map((doc) => BranchModel.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
  }

  Future<void> addBranch(BranchModel branch) async {
    await _firestore.collection('branches').doc(branch.id).set(branch.toMap());
    _branches.add(branch);
    notifyListeners();
  }

  Future<void> updateBranch(BranchModel branch) async {
    await _firestore.collection('branches').doc(branch.id).update(branch.toMap());
    final index = _branches.indexWhere((b) => b.id == branch.id);
    if (index != -1) _branches[index] = branch;
    notifyListeners();
  }

  Future<void> deleteBranch(String id) async {
    await _firestore.collection('branches').doc(id).delete();
    _branches.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}