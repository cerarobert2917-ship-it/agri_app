import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'google_auth.dart';

enum GoogleResult { cancelled, signedIn, needsRole }

class AppUser {
  final int id;
  final String fullName;
  final String role;
  final String? storeStatus;
  AppUser({required this.id, required this.fullName, required this.role, this.storeStatus});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: int.parse('${j['id']}'),
        fullName: j['full_name'],
        role: j['role'],
        storeStatus: j['store_status'],
      );
}

class AuthService extends ChangeNotifier {
  final _api = ApiClient.instance;
  AppUser? user;

  Future<bool> restoreSession() async {
    if (!await _api.hasSession) return false;
    try {
      final d = await _api.get('/auth/me');
      user = AppUser.fromJson(Map<String, dynamic>.from(d));
      notifyListeners();
      return true;
    } catch (_) {
      await _api.clear();
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final d = await _api.post('/auth/login', {'email': email, 'password': password});
    await _applySession(d);
  }

  GoogleTokens? _pendingGoogle; // token na hinihintay ang pagpili ng role

  /// Continue with Google.
  /// - May account na: papasok agad, at ang role ay galing sa database.
  /// - Bagong account at walang [role]: ibabalik ang needsRole (itanong sa user,
  ///   tapos tawagin ulit na may role).
  Future<GoogleResult> loginWithGoogle({String? role}) async {
    final t = (role != null && _pendingGoogle != null) ? _pendingGoogle : await GoogleAuth.signIn();
    if (t == null) return GoogleResult.cancelled;
    final d = await _api.post('/auth/google', {
      'id_token': t.idToken,
      'access_token': t.accessToken,
      'role': role,
    });
    if (d is Map && d['needs_role'] == true) {
      _pendingGoogle = t;
      return GoogleResult.needsRole;
    }
    _pendingGoogle = null;
    await _applySession(d);
    return GoogleResult.signedIn;
  }

  Future<void> register(Map<String, dynamic> data) async {
    final d = await _api.post('/auth/register', data);
    await _applySession(d);
  }

  Future<void> _applySession(dynamic d) async {
    await _api.saveTokens(d['access_token'], d['refresh_token']);
    user = AppUser.fromJson(Map<String, dynamic>.from(d['user']));
    notifyListeners();
  }

  /// Buong detalye ng profile (email, phone, google_linked, atbp.)
  Future<Map<String, dynamic>> fetchProfile() async =>
      Map<String, dynamic>.from(await _api.get('/auth/profile'));

  /// Palitan ang full_name at/o phone. Ibabalik ang bagong profile.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> changes) async {
    final d = Map<String, dynamic>.from(await _api.post('/auth/profile', changes));
    final u = user;
    if (u != null && d['full_name'] != null) {
      user = AppUser(id: u.id, fullName: '${d['full_name']}', role: u.role, storeStatus: u.storeStatus);
      notifyListeners();
    }
    return d;
  }

  /// Ilagay/palitan ang profile picture ([base64Image] = laman ng JPEG/PNG/WebP).
  Future<Map<String, dynamic>> uploadAvatar(String base64Image) async =>
      Map<String, dynamic>.from(await _api.post('/auth/avatar', {'image': base64Image}));

  /// Tanggalin ang profile picture.
  Future<Map<String, dynamic>> removeAvatar() async =>
      Map<String, dynamic>.from(await _api.post('/auth/avatar', {'remove': true}));

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.post('/auth/change-password', {'old_password': oldPassword, 'new_password': newPassword});
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {'refresh_token': await _api.refreshToken});
    } catch (_) {}
    await _api.clear();
    await GoogleAuth.signOut();
    user = null;
    notifyListeners();
  }
}
