import 'package:dio/dio.dart';
import '../presentation/api.dart';
import '../models/redeem.dart';

class VoucherRepository {
  final Dio dio = Api().dio;

  // =====================
  // GET VOUCHER LIST ONLY
  // =====================
  Future<List<Redeem>> getRedeemList({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      '/redeem',
      queryParameters: {
        'page': page,
        'limit': limit,
        'programType': 'VOUCHER', // 🔥 PEMISAH UTAMA
      },
    );

    final List items = response.data['data']['items'];
    return items.map((e) => Redeem.fromJson(e)).toList();
  }

  // =====================
  // REDEEM VOUCHER
  // =====================
  Future<Map<String, dynamic>> redeemVoucher({
    required String serial,
    required String name,
    required String nik,
  }) async {
    final response = await dio.post(
      '/redeem',
      data: {
        'serialNumber': serial,
        'product': 'VOUCHER',
        'name': name,
        'identityNumber': nik,
        'notes': '',
      },
    );

    return {
      'success': response.statusCode == 200 || response.statusCode == 201,
      'message': response.data['message'],
    };
  }

  // =====================
  // SOFT DELETE
  // =====================
  Future<Map<String, dynamic>> deleteVoucher({
    required String id,
    required String note,
    required String deletedBy,
  }) async {
    final response = await dio.delete(
      '/redeem/$id',
      data: {'notes': note, 'deletedBy': deletedBy},
    );

    return {
      'success': response.statusCode == 200,
      'message': response.data['message'],
    };
  }
}
