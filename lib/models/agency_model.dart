import 'product_model.dart';

class AgencyModel {
  final String id;
  final String name;
  final String companyId;
  final String companyName;
  final String? logoUrl;
  final List<ProductModel> products;
  final bool isActive;

  AgencyModel({
    required this.id,
    required this.name,
    required this.companyId,
    required this.companyName,
    this.logoUrl,
    required this.products,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'companyId': companyId,
      'companyName': companyName,
      'logoUrl': logoUrl,
      'products': products.map((p) => p.toMap()).toList(),
      'isActive': isActive,
    };
  }

  factory AgencyModel.fromMap(String id, Map<String, dynamic> map) {
    return AgencyModel(
      id: id,
      name: map['name'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      logoUrl: map['logoUrl'],
      products: (map['products'] as List?)?.map((p) => ProductModel.fromMap(p['id'] ?? '', p)).toList() ?? [],
      isActive: map['isActive'] ?? true,
    );
  }
}