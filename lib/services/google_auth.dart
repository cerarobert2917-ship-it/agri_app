import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import '../core/config.dart';

/// Resulta ng Google sign-in: mga token na ipapadala sa backend para i-verify.
class GoogleTokens {
  final String? idToken;
  final String? accessToken;
  const GoogleTokens({this.idToken, this.accessToken});
}

class GoogleAuth {
  static final GoogleSignIn _gsi = GoogleSignIn(
    scopes: const ['email', 'profile'],
    // Web: kailangan ang clientId. Android/iOS: serverClientId ang gamit para
    // makakuha ng idToken na pwedeng i-verify ng backend.
    clientId: kIsWeb ? AppConfig.googleWebClientId : null,
    serverClientId: kIsWeb ? null : AppConfig.googleWebClientId,
  );

  /// Mga error code kapag isinara o kinansela ng user ang Google popup. Hindi ito totoong error.
  static const _cancelCodes = {'popup_closed', 'popup_closed_by_user', 'sign_in_canceled', 'canceled'};

  static bool _isCancel(Object e) {
    if (e is PlatformException && _cancelCodes.contains(e.code)) return true;
    final t = e.toString();
    return t.contains('popup_closed') || t.contains('sign_in_canceled');
  }

  /// Bubuksan ang Google account picker. null = nag-cancel o nag-close ang user (walang ipapakitang error).
  static Future<GoogleTokens?> signIn() async {
    GoogleSignInAccount? account;
    try {
      account = await _gsi.signIn();
    } catch (e) {
      if (_isCancel(e)) return null;
      rethrow;
    }
    if (account == null) return null;
    final auth = await account.authentication;
    if (auth.idToken == null && auth.accessToken == null) {
      throw Exception('Google did not return a token. Please try again.');
    }
    return GoogleTokens(idToken: auth.idToken, accessToken: auth.accessToken);
  }

  static Future<void> signOut() async {
    try {
      await _gsi.signOut();
    } catch (_) {}
  }
}
