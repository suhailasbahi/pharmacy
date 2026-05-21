class RegionPricing {
  final String regionId; // 'sanaa', 'aden', 'taiz', etc.
  final String regionName;
  final double price;
  final String currency; // 'yemen', 'saudi', 'dollar'
  final bool hasOffer;      // هل هذا السعر له عرض؟
  final double? offerPrice; // سعر العرض (إذا موجود)

  RegionPricing({
    required this.regionId,
    required this.regionName,
    required this.price,
    required this.currency,
    this.hasOffer = false,
    this.offerPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'regionId': regionId,
      'regionName': regionName,
      'price': price,
      'currency': currency,
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
      hasOffer: map['hasOffer'] ?? false,
      offerPrice: map['offerPrice']?.toDouble(),
    );
  }

  // الحصول على السعر النهائي (مع مراعاة العرض)
  double getFinalPrice() {
    return (hasOffer && offerPrice != null) ? offerPrice! : price;
  }

  // الحصول على السعر الأصلي
  double getBasePrice() {
    return price;
  }
}