import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 40),
      validateStatus: (_) => true,
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
      final t = await _storage.read(key: 'access');
      if (t != null) o.headers['Authorization'] = 'Bearer $t';
      h.next(o);
    }));
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  Future<String?> get refreshToken => _storage.read(key: 'refresh');
  Future<bool> get hasSession async => (await _storage.read(key: 'access')) != null;
  Future<void> clear() => _storage.deleteAll();

  Future<bool> _tryRefresh() async {
    final r = await refreshToken;
    if (r == null) return false;
    try {
      final res = await _dio.post('/auth/refresh', data: {'refresh_token': r});
      if (res.data is Map && res.data['success'] == true) {
        final d = res.data['data'];
        await saveTokens(d['access_token'], d['refresh_token']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<dynamic> request(String method, String path, {Map<String, dynamic>? query, Map<String, dynamic>? body}) async {
    Response res;
    try {
      res = await _send(method, path, query, body);
      if (res.statusCode == 401 && !path.startsWith('/auth/') && await _tryRefresh()) {
        res = await _send(method, path, query, body);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        throw ApiException('Cannot reach the server. Check your internet connection or XAMPP.');
      }
      throw ApiException('Connection error.');
    }
    final data = res.data;
    if (data is! Map) throw ApiException('Unexpected response from the server.', res.statusCode);
    if (data['success'] != true) throw ApiException(data['message'] ?? 'An error occurred.', res.statusCode);
    return data['data'];
  }

  Future<Response> _send(String m, String p, Map<String, dynamic>? q, Map<String, dynamic>? b) =>
      _dio.request(p, queryParameters: q, data: b, options: Options(method: m));

  Future<dynamic> get(String p, {Map<String, dynamic>? query}) => request('GET', p, query: query);
  Future<dynamic> post(String p, Map<String, dynamic> b) => request('POST', p, body: b);
}
