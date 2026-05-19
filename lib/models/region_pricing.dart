class RegionPricing {
  final String regionId; // 'sanaa', 'aden', 'taiz', etc.
  final String regionName;
  final double price;
  final String currency; // 'yemen', 'saudi', 'dollar'
  final double taxRate;
  final bool hasOffer;      // جديد: هل هذا السعر له عرض؟
  final double? offerPrice; // جديد: سعر العرض (إذا موجود)

  RegionPricing({
    required this.regionId,
    required this.regionName,
    required this.price,
    required this.currency,
    this.taxRate = 0.0,
    this.hasOffer = false,
    this.offerPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'regionId': regionId,
      'regionName': regionName,
      'price': price,
      'currency': currency,
      'taxRate': taxRate,
      'hasOffer': hasOffer,
      'offerPrice': offerPrice,
    };
  }

  factory RegionPricing.fromMap(Map<String, dynamic> map) {
    return RegionPricing(
      regionId: map['regionId'] ?? '',
      regionName: map['regionName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'yemen',
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
      hasOffer: map['hasOffer'] ?? false,
      offerPrice: map['offerPrice']?.toDouble(),
    );
  }

  // الحصول على السعر النهائي (بعد الضريبة) مع مراعاة العرض
  double getFinalPrice() {
    final basePrice = (hasOffer && offerPrice != null) ? offerPrice! : price;
    return basePrice + (basePrice * taxRate / 100);
  }

  // الحصول على السعر الأصلي (قبل الضريبة) مع مراعاة العرض
  double getBasePrice() {
    return (hasOffer && offerPrice != null) ? offerPrice! : price;
  }
}