import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _apiKeyStorageKey = 'claude_api_key';
  static const _legacyPrefsKey = 'claude_api_key';

  static const _storage = FlutterSecureStorage();

  static Future<String> getApiKey() async {
    final stored = await _storage.read(key: _apiKeyStorageKey);
    if (stored != null) return stored;

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyPrefsKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _storage.write(key: _apiKeyStorageKey, value: legacy);
      await prefs.remove(_legacyPrefsKey);
      return legacy;
    }
    return '';
  }

  static Future<void> setApiKey(String key) async {
    await _storage.write(key: _apiKeyStorageKey, value: key);
  }
}
