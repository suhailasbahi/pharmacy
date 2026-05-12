class Region {
  final String id;   // المعرف (مثل 'sanaa')
  final String name; // الاسم العربي (مثل 'صنعاء')

  const Region(this.id, this.name);

  static const List<Region> allRegions = [
    Region('sanaa', 'صنعاء'),
    Region('aden', 'عدن'),
    Region('taiz', 'تعز'),
    Region('hodeidah', 'الحديدة'),
    Region('ibb', 'إب'),
    Region('abyan', 'أبين'),
    Region('shabwah', 'شبوة'),
    Region('hadhramaut', 'حضرموت'),
    Region('lahij', 'لحج'),
    Region('dhalee', 'الضالع'),
    Region('mahrah', 'المهرة'),
    Region('bayda', 'البيضاء'),
    Region('jawf', 'الجوف'),
    Region('amran', 'عمران'),
    Region('dhamar', 'ذمار'),
    Region('hajjah', 'حجة'),
    Region('marib', 'مأرب'),
    Region('raymah', 'ريمة'),
    Region('sadah', 'صعدة'),
    Region('socotra', 'سقطرى'),
    Region('mukalla', 'المكلا'),   // مدن رئيسية داخل حضرموت
    Region('sayun', 'سيئون'),
  ];

  static String getNameById(String id) {
    return allRegions.firstWhere((r) => r.id == id, orElse: () => allRegions.first).name;
  }

  static String getIdByName(String name) {
    return allRegions.firstWhere((r) => r.name == name, orElse: () => allRegions.first).id;
  }
}