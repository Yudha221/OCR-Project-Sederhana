import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ocr_project/src/models/my_response.dart';
import 'package:ocr_project/src/models/user.dart';
import 'package:ocr_project/src/repositories/login_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

      final body = response.data as Map<String, dynamic>;

      // ================= SUCCESS =================
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'];

        final token = data['token'];
        final userJson = data['user'];

        await storage.write(key: 'token', value: token.toString());
        await storage.write(key: 'userProfile', value: jsonEncode(userJson));

        final packageInfo = await PackageInfo.fromPlatform();
        await storage.write(key: 'appVersion', value: packageInfo.version);

        return MyResponse<User>(
          code: 0,
          message: body['message'] ?? 'Login berhasil',
          data: User.fromJson(userJson),
        );
      }

      // ================= ERROR BACKEND =================
      return MyResponse<User>(
        code: 1,
        message: body['error']?['message'] ?? 'Terjadi kesalahan',
      );
    }
    // ================= ERROR DIO =================
    on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;

        if (data is Map<String, dynamic>) {
          return MyResponse<User>(
            code: 1,
            message: data['error']?['message'] ?? 'Terjadi kesalahan',
          );
        }
      }

      return MyResponse<User>(code: 1, message: 'Koneksi internet terputus');
    }
    // ================= ERROR LAIN =================
    catch (_) {
      return MyResponse<User>(
        code: 1,
        message: 'Terjadi kesalahan pada aplikasi',
      );
    }
  }
}
