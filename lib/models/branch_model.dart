class BranchModel {
  final String id;
  final String companyId;
  final String name;           // اسم الفرع (مثل "فرع صنعاء")
  final String regionId;
  final String city;
  final String address;
  final String phone;
  final String? managerUserId; // معرف مدير الفرع (من نوع sub_account)
  final String? workingHours;
  final bool isActive;

  BranchModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.regionId,
    required this.city,
    required this.address,
    required this.phone,
    this.managerUserId,
    this.workingHours,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'regionId': regionId,
      'city': city,
      'address': address,
      'phone': phone,
      'managerUserId': managerUserId,
      'workingHours': workingHours,
      'isActive': isActive,
    };
  }

  factory BranchModel.fromMap(String id, Map<String, dynamic> map) {
    return BranchModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      regionId: map['regionId'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      managerUserId: map['managerUserId'],
      workingHours: map['workingHours'],
      isActive: map['isActive'] ?? true,
    );
  }
}