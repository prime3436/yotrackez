import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _apiKeyPref = 'gemini_api_key';
  static ApiKeyService? _instance;
  String? _cachedKey;

  ApiKeyService._();

  static ApiKeyService get instance {
    _instance ??= ApiKeyService._();
    return _instance!;
  }

  bool get hasApiKey => (_cachedKey != null && _cachedKey!.trim().isNotEmpty);

  String? get apiKey => _cachedKey?.trim();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_apiKeyPref);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = key.trim();
    await prefs.setString(_apiKeyPref, trimmed);
    _cachedKey = trimmed;
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
    _cachedKey = null;
  }
}
