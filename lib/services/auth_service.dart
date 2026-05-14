/*import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      "https://backendseguros-production.up.railway.app/api";

  String? accessToken;
  String? refreshToken;
  String? tenantSlug;

  // 🔐 LOGIN REAL
  Future<bool> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      accessToken = data["access"];
      refreshToken = data["refresh"];
      tenantSlug = data['usuario']['tenant_slug'];

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
      body: jsonEncode({"refresh": refreshToken}),
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
      body: jsonEncode({"refresh": refreshToken}),
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
      body: jsonEncode({"email": email}),
    );

    return response.statusCode == 200;
  }

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
    // Cambia 'tu-agencia-slug' por el slug real del tenant, idealmente
    // guardado tras el login. Por ahora es un placeholder.
    'X-Tenant-Slug': tenantSlug ?? '',
  };
}*/
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // ── Singleton ──────────────────────────────────────────
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  // ───────────────────────────────────────────────────────

  final String baseUrl =
      "https://backendseguros-production.up.railway.app/api";

  String? accessToken;
  String? refreshToken;
  String? tenantSlug;
  String? userRol;

  bool get isAuthenticated => accessToken != null;

  // 🔐 LOGIN REAL
  Future<bool> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      accessToken  = data["access"];
      refreshToken = data["refresh"];
      tenantSlug   = data["usuario"]?["tenant_slug"];
      userRol = data["usuario"]?["rol"];

      return true;
    } else {
      print("Login error: ${response.body}");
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
      body: jsonEncode({"refresh": refreshToken}),
    );

    accessToken  = null;
    refreshToken = null;
    tenantSlug   = null;
  }

  // 🔁 REFRESH TOKEN
  Future<bool> refresh() async {
    final url = Uri.parse("$baseUrl/token/refresh/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
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
    final url = Uri.parse("$baseUrl/password-reset-request/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return response.statusCode == 200;
  }

  // 🔑 HEADERS con token y tenant
  Map<String, String> get authHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${accessToken ?? ''}',
    };
    if (tenantSlug != null && tenantSlug!.isNotEmpty) {
      headers['X-Tenant-Slug'] = tenantSlug!;
    }
    return headers;
  }
}
