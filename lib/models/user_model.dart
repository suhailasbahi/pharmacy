class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String userType;
  final String? parentCompanyId;
  final String? branchId;
  final String roleId;
  final List<String> customPermissions;
  final bool isActive;
  final DateTime createdAt;
  final String? licenseNumber;
  final String? licenseImageUrl;
  final bool isApproved;
  final String? address;        // العنوان التفصيلي (مثال: "شارع التعاون، صنعاء")
  final String? companyId;
  final String? pharmacyId;
  final String? regionId;        // جديد: معرف المنطقة (مثل 'sanaa', 'aden')
    
    final List<String> assignedRegions; // جديد (قائمة معرفات المناطق)

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.parentCompanyId,
    this.branchId,
    required this.roleId,
    this.customPermissions = const [],
    this.isActive = true,
    required this.createdAt,
    this.licenseNumber,
    this.licenseImageUrl,
    this.isApproved = false,
    this.address,
    this.companyId,
    this.pharmacyId,
    this.regionId,
    this.assignedRegions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType,
      'parentCompanyId': parentCompanyId,
      'branchId': branchId,
      'roleId': roleId,
      'customPermissions': customPermissions,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'licenseNumber': licenseNumber,
      'licenseImageUrl': licenseImageUrl,
      'isApproved': isApproved,
      'address': address,
      'companyId': companyId,
      'pharmacyId': pharmacyId,
      'regionId': regionId,
      'assignedRegions': assignedRegions,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] ?? '',
      parentCompanyId: map['parentCompanyId'],
      branchId: map['branchId'],
      roleId: map['roleId'] ?? '',
      customPermissions: List<String>.from(map['customPermissions'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      licenseNumber: map['licenseNumber'],
      licenseImageUrl: map['licenseImageUrl'],
      isApproved: map['isApproved'] ?? false,
      address: map['address'],
      companyId: map['companyId'],
      pharmacyId: map['pharmacyId'],
      regionId: map['regionId'],
      assignedRegions: List<String>.from(map['assignedRegions'] ?? []),
    );
  }
}