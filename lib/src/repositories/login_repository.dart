import 'package:http/http.dart' as http;
import 'package:ocr_project/src/presentation/api.dart';

class LoginRepository {
  Future<http.Response> login(String username, String password) {
    return http.post(
      Uri.parse(ApiConstants.loginUrl),
      headers: {'Accept': 'application/json'},
      body: {'username': username, 'password': password},
    );
  }
}
