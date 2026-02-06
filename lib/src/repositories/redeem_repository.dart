import 'package:dio/dio.dart';
import 'package:ocr_project/src/models/card_category.dart';
import 'package:ocr_project/src/models/card_type.dart';
import '../presentation/api.dart';
import '../models/redeem.dart';

class RedeemRepository {
  final Dio dio = Api().dio;

  // =====================
  // GET LIST (HOME TABLE)
  // =====================
  Future<List<Redeem>> getRedeemList({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      '/redeem',
      queryParameters: {'page': page, 'limit': limit},
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
  // DELETE REDEEM ✅ (UUID STRING)
  // =====================
  Future<Map<String, dynamic>> deleteRedeem({
    required String id,
    required String note,
    required String deletedBy,
  }) async {
    try {
      final Response response = await dio.delete(
        '/redeem/$id',
        queryParameters: {'notes': note, 'deletedBy': deletedBy},
        data: {
          'notes': note,
          'deletedBy': deletedBy,
        }, // DOUBLE SEND (Body + Query)
      );

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

  // =====================
  // REDEEM (POST)
  // =====================
  Future<Map<String, dynamic>> redeem({
    required String serialNumber,
    required int redeemType,
  }) async {
    try {
      final Response response = await dio.post(
        '/redeem',
        data: {
          'serialNumber': serialNumber,
          'redeemType': redeemType == 1 ? 'SINGLE' : 'ROUNDTRIP',
          'product': 'FWC',
          'notes': '',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Redeem gagal',
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

  // =====================
  // GET CARD CATEGORY (FWC)
  // =====================
  Future<List<CardCategory>> getCardCategories() async {
    final response = await dio.get(
      '/card/category',
      queryParameters: {'programType': 'FWC'},
    );

    final List data = response.data['data'];
    return data.map((e) => CardCategory.fromJson(e)).toList();
  }

  // =====================
  // GET CARD TYPES (FWC)
  // =====================
  Future<List<CardType>> getCardTypes() async {
    final response = await dio.get(
      '/card/types',
      queryParameters: {'programType': 'FWC'},
    );

    final List data = response.data['data'];
    return data.map((e) => CardType.fromJson(e)).toList();
  }
}
