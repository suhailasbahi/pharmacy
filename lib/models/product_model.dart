import 'region_pricing.dart';
import 'bonus_model.dart';

class ProductModel {
  final String id;
  final String companyId;
  final String companyName;
  final String name;
  final String scientificName;
  final String concentration;
  final int stockQuantity;
  final bool requiresCooling;
  final String? imageUrl;
  final DateTime expiryDate;
  final bool isActive;
  final DateTime createdAt;
  final List<RegionPricing> regionPrices;
  final BonusModel? bonusCash;
  final BonusModel? bonusCredit;
  final double pricePerPiece;
  final double pricePerCarton;
  final int piecesPerCarton;
  final String defaultUnit;
  final int minOrderQuantity;
  final bool hasOffer;
  final double? offerPrice;
  final String? createdBy;

  ProductModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.scientificName,
    required this.concentration,
    required this.stockQuantity,
    required this.requiresCooling,
    this.imageUrl,
    required this.expiryDate,
    required this.isActive,
    required this.createdAt,
    required this.regionPrices,
    this.bonusCash,
    this.bonusCredit,
    this.pricePerPiece = 0,
    this.pricePerCarton = 0,
    this.piecesPerCarton = 1,
    this.defaultUnit = 'piece',
    this.minOrderQuantity = 1,
    this.hasOffer = false,
    this.offerPrice,
    this.createdBy,
  });

  // ========== الدوال المطلوبة ==========
  double getBasePriceForRegion(String regionId) {
    final pricing = regionPrices.firstWhere(
      (p) => p.regionId == regionId,
      orElse: () => regionPrices.isNotEmpty ? regionPrices.first : RegionPricing(regionId: regionId, regionName: '', price: 0, currency: 'yemen'),
    );
    return pricing.price;
  }

  double getFinalPriceForRegion(String regionId) {
    final pricing = regionPrices.firstWhere(
      (p) => p.regionId == regionId,
      orElse: () => regionPrices.isNotEmpty ? regionPrices.first : RegionPricing(regionId: regionId, regionName: '', price: 0, currency: 'yemen'),
    );
    return pricing.price + (pricing.price * pricing.taxRate / 100);
  }

  String getCurrencyForRegion(String regionId) {
    final pricing = regionPrices.firstWhere(
      (p) => p.regionId == regionId,
      orElse: () => regionPrices.isNotEmpty ? regionPrices.first : RegionPricing(regionId: regionId, regionName: '', price: 0, currency: 'yemen'),
    );
    return pricing.currency;
  }

  String get currencySymbol {
    final firstCurrency = regionPrices.isNotEmpty ? regionPrices.first.currency : 'yemen';
    switch (firstCurrency) {
      case 'yemen': return 'ر.ي';
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  // باقي الدوال (toMap, fromMap) كما هي موجودة مسبقاً
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'name': name,
      'scientificName': scientificName,
      'concentration': concentration,
      'stockQuantity': stockQuantity,
      'requiresCooling': requiresCooling,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'regionPrices': regionPrices.map((p) => p.toMap()).toList(),
      'bonusCash': bonusCash?.toMap(),
      'bonusCredit': bonusCredit?.toMap(),
      'pricePerPiece': pricePerPiece,
      'pricePerCarton': pricePerCarton,
      'piecesPerCarton': piecesPerCarton,
      'defaultUnit': defaultUnit,
      'minOrderQuantity': minOrderQuantity,
      'hasOffer': hasOffer,
      'offerPrice': offerPrice,
      'createdBy': createdBy,
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      concentration: map['concentration'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
      requiresCooling: map['requiresCooling'] ?? false,
      imageUrl: map['imageUrl'],
      expiryDate: DateTime.parse(map['expiryDate'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      regionPrices: (map['regionPrices'] as List?)?.map((p) => RegionPricing.fromMap(p)).toList() ?? [],
      bonusCash: map['bonusCash'] != null ? BonusModel.fromMap(map['bonusCash']) : null,
      bonusCredit: map['bonusCredit'] != null ? BonusModel.fromMap(map['bonusCredit']) : null,
      pricePerPiece: (map['pricePerPiece'] ?? 0).toDouble(),
      pricePerCarton: (map['pricePerCarton'] ?? 0).toDouble(),
      piecesPerCarton: map['piecesPerCarton'] ?? 1,
      defaultUnit: map['defaultUnit'] ?? 'piece',
      minOrderQuantity: map['minOrderQuantity'] ?? 1,
      hasOffer: map['hasOffer'] ?? false,
      offerPrice: map['offerPrice']?.toDouble(),
      createdBy: map['createdBy'],
    );
  }
}