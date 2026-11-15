/// Sample na datos ng mga tindahan (products, stocks, presyo at oras).
/// Palitan na lang ng totoong datos o galing sa API kapag handa na.
class Product {
  final String name;
  final String unit; // hal. "50kg sack"
  final double price; // PHP
  final int stock;

  /// Kategorya galing sa listahan ng produkto (hal. "Rice seeds").
  final String category;
  const Product(this.name, this.unit, this.price, this.stock,
      [this.category = '']);
}

/// Pangkat na ginagamit sa pag-group ng produkto sa store details.
const productGroupOrder = ['Fertilizers', 'Rice Seeds', 'Vegetable Seeds', 'Others'];

String productGroup(String category) {
  final c = category.toLowerCase();
  if (c.contains('rice')) return 'Rice Seeds';
  if (c.contains('vegetable')) return 'Vegetable Seeds';
  if (c.contains('fertilizer')) return 'Fertilizers';
  return 'Others';
}

/// Oras ng bukas/sara, sa minuto mula hatinggabi. null = sarado buong araw.
class DayHours {
  final int open;
  final int close;
  const DayHours(this.open, this.close);
}

int _t(int h, [int m = 0]) => h * 60 + m;

class StoreInfo {
  final List<Product> products;

  /// 7 na araw: index 0 = Monday ... 6 = Sunday
  final List<DayHours?> week;
  final bool hoursFromGoogle; // true kung galing sa totoong Google Maps hours
  /// Oras na tinype ng owner (kapag hindi ma-parse sa 7 araw).
  final String? hoursText;
  const StoreInfo(this.products, this.week, {this.hoursFromGoogle = false, this.hoursText});

  /// May alam bang oras ang tindahan?
  bool get hasHours => week.any((d) => d != null);

  static const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  static const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String fmt(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final ap = h >= 12 ? 'PM' : 'AM';
    return '$h12:${m.toString().padLeft(2, '0')} $ap';
  }

  /// Oras sa Pilipinas (UTC+8), kahit ano pa ang timezone ng device.
  static DateTime phNow() =>
      DateTime.now().toUtc().add(const Duration(hours: 8));

  /// (bukas ba ngayon?, maikling paliwanag)
  ({bool open, String text}) status(DateTime now) {
    if (!hasHours) {
      final t = (hoursText ?? '').trim();
      return (open: false, text: t.isEmpty ? 'Store hours not set' : t);
    }
    final d = now.weekday - 1;
    final mins = now.hour * 60 + now.minute;
    final today = week[d];
    if (today != null && mins >= today.open && mins < today.close) {
      return (open: true, text: 'Open • Closes ${fmt(today.close)}');
    }
    if (today != null && mins < today.open) {
      return (open: false, text: 'Closed • Opens ${fmt(today.open)}');
    }
    for (var i = 1; i <= 7; i++) {
      final nd = (d + i) % 7;
      final h = week[nd];
      if (h != null) {
        return (
          open: false,
          text: 'Closed • Opens ${fmt(h.open)} ${dayShort[nd]}'
        );
      }
    }
    return (open: false, text: 'Closed');
  }
}

/// Mga tindahan sa Mamburao (key, pangalan, latitude, longitude).
/// Ginagamit ng mapa at ng search.
class StoreMeta {
  final String key;
  final String name;
  final double lat;
  final double lng;

  /// Larawan ng harapan ng tindahan (asset path).
  final String image;
  /// Larawan na in-upload (URL) kung mayroon.
  final String? photoUrl;
  const StoreMeta(this.key, this.name, this.lat, this.lng, this.image, {this.photoUrl});
}

/// Hanapin ang larawan ng harapan ng tindahan ayon sa pangalan (hal. 'SEVILLA'
/// o 'Sevilla Trading' -> sevilla.png). null kung walang tugma.
String? storeImageForName(String name) {
  final n = name.trim().toUpperCase();
  if (n.isEmpty) return null;
  for (final m in storeList) {
    final mn = m.name.toUpperCase();
    if (mn == n || mn.contains(n) || n.contains(mn)) return m.image;
  }
  return null;
}

const storeList = [
  StoreMeta('sevilla', 'SEVILLA TRADING', 13.221531, 120.600390,
      'assets/images/stores/sevilla.png'),
  StoreMeta('emma_lao', 'EMMA LAO', 13.217330, 120.603217,
      'assets/images/stores/emma_lao.png'),
  StoreMeta('mamburao_trading', 'MAMBURAO TRADING', 13.222781, 120.597125,
      'assets/images/stores/mamburao_trading.png'),
  StoreMeta('mpmpc', 'MPMPC', 13.266544, 120.621443,
      'assets/images/stores/mpmpc.png'),
];

