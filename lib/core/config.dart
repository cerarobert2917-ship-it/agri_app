class AppConfig {
  /// Set this when running/building the app:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2/agri_api
  ///
  /// Android emulator: http://10.0.2.2/agri_api
  /// Chrome on the same PC as XAMPP: http://localhost/agri_api
  /// Physical phone: http://YOUR-PC-LAN-IP/agri_api
  ///
  /// Use your server's HTTPS URL in production.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/agri_api',
  );

  // Public OAuth client ID (not an API secret).
  static const String googleWebClientId =
      '623705794362-ndbia6doioq09nr4m4ckfc2v4pgb74b6.apps.googleusercontent.com';

  // Mamburao town center, used as a fallback when location is unavailable.
  static const double defaultLat = 13.2230;
  static const double defaultLng = 120.5960;
}
