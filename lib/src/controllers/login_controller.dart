import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ocr_project/src/models/my_response.dart';
import 'package:ocr_project/src/models/user.dart';
import 'package:ocr_project/src/repositories/login_repository.dart';

class LoginController {
  final LoginRepository _repository = LoginRepository();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // ⚠️ (opsional, boleh nanti dipindah ke Page)
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<MyResponse<User>> login() async {
    try {
      final response = await _repository.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      // ================= SUCCESS =================
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'];

        final token = data['token'];
        final userJson = data['user'];

        await storage.write(key: 'token', value: token.toString());
        await storage.write(key: 'userProfile', value: jsonEncode(userJson));

        return MyResponse<User>(
          code: 0,
          message: body['message'] ?? 'Login berhasil',
          data: User.fromJson(userJson),
        );
      }

      // ================= USER / PASSWORD SALAH =================
      if (response.statusCode == 401 || response.statusCode == 403) {
        return MyResponse<User>(
          code: 1,
          message: 'Username atau password salah',
        );
      }

      // ================= SERVER ERROR =================
      return MyResponse<User>(
        code: 1,
        message: 'Server sedang bermasalah, silakan coba lagi',
      );
    } catch (_) {
      // ================= INTERNET ERROR =================
      return MyResponse<User>(
        code: 1,
        message: 'Koneksi internet terputus, periksa jaringan Anda',
      );
    }
  }
}
