import 'package:dio/dio.dart';
import 'package:ocr_project/src/models/card_category.dart';
import 'package:ocr_project/src/models/card_type.dart';
import 'package:ocr_project/src/models/station.dart';
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
  // REDEEM VOUCHER
  // =====================
  Future<Map<String, dynamic>> redeemVoucher({
    required String serial,
    required String name,
    required String nik,
  }) async {
    try {
      final response = await dio.post(
        '/redeem',
        data: {
          'serialNumber': serial,
          'redeemType': 'SINGLE',
          'product': 'VOUCHER',
          'passengerName': name,
          'passengerNik': nik,
          'notes': '',
        },
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Redeem gagal',
      };
    }
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

  // =====================
  // GET VOUCHER CATEGORIES
  // =====================
  Future<List<CardCategory>> getVoucherCategories() async {
    final response = await dio.get(
      '/card/category',
      queryParameters: {'programType': 'VOUCHER'},
    );

    final List data = response.data['data'];
    return data.map((e) => CardCategory.fromJson(e)).toList();
  }

  // =====================
  // GET VOUCHER CARD TYPES
  // =====================
  Future<List<CardType>> getVoucherCardTypes() async {
    final response = await dio.get(
      '/card/types',
      queryParameters: {'programType': 'VOUCHER'},
    );

    final List data = response.data['data'];
    return data.map((e) => CardType.fromJson(e)).toList();
  }

  // =====================
  // GET STATIONS
  // =====================
  Future<List<Station>> getStations() async {
    final response = await dio.get('/station');

    final List items = response.data['data']['items'];

    return items.map((e) => Station.fromJson(e)).toList();
  }
}
