import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ocr_project/src/presentation/api.dart';

class LastRedeemRepository {
  final Dio _dio = Api().dio;

  Future<Response> fetchLastRedeem() async {
    return await _dio.get('/redeem');
  }

  /// ✅ upload base64 & ambil URL foto
  Future<String> uploadLastDoc(String id, Map<String, dynamic> body) async {
    final response = await _dio.post(
      '/redeem/$id/last-doc',
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = response.data['message'] ?? 'Upload gagal (${response.statusCode})';
      throw Exception(message);
    }

    final data = response.data['data'];

    if (data == null || data['path'] == null) {
      throw Exception('Path foto tidak ditemukan dari server');
    }

    final path = data['path'];

    return 'https://rewards-dev.kcic.co.id/api/$path';
  }
}
