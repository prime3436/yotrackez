import 'package:shared_preferences/shared_preferences.dart';

/// Manages the Gemini API key storage and retrieval.
/// Uses SharedPreferences for persistent local storage.
class ApiKeyService {
  static const String _apiKeyPref = 'gemini_api_key';
  static ApiKeyService? _instance;
  String? _cachedKey;

  ApiKeyService._();

  static ApiKeyService get instance {
    _instance ??= ApiKeyService._();
    return _instance!;
  }

  /// Whether a valid Gemini API key is configured locally by the user.
  bool get hasApiKey => (_cachedKey != null && _cachedKey!.trim().isNotEmpty);

  /// Get the stored API key.
  String? get apiKey => _cachedKey?.trim();

  /// Load the API key from storage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_apiKeyPref);
  }

  /// Save a new API key.
  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = key.trim();
    await prefs.setString(_apiKeyPref, trimmed);
    _cachedKey = trimmed;
  }

  /// Remove the stored API key.
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
    _cachedKey = null;
  }
}
