import 'api_client.dart';

/// All admin API calls. Every endpoint requires an admin account.
class AdminService {
  final _api = ApiClient.instance;

  List<Map<String, dynamic>> _list(dynamic d) =>
      (d as List).map((e) => Map<String, dynamic>.from(e)).toList();

  Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);

  // ---- dashboard / reports / logs
  Future<Map<String, dynamic>> dashboard() async => _map(await _api.get('/admin/dashboard'));
  Future<Map<String, dynamic>> analytics() async => _map(await _api.get('/admin/analytics'));
  Future<List<Map<String, dynamic>>> logs({int limit = 100}) async =>
      _list(await _api.get('/admin/logs', query: {'limit': limit}));

  // ---- store claims (verification)
  /// status: pending | approved | rejected | all
  Future<List<Map<String, dynamic>>> claims(String status) async =>
      _list(await _api.get('/admin/claims', query: {'status': status}));

  /// part: permit | storefront   status: pending | verified | rejected
  Future<void> verifyClaim(int claimId, String part, String status) =>
      _api.post('/admin/claims/verify', {'claim_id': claimId, 'part': part, 'status': status});

  Future<void> reviewClaim(int claimId, {required bool approve, String? reason}) =>
      _api.post('/admin/claims/review', {
        'claim_id': claimId,
        'action': approve ? 'approve' : 'reject',
        if (!approve) 'reason': reason ?? '',
      });

  // ---- stores
  Future<List<Map<String, dynamic>>> stores() async => _list(await _api.get('/admin/stores'));

  Future<Map<String, dynamic>> storeDetail(int id) async =>
      _map(await _api.get('/admin/stores/detail', query: {'id': id}));

  Future<void> setStoreActive(int id, bool active) =>
      _api.post('/admin/stores/active', {'store_id': id, 'active': active});

  /// data: name, address, barangay, description, latitude, longitude, image (base64, optional)
  Future<void> createStore(Map<String, dynamic> data) => _api.post('/admin/stores', data);

  // ---- users
  /// role: store_owner | customer
  Future<List<Map<String, dynamic>>> users(String role) async =>
      _list(await _api.get('/admin/users', query: {'role': role}));

  /// status: active | suspended
  Future<void> setUserStatus(int id, String status) =>
      _api.post('/admin/users/status', {'user_id': id, 'status': status});

  // ---- products (monitoring only)
  /// stock: '' | in | low | out | hidden
  Future<List<Map<String, dynamic>>> products({int? storeId, int? categoryId, String stock = ''}) async {
    final q = <String, dynamic>{};
    if (storeId != null) q['store_id'] = storeId;
    if (categoryId != null) q['category_id'] = categoryId;
    if (stock.isNotEmpty) q['stock'] = stock;
    return _list(await _api.get('/admin/products', query: q));
  }

  Future<void> moderateProduct(int id, {required bool hidden, String? reason}) =>
      _api.post('/admin/products/moderate', {
        'product_id': id,
        'hidden': hidden,
        if (hidden) 'reason': reason ?? '',
      });

  Future<List<Map<String, dynamic>>> categories() async => _list(await _api.get('/categories'));

  /// GET /health (no login needed): used by System Settings.
  Future<Map<String, dynamic>> health() async => _map(await _api.get('/health'));
}
