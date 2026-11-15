import 'package:flutter/foundation.dart';
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

  /// Bubuksan ang Google account picker. null = nag-cancel ang user.
  static Future<GoogleTokens?> signIn() async {
    final account = await _gsi.signIn();
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
