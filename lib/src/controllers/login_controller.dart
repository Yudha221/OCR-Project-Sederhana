import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ocr_project/src/models/my_response.dart';
import 'package:ocr_project/src/models/user.dart';
import 'package:ocr_project/src/repositories/login_repository.dart';

class LoginController {
  final LoginRepository _repository = LoginRepository();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Controller untuk UI
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<MyResponse<User>> login() async {
    try {
      debugPrint('================ LOGIN REQUEST ================');
      debugPrint('USERNAME : ${usernameController.text}');
      debugPrint('PASSWORD : ${passwordController.text}');

      final http.Response response = await _repository.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      // 🔥 PRINT URL + STATUS + BODY
      debugPrint('================ LOGIN RESPONSE ================');
      debugPrint('REQUEST URL : ${response.request?.url}');
      debugPrint('STATUS CODE : ${response.statusCode}');
      debugPrint('BODY RAW    : ${response.body}');
      debugPrint('HEADERS     : ${response.headers}');
      debugPrint('================================================');

      // ================= SUCCESS =================
      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (!body.containsKey('data')) {
          debugPrint('❌ ERROR: field "data" tidak ditemukan');
          return MyResponse(
            code: 1,
            message: 'Format response tidak sesuai (data)',
          );
        }

        final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;

        if (!data.containsKey('token')) {
          debugPrint('❌ ERROR: field "token" tidak ditemukan');
          return MyResponse(code: 1, message: 'Token tidak ditemukan');
        }

        if (!data.containsKey('user')) {
          debugPrint('❌ ERROR: field "user" tidak ditemukan');
          return MyResponse(code: 1, message: 'User tidak ditemukan');
        }

        final String token = data['token'].toString();
        final Map<String, dynamic> userJson =
            data['user'] as Map<String, dynamic>;

        debugPrint('TOKEN : $token');
        debugPrint('USER  : $userJson');

        // 🔐 SIMPAN KE SECURE STORAGE
        await storage.write(key: 'token', value: token);
        await storage.write(key: 'userId', value: userJson['id'].toString());
        await storage.write(key: 'userProfile', value: jsonEncode(userJson));

        final User user = User.fromJson(userJson);

        debugPrint('✅ LOGIN SUCCESS');

        return MyResponse<User>(
          code: 0,
          message: body['message'] ?? 'Login berhasil',
          data: user,
        );
      }

      // ================= FAILED =================
      debugPrint('❌ LOGIN FAILED (STATUS ${response.statusCode})');

      return MyResponse<User>(
        code: 1,
        message: 'Login gagal (status ${response.statusCode})',
      );
    } catch (e, s) {
      // ================= EXCEPTION =================
      debugPrint('🔥 LOGIN EXCEPTION');
      debugPrint('ERROR : $e');
      debugPrint('STACK : $s');

      return MyResponse<User>(code: 1, message: 'Terjadi error saat login');
    }
  }
}
