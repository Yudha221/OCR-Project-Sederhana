import 'package:dio/dio.dart';
import '../presentation/api.dart';

class HistoryDeleteRepository {
  final Dio _dio = Api().dio;

  Future<Response> fetchHistoryDelete({int page = 1, int limit = 1000}) async {
    return await _dio.get(
      '/redeem',
      queryParameters: {'isDeleted': true, 'page': page, 'limit': limit},
    );
  }
}
