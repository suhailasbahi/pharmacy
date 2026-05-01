import 'product_model.dart';
import 'agency_model.dart';
import 'region_pricing.dart';

final dummyAgencies = [
  AgencyModel(
    id: 'agency_1',
    name: 'وكالة الخليج',
    companyId: 'comp_001',
    companyName: 'شركة الأدوية العربية',
    products: [
      ProductModel(
        id: 'p1',
        companyId: 'comp_001',
        companyName: 'شركة الأدوية العربية',
        name: 'بنادول',
        scientificName: 'باراسيتامول',
        concentration: '500mg',
        stockQuantity: 100,
        requiresCooling: false,
        expiryDate: DateTime(2025,12,31),
        isActive: true,
        createdAt: DateTime.now(),
        regionPrices: [RegionPricing(regionId: 'sanaa', regionName: 'صنعاء', price: 15.0, currency: 'yemen')],
        bonusCash: null,
        bonusCredit: null,
        pricePerPiece: 0.15,
        pricePerCarton: 12.0,
        piecesPerCarton: 100,
        defaultUnit: 'carton',
        minOrderQuantity: 1,
        hasOffer: true,
        offerPrice: 12.0,
      ),
      // أضف منتجات أخرى حسب الحاجة
    ],
  ),
];