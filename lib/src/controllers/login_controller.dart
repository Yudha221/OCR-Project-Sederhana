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
      debugPrint('================ LOGIN REQUEST ================');
      debugPrint('USERNAME : ${usernameController.text}');
      debugPrint('PASSWORD : ${passwordController.text}');

      final response = await _repository.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      debugPrint('================ LOGIN RESPONSE ================');
      debugPrint('STATUS CODE : ${response.statusCode}');
      debugPrint('BODY        : ${response.data}');
      debugPrint('================================================');

      // ================= SUCCESS =================
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;

        if (!body.containsKey('data')) {
          return MyResponse(
            code: 1,
            message: 'Format response tidak sesuai (data)',
          );
        }

        final data = body['data'] as Map<String, dynamic>;

        final token = data['token'];
        final userJson = data['user'];

        if (token == null || userJson == null) {
          return MyResponse(code: 1, message: 'Token / User tidak ditemukan');
        }

        // 🔐 SIMPAN KE STORAGE
        await storage.write(key: 'token', value: token.toString());
        await storage.write(key: 'userProfile', value: jsonEncode(userJson));

        final user = User.fromJson(userJson);

        debugPrint('✅ LOGIN SUCCESS');

        return MyResponse<User>(
          code: 0,
          message: body['message'] ?? 'Login berhasil',
          data: user,
        );
      }

      // ================= FAILED =================
      return MyResponse<User>(
        code: 1,
        message: 'Login gagal (status ${response.statusCode})',
      );
    } catch (e, s) {
      debugPrint('🔥 LOGIN EXCEPTION');
      debugPrint('ERROR : $e');
      debugPrint('STACK : $s');

      return MyResponse<User>(code: 1, message: 'Terjadi error saat login');
    }
  }
}
