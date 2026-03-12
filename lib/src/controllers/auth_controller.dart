import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ocr_project/src/presentation/api.dart';

class AuthController {
  final _storage = const FlutterSecureStorage();

  Future<String> getUserName() async {
    final userJson = await _storage.read(key: 'userProfile');
    if (userJson == null) return '';

    final user = jsonDecode(userJson);
    return user['fullName'] ?? user['username'] ?? '';
  }

  Future<String> getStationId() async {
    final userJson = await _storage.read(key: 'userProfile');
    if (userJson == null) return '';

    final user = jsonDecode(userJson);
    return user['station']?['id'] ?? '';
  }

  Future<void> logout() async {
    try {
      // 🔥 panggil API logout
      await Api().dio.post('/auth/logout');

      // 🔥 hapus data login dari storage
      await _storage.deleteAll();
    } catch (e) {
      print("Logout error: $e");

      // kalau API error tetap hapus local token
      await _storage.deleteAll();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return false;

    final savedVersion = await _storage.read(key: 'appVersion');

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // 🔥 Kalau versi beda → force logout
    if (savedVersion != currentVersion) {
      await logout();
      return false;
    }

    return true;
  }
}
