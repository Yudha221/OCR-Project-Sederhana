import 'package:dio/dio.dart';
import '../presentation/api.dart';
import '../models/redeem.dart';

class RedeemRepository {
  final Dio dio = Api().dio;

  // =====================
  // GET LIST (HOME TABLE)
  // =====================
  Future<List<Redeem>> getRedeemList() async {
    final response = await dio.get('/redeem');
    final List items = response.data['data']['items'];
    return items.map((e) => Redeem.fromJson(e)).toList();
  }

  // =====================
  // VERIFY SERIAL
  // =====================
  Future<Map<String, dynamic>> verifySerial(String serialNumber) async {
    try {
      final serial = serialNumber.trim();

      if (serial.isEmpty) {
        return {'success': false, 'message': 'Serial number kosong'};
      }

      final Response response = await dio.get('/redeem/check/$serial');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message':
            response.data?['message'] ??
            'Server error (${response.statusCode})',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Server tidak merespon',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =====================
  // DELETE REDEEM ✅ (UUID STRING)
  // =====================
  Future<Map<String, dynamic>> deleteRedeem(String id) async {
    try {
      final Response response = await dio.delete('/redeem/$id');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message':
            response.data?['message'] ??
            'Gagal menghapus (${response.statusCode})',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Server error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
