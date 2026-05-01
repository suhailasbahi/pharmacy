class RegionPricing {
  final String regionId; // 'sanaa', 'aden', 'taiz', etc.
  final String regionName;
  final double price;
  final String currency; // 'yemen', 'saudi', 'dollar'
  final double taxRate;

  RegionPricing({
    required this.regionId,
    required this.regionName,
    required this.price,
    required this.currency,
    this.taxRate = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'regionId': regionId,
      'regionName': regionName,
      'price': price,
      'currency': currency,
      'taxRate': taxRate,
    };
  }

  factory RegionPricing.fromMap(Map<String, dynamic> map) {
    return RegionPricing(
      regionId: map['regionId'] ?? '',
      regionName: map['regionName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'yemen',
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
    );
  }
}