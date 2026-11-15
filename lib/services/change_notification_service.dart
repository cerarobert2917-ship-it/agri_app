import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

/// Isang pagbabago ng presyo at/o stock na ginawa ng owner.
class ChangeItem {
  final int id;
  final String productName;
  final String packaging;
  final String storeName;
  final double? oldPrice, newPrice;
  final int? oldStock, newStock;
  final DateTime? createdAt;

  const ChangeItem({
    required this.id,
    required this.productName,
    required this.packaging,
    required this.storeName,
    this.oldPrice,
    this.newPrice,
    this.oldStock,
    this.newStock,
    this.createdAt,
  });

  bool get priceChanged => oldPrice != null && newPrice != null;
  bool get stockChanged => oldStock != null && newStock != null;

  factory ChangeItem.fromJson(Map<String, dynamic> j) {
    String? t(dynamic v) {
      final s = '${v ?? ''}'.trim();
      return (s.isEmpty || s == 'null') ? null : s;
    }

    return ChangeItem(
      id: int.tryParse('${j['id']}') ?? 0,
      productName: '${j['product_name']}',
      packaging: t(j['brand']) ?? '${j['unit']}',
      storeName: '${j['store_name']}',
      oldPrice: double.tryParse('${j['old_price']}'),
      newPrice: double.tryParse('${j['new_price']}'),
      oldStock: int.tryParse('${j['old_stock']}'),
      newStock: int.tryParse('${j['new_stock']}'),
      createdAt: DateTime.tryParse('${j['created_at']}'.replaceFirst(' ', 'T')),
    );
  }
}

/// Kumukuha ng mga update sa presyo/stock para sa Notifications tab ng viewer.
class ChangeNotificationService extends ChangeNotifier {
  final _api = ApiClient.instance;
  final _store = const FlutterSecureStorage();

  List<ChangeItem> items = [];
  int lastSeenId = 0;
  int _latestId = 0;
  int _unread = 0;
  bool alertsOn = true;
  bool loading = false;
  bool loadedOnce =
      false; // tapos na ba ang unang pag-load (para sa loading state)
  String? error;
  Timer? _timer;
  bool _disposed = false;

  /// Bilang na nasa badge. Zero kapag naka-off ang "Price alerts" sa Profile.
  int get badgeCount => alertsOn ? _unread : 0;

  /// Ilan ang hindi pa nababasa (para sa "Mark all as read").
  int get unreadCount => _unread;

  void start() {
    refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_disposed) return;
    loading = true;
    try {
      alertsOn = (await _store.read(key: 'pref_price_alerts')) != 'off';
      final d =
          Map<String, dynamic>.from(await _api.get('/notifications/changes'));
      items = [
        for (final e in (d['items'] as List? ?? []))
          ChangeItem.fromJson(Map<String, dynamic>.from(e))
      ];
      _latestId = int.tryParse('${d['latest_id']}') ?? 0;
      lastSeenId = int.tryParse('${d['last_seen_id']}') ?? 0;
      _unread = int.tryParse('${d['unread_count']}') ?? 0;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    loadedOnce = true;
    if (!_disposed) notifyListeners();
  }

  /// Markahan ang lahat bilang nabasa na (explicit na ginagawa ng viewer).
  Future<void> markAllRead() async {
    if (_unread == 0 && lastSeenId >= _latestId) return;
    _unread = 0;
    lastSeenId = _latestId;
    notifyListeners();
    try {
      await _api.post('/notifications/seen', {'last_seen_id': _latestId});
    } catch (_) {
      await refresh(); // ibalik sa tunay na estado kung pumalya
    }
  }

  /// Burahin ang isang notification (para sa viewer na ito lang).
  Future<void> delete(ChangeItem c) async {
    items = items.where((e) => e.id != c.id).toList();
    if (c.id > lastSeenId && _unread > 0) _unread--;
    notifyListeners();
    try {
      await _api.post('/notifications/delete', {'id': c.id});
    } catch (_) {
      await refresh();
    }
  }

  /// Burahin lahat ng notification (para sa viewer na ito lang).
  Future<void> clearAll() async {
    items = [];
    _unread = 0;
    notifyListeners();
    try {
      await _api.post('/notifications/clear', {});
    } catch (_) {
      await refresh();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
