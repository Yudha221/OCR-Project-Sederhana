import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ocr_project/src/presentation/api.dart';

class LastRedeemRepository {
  final Dio _dio = Api().dio;

  /// ambil transaksi terakhir
  Future<Response> fetchLastRedeem() async {
    return await _dio.get('/redeem');
  }

  /// ✅ upload foto last doc
  Future uploadLastDoc(String id, File file) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post('/redeem/$id/last-doc', data: formData);

      print("UPLOAD SUCCESS:");
      print(response.data);
    } catch (e) {
      print("UPLOAD ERROR:");
      print(e);
      rethrow;
    }
  }
}
