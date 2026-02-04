import 'package:dio/dio.dart';
import '../presentation/api.dart';

class VoucherDeleteRepository {
  final Dio _dio = Api().dio;

  Future<Response> fetchVoucherDelete({int page = 1, int limit = 1000}) async {
    return await _dio.get(
      '/redeem',
      queryParameters: {
        'isDeleted': true,
        'product': 'VOUCHER', // 🔥 PENTING: BUKAN programType
        'page': page,
        'limit': limit,
      },
    );
  }
}
