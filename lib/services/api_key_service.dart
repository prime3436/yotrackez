import 'package:shared_preferences/shared_preferences.dart';

/// Manages the Gemini API key storage and retrieval.
/// Uses SharedPreferences for persistent local storage.
class ApiKeyService {
  static const String _apiKeyPref = 'gemini_api_key';
  static const String _defaultApiKey = 'AIzaSyAY7YigBJAl8CpdG0-MKSc44H-TQMmCgKw';
  static ApiKeyService? _instance;
  String? _cachedKey;

  ApiKeyService._();

  static ApiKeyService get instance {
    _instance ??= ApiKeyService._();
    return _instance!;
  }

  /// Whether an API key is configured (default or custom).
  bool get hasApiKey => (apiKey ?? '').isNotEmpty;

  /// Get the stored API key, falling back to the default.
  String? get apiKey => (_cachedKey != null && _cachedKey!.isNotEmpty) ? _cachedKey : _defaultApiKey;

  /// Load the API key from storage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_apiKeyPref);
  }

  /// Save a new API key.
  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key.trim());
    _cachedKey = key.trim();
  }

  /// Remove the stored API key.
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
    _cachedKey = null;
  }
}
