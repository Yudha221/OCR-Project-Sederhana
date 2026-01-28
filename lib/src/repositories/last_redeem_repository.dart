import 'package:dio/dio.dart';
import 'package:ocr_project/src/presentation/api.dart';

class LastRedeemRepository {
  final Dio _dio = Api().dio; // ✅ FIX

  Future<Response> fetchLastRedeem() async {
    return await _dio.get('/redeem');
  }
}
