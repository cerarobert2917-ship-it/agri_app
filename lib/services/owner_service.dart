import 'api_client.dart';

class OwnerService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>?> getStore() async {
    final d = await _api.get('/owner/store');
    return d == null ? null : Map<String, dynamic>.from(d);
  }

  /// Mga store na ginawa ng admin na wala pang owner.
  Future<List<Map<String, dynamic>>> availableStores() async {
    final d = await _api.get('/owner/stores/available');
    return (d as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Mag-claim ng store. Ang mga larawan ay base64 (JPEG).
  Future<void> claimStore({
    required int storeId,
    required String permitBase64,
    required String frontBase64,
  }) =>
      _api.post('/owner/store/claim', {
        'store_id': storeId,
        'permit_image': permitBase64,
        'storefront_image': frontBase64,
      });

  /// Description, contact number at oras lang ang puwedeng palitan.
  /// Naka-lock na ang pangalan, address, barangay at lokasyon.
  Future<void> saveStore(Map<String, dynamic> data) => _api.post('/owner/store', {
        'description': data['description'],
        'contact_number': data['contact_number'],
        'opening_hours': data['opening_hours'],
      });

  Future<List<Map<String, dynamic>>> products() async {
    final d = await _api.get('/owner/products');
    return (d as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final d = await _api.get('/categories');
    return (d as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveProduct(Map<String, dynamic> data) => _api.post('/owner/products', data);

  Future<void> quickUpdate(int id, {double? price, int? stock, bool? available}) {
    final body = <String, dynamic>{'id': id};
    if (price != null) body['price'] = price;
    if (stock != null) body['stock_quantity'] = stock;
    if (available != null) body['is_available'] = available ? 1 : 0;
    return _api.post('/owner/products/update', body);
  }

  Future<void> deleteProduct(int id) => _api.post('/owner/products/delete', {'id': id});
}
