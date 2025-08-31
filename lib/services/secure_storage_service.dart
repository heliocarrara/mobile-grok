import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ignore: depend_on_referenced_packages
class SecureStorageService {
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();
  static final SecureStorageService _instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _grokKey = 'grok_api_key_secure';

  Future<void> saveGrokApiKey(String key) async {
    return _storage.write(key: _grokKey, value: key);
  }

  Future<String?> readGrokApiKey() async {
    return _storage.read(key: _grokKey);
  }

  Future<void> deleteGrokApiKey() async {
    return _storage.delete(key: _grokKey);
  }
}
