class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String userType; // 'pharmacy' or 'company'
  final String licenseNumber;
  final String? licenseImageUrl;
  final bool isApproved;
  final String regionId; // selected region during registration
  final String? address;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    required this.licenseNumber,
    this.licenseImageUrl,
    required this.isApproved,
    required this.regionId,
    this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType,
      'licenseNumber': licenseNumber,
      'licenseImageUrl': licenseImageUrl,
      'isApproved': isApproved,
      'regionId': regionId,
      'address': address,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      licenseImageUrl: map['licenseImageUrl'],
      isApproved: map['isApproved'] ?? false,
      regionId: map['regionId'] ?? 'sanaa',
      address: map['address'],
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
    );
  }
}