/// Mga produkto, presyo at stock ng bawat tindahan (galing sa Agri_products_for_4_store.xlsx).
final Map<String, StoreInfo> storeData = {
  // Oras: galing sa Google Maps (screenshot)
  'sevilla': StoreInfo(
    const [
      Product('Urea 46-0-0 Fertilizer', '50kg sack', 1840, 12, 'Fertilizer'),
      Product('Complete 14-14-14 Fertilizer', '50kg sack', 1710, 20, 'Fertilizer'),
      Product('DAP 18-46-0 Fertilizer', '50kg sack', 2440, 15, 'Fertilizer'),
      Product('Muriate of Potash (MOP) 0-0-60', '50kg sack', 2180, 8, 'Fertilizer'),
      Product('Solophos 0-18-0 Fertilizer', '50kg sack', 1030, 25, 'Fertilizer'),
      Product('NPK 14-14-14 Fertilizer', '50kg sack', 1735, 15, 'Fertilizer'),
      Product('NSIC Rc 222 Rice Seeds', '20kg sack', 1460, 15, 'Rice seeds'),
      Product('NSIC Rc 160 Rice Seeds', '20kg sack', 1580, 8, 'Rice seeds'),
      Product('NSIC Rc 216 Rice Seeds', '20kg sack', 1505, 9, 'Rice seeds'),
      Product('NSIC Rc 402 Rice Seeds', '20kg sack', 1620, 12, 'Rice seeds'),
      Product('Tomato Seeds', '10g pack', 250, 46, 'Vegetable seeds'),
      Product('Eggplant Seeds', '10g pack', 90, 38, 'Vegetable seeds'),
      Product('Ammonium Sulfate 21-0-0', '50kg sack', 1400, 16, 'Fertilizer'),
      Product('Zinc Sulfate', '1kg pack', 240, 16, 'Fertilizer'),
      Product('Magnesium Sulfate', '1kg pack', 160, 22, 'Fertilizer'),
      Product('Organic Compost', '25kg sack', 260, 28, 'Fertilizer / soil amendment'),
      Product('NSIC Rc 300 Rice Seeds', '20kg sack', 1570, 7, 'Rice seeds'),
      Product('NSIC Rc 124 Rice Seeds', '20kg sack', 1470, 5, 'Rice seeds'),
      Product('Pechay Seeds', '10g pack', 35, 48, 'Vegetable seeds'),
      Product('Watermelon Seeds', '10g pack', 125, 16, 'Vegetable seeds'),
    ],
    [
      for (var i = 0; i < 6; i++) DayHours(_t(8), _t(17, 30)),
      null,
    ],
    hoursFromGoogle: true,
  ),
  'mamburao_trading': StoreInfo(
    const [
      Product('Urea 46-0-0 Fertilizer', '50kg sack', 1920, 20, 'Fertilizer'),
      Product('Complete 14-14-14 Fertilizer', '50kg sack', 1730, 16, 'Fertilizer'),
      Product('DAP 18-46-0 Fertilizer', '50kg sack', 2540, 14, 'Fertilizer'),
      Product('Muriate of Potash (MOP) 0-0-60', '50kg sack', 2220, 14, 'Fertilizer'),
      Product('Solophos 0-18-0 Fertilizer', '50kg sack', 1080, 16, 'Fertilizer'),
      Product('NPK 14-14-14 Fertilizer', '50kg sack', 1795, 19, 'Fertilizer'),
      Product('NSIC Rc 222 Rice Seeds', '20kg sack', 1510, 10, 'Rice seeds'),
      Product('NSIC Rc 160 Rice Seeds', '20kg sack', 1610, 13, 'Rice seeds'),
      Product('NSIC Rc 216 Rice Seeds', '20kg sack', 1560, 10, 'Rice seeds'),
      Product('NSIC Rc 402 Rice Seeds', '20kg sack', 1695, 10, 'Rice seeds'),
      Product('Tomato Seeds', '10g pack', 275, 32, 'Vegetable seeds'),
      Product('Eggplant Seeds', '10g pack', 105, 30, 'Vegetable seeds'),
      Product('Ammonium Sulfate 21-0-0', '50kg sack', 1455, 22, 'Fertilizer'),
      Product('Potassium Sulfate 0-0-50', '50kg sack', 2385, 14, 'Fertilizer'),
      Product('Calcium Nitrate', '25kg sack', 2015, 13, 'Fertilizer'),
      Product('Boron Fertilizer', '1kg pack', 355, 19, 'Fertilizer'),
      Product('NSIC Rc 124 Rice Seeds', '20kg sack', 1525, 11, 'Rice seeds'),
      Product('Hybrid Rice Seeds', '5kg pack', 2885, 12, 'Rice seeds'),
      Product('Pechay Seeds', '10g pack', 90, 54, 'Vegetable seeds'),
      Product('Cucumber Seeds', '10g pack', 140, 33, 'Vegetable seeds'),
    ],
    [
      for (var i = 0; i < 6; i++) DayHours(_t(7, 30), _t(17, 30)),
      null,
    ],
    hoursFromGoogle: true,
  ),
  // Sample na oras (gawa-gawa muna)
  'emma_lao': StoreInfo(
    const [
      Product('Urea 46-0-0 Fertilizer', '50kg sack', 1895, 17, 'Fertilizer'),
      Product('Complete 14-14-14 Fertilizer', '50kg sack', 1660, 25, 'Fertilizer'),
      Product('DAP 18-46-0 Fertilizer', '50kg sack', 2500, 10, 'Fertilizer'),
      Product('Muriate of Potash (MOP) 0-0-60', '50kg sack', 2195, 12, 'Fertilizer'),
      Product('Solophos 0-18-0 Fertilizer', '50kg sack', 1065, 22, 'Fertilizer'),
      Product('NPK 14-14-14 Fertilizer', '50kg sack', 1780, 10, 'Fertilizer'),
      Product('NSIC Rc 222 Rice Seeds', '20kg sack', 1530, 13, 'Rice seeds'),
      Product('NSIC Rc 160 Rice Seeds', '20kg sack', 1550, 14, 'Rice seeds'),
      Product('NSIC Rc 216 Rice Seeds', '20kg sack', 1545, 5, 'Rice seeds'),
      Product('NSIC Rc 402 Rice Seeds', '20kg sack', 1670, 7, 'Rice seeds'),
      Product('Tomato Seeds', '10g pack', 265, 36, 'Vegetable seeds'),
      Product('Eggplant Seeds', '10g pack', 107, 33, 'Vegetable seeds'),
      Product('Ammonium Sulfate 21-0-0', '50kg sack', 1435, 20, 'Fertilizer'),
      Product('Zinc Sulfate', '1kg pack', 275, 20, 'Fertilizer'),
      Product('Agricultural Lime', '50kg sack', 365, 28, 'Fertilizer / soil amendment'),
      Product('Vermicast', '25kg sack', 405, 23, 'Fertilizer / soil amendment'),
      Product('NSIC Rc 124 Rice Seeds', '20kg sack', 1505, 9, 'Rice seeds'),
      Product('Hybrid Rice Seeds', '5kg pack', 2865, 10, 'Rice seeds'),
      Product('Pechay Seeds', '10g pack', 70, 52, 'Vegetable seeds'),
      Product('Cucumber Seeds', '10g pack', 120, 31, 'Vegetable seeds'),
    ],
    [
      for (var i = 0; i < 6; i++) DayHours(_t(7), _t(17)),
      null,
    ],
  ),
  'mpmpc': StoreInfo(
    const [
      Product('Urea 46-0-0 Fertilizer', '50kg sack', 1870, 15, 'Fertilizer'),
      Product('Complete 14-14-14 Fertilizer', '50kg sack', 1690, 22, 'Fertilizer'),
      Product('DAP 18-46-0 Fertilizer', '50kg sack', 2480, 11, 'Fertilizer'),
      Product('Muriate of Potash (MOP) 0-0-60', '50kg sack', 2150, 10, 'Fertilizer'),
      Product('Solophos 0-18-0 Fertilizer', '50kg sack', 1050, 20, 'Fertilizer'),
      Product('NPK 14-14-14 Fertilizer', '50kg sack', 1760, 13, 'Fertilizer'),
      Product('NSIC Rc 222 Rice Seeds', '20kg sack', 1480, 12, 'Rice seeds'),
      Product('NSIC Rc 160 Rice Seeds', '20kg sack', 1560, 9, 'Rice seeds'),
      Product('NSIC Rc 216 Rice Seeds', '20kg sack', 1520, 7, 'Rice seeds'),
      Product('NSIC Rc 402 Rice Seeds', '20kg sack', 1650, 8, 'Rice seeds'),
      Product('Tomato Seeds', '10g pack', 260, 40, 'Vegetable seeds'),
      Product('Eggplant Seeds', '10g pack', 95, 35, 'Vegetable seeds'),
      Product('Ammonium Sulfate 21-0-0', '50kg sack', 1420, 18, 'Fertilizer'),
      Product('Zinc Sulfate', '1kg pack', 260, 18, 'Fertilizer'),
      Product('Agricultural Lime', '50kg sack', 350, 26, 'Fertilizer / soil amendment'),
      Product('Humic Acid Liquid Fertilizer', '1 liter bottle', 450, 9, 'Fertilizer'),
      Product('Hybrid Rice Seeds', '5kg pack', 2850, 8, 'Rice seeds'),
      Product('NSIC Rc 300 Rice Seeds', '20kg sack', 1590, 9, 'Rice seeds'),
      Product('Pechay Seeds', '10g pack', 55, 50, 'Vegetable seeds'),
      Product('Squash Seeds', '10g pack', 90, 26, 'Vegetable seeds'),
    ],
    [
      for (var i = 0; i < 5; i++) DayHours(_t(8), _t(17)),
      DayHours(_t(8), _t(12)), // Saturday
      null, // Sunday
    ],
  ),
};
