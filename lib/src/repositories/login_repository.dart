import 'package:dio/dio.dart';
import '../presentation/api.dart';

class LoginRepository {
  final Dio dio = Api().dio;

  Future<Response> login(String username, String password) {
    return dio.post(
      '/auth/login-simple',
      data: {'username': username, 'password': password},
    );
  }
}
