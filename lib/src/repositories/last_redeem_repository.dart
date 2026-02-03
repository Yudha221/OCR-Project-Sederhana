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

    final path = response.data['data']['path'];
    return 'https://fwc-kcic.me:3001/$path';
  }
}
