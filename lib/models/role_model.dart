class RoleModel {
  final String id;
  final String name;
  final String description;
  final List<String> defaultPermissions;

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPermissions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'defaultPermissions': defaultPermissions,
    };
  }

  factory RoleModel.fromMap(String id, Map<String, dynamic> map) {
    return RoleModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      defaultPermissions: List<String>.from(map['defaultPermissions'] ?? []),
    );
  }
}