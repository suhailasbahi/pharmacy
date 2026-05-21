class CurrencyConstants {
  static const String yer = 'YER';
  static const String sar = 'SAR';

  static const String yerSymbol = 'ر.ي';
  static const String sarSymbol = 'ر.س';

  // العملة الأساسية للنظام
  static const String baseCurrency = yer;

  // سعر الصرف الافتراضي
  static const double defaultSarRate = 140.0;

  static List<String> supportedCurrencies = [
    yer,
    sar,
  ];
}