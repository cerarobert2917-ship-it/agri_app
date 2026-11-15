import '../core/config.dart';
import '../services/api_client.dart';
import 'store_data.dart';

/// Stores + products for viewers, loaded from the database (GET /catalog).
/// This replaces the fixed sample data, so what viewers see is exactly what
/// store owners manage in their own Products tab.
class CatalogRepository {
  CatalogRepository._();
  static final CatalogRepository instance = CatalogRepository._();

  List<StoreMeta> stores = [];
  Map<String, StoreInfo> info = {};

  StoreMeta? metaFor(String key) {
    for (final s in stores) {
      if (s.key == key) return s;
    }
    return null;
  }

  Future<void> load() async {
    final data = await ApiClient.instance.get('/catalog');
    final list = (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final metas = <StoreMeta>[];
    final infos = <String, StoreInfo>{};

    for (final s in list) {
      final key = '${s['id']}';
      final name = '${s['name']}';
      final lat = double.tryParse('${s['latitude']}') ?? AppConfig.defaultLat;
      final lng = double.tryParse('${s['longitude']}') ?? AppConfig.defaultLng;
      final photo = _text(s['photo_url']);
      metas.add(StoreMeta(
        key,
        name,
        lat,
        lng,
        storeImageForName(name) ?? '',
        photoUrl: photo == null ? null : (photo.startsWith('http') ? photo : '${AppConfig.baseUrl}/$photo'),
      ));

      final products = <Product>[
        for (final p in (s['products'] as List? ?? []))
          _product(Map<String, dynamic>.from(p)),
      ];

      final ownerText = _text(s['opening_hours']);
      final parsed = _parseHours(ownerText);
      final known = _staticFor(name);
      if (parsed != null) {
        infos[key] = StoreInfo(products, parsed, hoursText: ownerText);
      } else if (known != null && known.hasHours) {
        infos[key] = StoreInfo(products, known.week, hoursFromGoogle: known.hoursFromGoogle, hoursText: ownerText);
      } else {
        infos[key] = StoreInfo(products, List<DayHours?>.filled(7, null), hoursText: ownerText);
      }
    }
    stores = metas;
    info = infos;
  }

  static String? _text(dynamic v) {
    final t = '${v ?? ''}'.trim();
    return (t.isEmpty || t == 'null') ? null : t;
  }

  static Product _product(Map<String, dynamic> p) {
    final packaging = _text(p['brand']) ?? '${p['unit']}';
    return Product(
      '${p['name']}',
      packaging,
      double.tryParse('${p['price']}') ?? 0,
      int.tryParse('${p['stock_quantity']}') ?? 0,
      '${p['category_name']}',
    );
  }

  /// Hours of the 4 known stores (from Google Maps), matched by name.
  static StoreInfo? _staticFor(String name) {
    final n = name.trim().toUpperCase();
    if (n.isEmpty) return null;
    for (final m in storeList) {
      final mn = m.name.toUpperCase();
      if (mn == n || mn.contains(n) || n.contains(mn)) return storeData[m.key];
    }
    return null;
  }

  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  /// Understands owner text such as "Mon-Sat 7:00AM-6:00PM". Returns null if it cannot.
  static List<DayHours?>? _parseHours(String? text) {
    if (text == null) return null;
    final m = RegExp(
      r'^\s*([A-Za-z]{3})[A-Za-z]*\s*(?:-|–|to)\s*([A-Za-z]{3})[A-Za-z]*\s+(\d{1,2})(?::(\d{2}))?\s*([AaPp][Mm])\s*(?:-|–|to)\s*(\d{1,2})(?::(\d{2}))?\s*([AaPp][Mm])\s*$',
    ).firstMatch(text);
    if (m == null) return null;
    final a = _days.indexOf(m.group(1)!.toLowerCase());
    final b = _days.indexOf(m.group(2)!.toLowerCase());
    if (a < 0 || b < 0) return null;
    int mins(String h, String? mm, String ap) {
      var x = int.parse(h) % 12;
      if (ap.toLowerCase() == 'pm') x += 12;
      return x * 60 + (mm == null ? 0 : int.parse(mm));
    }

    final open = mins(m.group(3)!, m.group(4), m.group(5)!);
    final close = mins(m.group(6)!, m.group(7), m.group(8)!);
    if (close <= open) return null;
    final week = List<DayHours?>.filled(7, null);
    var i = a;
    for (var n = 0; n < 7; n++) {
      week[i] = DayHours(open, close);
      if (i == b) break;
      i = (i + 1) % 7;
    }
    return week;
  }
}
