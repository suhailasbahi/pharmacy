class BranchModel {
  final String id;
  final String companyId;
  final String regionId;
  final String city;
  final String address;
  final String phone;
  final String? workingHours;
  final bool isActive;

  BranchModel({
    required this.id,
    required this.companyId,
    required this.regionId,
    required this.city,
    required this.address,
    required this.phone,
    this.workingHours,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'regionId': regionId,
      'city': city,
      'address': address,
      'phone': phone,
      'workingHours': workingHours,
      'isActive': isActive,
    };
  }

  factory BranchModel.fromMap(String id, Map<String, dynamic> map) {
    return BranchModel(
      id: id,
      companyId: map['companyId'] ?? '',
      regionId: map['regionId'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      workingHours: map['workingHours'],
      isActive: map['isActive'] ?? true,
    );
  }
}