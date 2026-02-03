import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  static final Api _instance = Api._internal();
  late Dio dio;

  factory Api() {
    return _instance;
  }

  Api._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://rewards-dev.kcic.co.id/api/',
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),

        // 🔥 PENTING: supaya 500 TIDAK throw exception
        validateStatus: (status) {
          return status != null && status < 600;
        },
      ),
    );

    // 🔐 TOKEN INTERCEPTOR
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            const storage = FlutterSecureStorage();
            await storage.deleteAll();
          }
          handler.next(error);
        },
      ),
    );

    // 🔍 LOG (DEBUG)
    dio.interceptors.add(
      LogInterceptor(request: true, requestBody: true, responseBody: true),
    );
  }
}
