import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "https://backend-seguros-de-vida-production.up.railway.app/api";

  String? accessToken;
  String? refreshToken;

  // 🔐 LOGIN REAL
  Future<bool> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      accessToken = data["access"];
      refreshToken = data["refresh"];

      return true;
    } else {
      print(response.body);
      return false;
    }
  }

  // 🚪 LOGOUT REAL
  Future<void> logout() async {
    final url = Uri.parse("$baseUrl/logout/");

    await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "refresh": refreshToken,
      }),
    );

    accessToken = null;
    refreshToken = null;
  }

  // 🔁 REFRESH TOKEN
  Future<bool> refresh() async {
    final url = Uri.parse("$baseUrl/token/refresh/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "refresh": refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      accessToken = data["access"];
      return true;
    }
    return false;
  }

  // 📧 RECUPERAR CONTRASEÑA
  Future<bool> recoverPassword(String email) async {
    final url = Uri.parse("$baseUrl/password-reset/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
      }),
    );

    return response.statusCode == 200;
  }
}