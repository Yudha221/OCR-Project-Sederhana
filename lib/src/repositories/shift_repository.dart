import 'package:dio/dio.dart';

class ShiftRepository {
  final Dio _dio;

  ShiftRepository(this._dio);

  Future<Map<String, dynamic>> openShift(String shiftId) async {
    final response = await _dio.post('/shift/open', data: {"shiftId": shiftId});

    return response.data;
  }

  Future<Map<String, dynamic>> closeShift(String notes) async {
    final response = await _dio.post('/shift/close', data: {"notes": notes});

    return response.data;
  }

  Future<Map<String, dynamic>> getShiftStatus() async {
    final response = await _dio.get('/shift/status');
    return response.data;
  }

  Future<List<dynamic>> getAvailableShift() async {
    final response = await _dio.get('/shift/available');

    return response.data['data'];
  }

  Future<Map<String, dynamic>> exportShiftReport() async {
    final response = await _dio.get('/shift/export-data');
    return response.data;
  }
}
