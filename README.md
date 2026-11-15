# AgriBot Flutter App

AgriBot is the customer-facing agricultural price, stock, and store assistant for Mamburao.

## Requirements

- Flutter SDK compatible with Dart `>=3.3.0 <4.0.0`
- PHP/MySQL backend (`agri_api`) running separately
- Android emulator, physical Android phone, or Chrome

## Setup

1. Extract this project.
2. Open a terminal in the `agri_app` folder.
3. Install packages:

   ```bash
   flutter pub get
   ```

4. Configure the backend URL when running the app:

   **Chrome / same PC as XAMPP**
   ```bash
   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost/agri_api
   ```

   **Android emulator**
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2/agri_api
   ```

   **Physical Android phone**
   ```bash
   flutter run --dart-define=API_BASE_URL=http://YOUR-PC-LAN-IP/agri_api
   ```

   Replace `YOUR-PC-LAN-IP` with the computer's local network IP address. The phone and computer must be on the same Wi-Fi network. For production, use HTTPS.

5. Run checks:

   ```bash
   flutter analyze
   flutter test
   ```

## AgriBot API connection

The Flutter chat screen uses the existing endpoint:

- Method: `POST`
- Path: `/ai/chat`
- Full URL: `<API_BASE_URL>/ai/chat`
- Authentication: the existing `ApiClient` adds the saved Bearer access token when available.

Request body currently sent by the app:

```json
{
  "message": "Where can I find fertilizer?",
  "history": [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hello! How can I help?"}
  ],
  "lat": 13.223,
  "lng": 120.596
}
```

The existing API client expects the backend's standard success wrapper:

```json
{
  "success": true,
  "data": {
    "reply": "You can check the available fertilizer stores...",
    "products": []
  }
}
```

`products` is optional. When provided, each item should contain the fields used by the existing product card, such as `name`, `brand`, `price`, `unit`, `stock_status`, `store_name`, `distance_km`, and optionally `last_updated` / `is_stale`.

If your PHP endpoint uses different field names or a different response wrapper, update the Flutter mapping or backend response to match. The PHP backend was not included in the uploaded ZIP, so its actual implementation and database schema could not be verified.

## API URL configuration

`lib/core/config.dart` reads `API_BASE_URL` with `String.fromEnvironment`. Do not hardcode a production server URL into source control.

## API secrets

Do not place the Anthropic API key in Flutter code, Flutter assets, or a mobile `.env` file. Mobile app files can be inspected after installation. Keep the Anthropic key in the PHP backend's server-side environment/configuration, and let `/ai/chat` call Anthropic from the server.

The uploaded `.env` file did not contain an Anthropic API key. Add it only to the backend environment on your server; never add it to this Flutter ZIP.

## Main app structure

- `lib/core/` – app configuration, theme, helpers, and validators
- `lib/data/` – local store/product reference data
- `lib/screens/` – customer, owner, admin, login, map, and AgriBot screens
- `lib/services/` – API, authentication, admin, and owner services
- `lib/widgets/` – reusable UI components
- `assets/images/` – AgriBot and store images

## Notes

- Existing login, registration, store search, map, owner, and admin screens are retained.
- The AgriBot chat UI follows the supplied screenshot's green and light-green design.
- The chatbot requires the PHP backend to be running and the `/ai/chat` endpoint to return the response format described above.
