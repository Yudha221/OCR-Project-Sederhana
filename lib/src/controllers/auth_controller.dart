import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthController {
  final _storage = const FlutterSecureStorage();

  Future<String> getUserName() async {
    final userJson = await _storage.read(key: 'userProfile');
    if (userJson == null) return '';

    final user = jsonDecode(userJson);
    return user['fullName'] ?? user['username'] ?? '';
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'userProfile');
  }

  Future<bool> isLoggedIn() async {
    return await _storage.read(key: 'token') != null;
  }
}
