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
  String? tenantNombre;
  String? userRol;
  int? userId;

  // Se determina llamando a un endpoint exclusivo de superuser.
  // null = aún no verificado, true/false = verificado.
  bool? _esSuperuserCache;

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

      accessToken = data["access"];
      refreshToken = data["refresh"];
      tenantSlug = data["usuario"]?["tenant_slug"];
      tenantNombre = data["usuario"]?["tenant_nombre"];
      userRol = data["usuario"]?["rol"];
      userId = data["usuario"]?["id"];

      // Reseteamos la caché de superuser en cada login nuevo
      _esSuperuserCache = null;
      await _detectarSuperuser();

      return true;
    } else {
      print("Login error: ${response.body}");
      return false;
    }
  }

  /// Detecta si el usuario es Superusuario (rol "Sistema") llamando a un
  /// endpoint que el backend ya protege con IsAdminUser (solo superusers).
  /// No requiere modificar el backend.
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
    tenantSlug = null;
    tenantNombre = null;
    userRol = null;
    userId = null;
    _esSuperuserCache = null;
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

  // ══════════════════════════════════════════════════════════════════
  // ROLES — 5 niveles del sistema
  // ══════════════════════════════════════════════════════════════════
  //
  // Mapeo (sin tocar backend):
  //   Sistema       -> is_superuser de Django (detectado por endpoint)
  //   Tenant        -> grupo "AdminAgencia" (dueño de la agencia)
  //   AdminSeguro   -> grupo "Administrador" (admin operativo del tenant)
  //   Agente        -> grupo "Agente"
  //   Cliente       -> grupo "Cliente"

  /// true si ya se confirmó que es superusuario (rol Sistema).
  /// Si aún no se ha verificado (justo tras un login en curso), devuelve false
  /// de forma segura hasta que la verificación async termine.
  bool get esSistema => _esSuperuserCache == true;

  bool get esTenant => !esSistema && userRol == 'AdminAgencia';

  bool get esAdmin => !esSistema && userRol == 'Administrador';

  bool get esAgente => !esSistema && userRol == 'Agente';

  bool get esCliente => !esSistema && userRol == 'Cliente';

  /// true para Sistema, Tenant o AdminSeguro (roles con privilegios
  /// administrativos dentro de su alcance).
  bool get esStaff => esSistema || esTenant || esAdmin;

  /// Espera a que la detección de superuser termine (útil tras login,
  /// antes de decidir a qué pantalla redirigir).
  Future<void> esperarDeteccionRol() async {
    if (_esSuperuserCache == null) {
      await _detectarSuperuser();
    }
  }
}