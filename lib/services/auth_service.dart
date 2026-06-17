/*import 'dart:convert';
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
}*/
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String baseUrl =
      "https://backendseguros-production.up.railway.app/api";

  String? accessToken;
  String? refreshToken;
  String? tenantSlug;
  String? tenantNombre;
  String? userRol;
  int? userId;

  bool? _esSuperuserCache;

  bool get isAuthenticated => accessToken != null;

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      accessToken = data["access"];
      refreshToken = data["refresh"];
      tenantSlug = data["usuario"]?["tenant_slug"];
      tenantNombre = data["usuario"]?["tenant_nombre"];
      userRol = data["usuario"]?["rol"];
      userId = data["usuario"]?["id"];
      _esSuperuserCache = null;
      await _detectarSuperuser();
      return true;
    }
    return false;
  }

  Future<void> _detectarSuperuser() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/tenants/admin/lista/"),
        headers: authHeaders,
      );
      _esSuperuserCache = res.statusCode == 200;
    } catch (_) {
      _esSuperuserCache = false;
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse("$baseUrl/logout/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${accessToken ?? ''}",
        },
        body: jsonEncode({"refresh": refreshToken}),
      );
    } catch (_) {}
    accessToken = null;
    refreshToken = null;
    tenantSlug = null;
    tenantNombre = null;
    userRol = null;
    userId = null;
    _esSuperuserCache = null;
  }

  Future<bool> refresh() async {
    final response = await http.post(
      Uri.parse("$baseUrl/token/refresh/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
    );
    if (response.statusCode == 200) {
      accessToken = jsonDecode(response.body)["access"];
      return true;
    }
    return false;
  }

  Future<bool> recoverPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/password-reset-request/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return response.statusCode == 200;
  }

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

  // ── 4 ROLES ──────────────────────────────────────────────────────────────
  // Sistema    → is_superuser Django (detectado por endpoint exclusivo)
  // Admin      → grupo "AdminAgencia" O grupo "Administrador"
  //              (ambos administran dentro de su seguro/tenant)
  // Agente     → grupo "Agente"
  // Cliente    → grupo "Cliente"

  bool get esSistema => tenantSlug == null || tenantSlug!.isEmpty;
  /*bool get esSistema => _esSuperuserCache == true;
  bool get esSistema => _esSuperuserCache == true && userRol != 'Agente' && userRol != 'AdminAgencia' 
  && userRol != 'Administrador' && userRol != 'Cliente';*/

  /// Admin del seguro: incluye dueño de la agencia (AdminAgencia)
  /// y administrador operativo (Administrador)
  bool get esAdmin =>
      !esSistema && 
      (userRol == 'AdminAgencia' || userRol == 'Administrador');

  bool get esAgente => !esSistema && userRol == 'Agente';

  bool get esCliente => !esSistema && userRol == 'Cliente';
  /*bool get esAdmin => userRol == 'AdminAgencia' || userRol == 'Administrador';
  bool get esAgente => userRol == 'Agente';
  bool get esCliente => userRol == 'Cliente';*/

  /// Cualquier rol con acceso staff dentro de su ámbito
  bool get esStaff => esSistema || esAdmin || esAgente;

  Future<void> esperarDeteccionRol() async {
    if (_esSuperuserCache == null) {
      await _detectarSuperuser();
    }
  }
}