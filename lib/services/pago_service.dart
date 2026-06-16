import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/pago_model.dart';

class PagoService {
  final AuthService auth;
  PagoService(this.auth);

  String get base => auth.baseUrl;

  /// GET /api/pagos/  — historial de pagos.
  /// Cliente: ve solo los suyos (el backend filtra por tenant; el filtro
  /// por cliente propio se hace aquí mismo comparando poliza.cliente_email
  /// no está expuesto directamente, así que usamos el query param 'cliente'
  /// cuando el rol no es cliente, y dejamos que el cliente vea su propio
  /// listado vía la relación de pólizas que el backend ya resuelve).
  Future<List<PagoModel>> listarPagos({String? numeroPoliza, int? clienteId}) async {
    final params = <String, String>{};
    if (numeroPoliza != null) params['poliza'] = numeroPoliza;
    if (clienteId != null) params['cliente'] = clienteId.toString();

    final uri = Uri.parse('$base/pagos/').replace(
      queryParameters: params.isEmpty ? null : params,
    );

    final res = await http.get(uri, headers: auth.authHeaders);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).map((j) => PagoModel.fromJson(j)).toList();
    }
    throw Exception('Error al listar pagos (${res.statusCode})');
  }
  /*
  Future<String> crearCheckoutSession(int polizaId) async {
    final res = await http.post(
      Uri.parse('$base/pagos/crear-checkout/'),
      headers: auth.authHeaders,
      body: jsonEncode({'poliza_id': polizaId}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['url'] as String;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al crear sesión de pago');
  }*/

  /// PASO 1 (Stripe real): crea la sesión de checkout.
  /// Devuelve un mapa con 'url' (para abrir en el navegador) y
  /// 'session_id' (para confirmar el pago después).
  Future<Map<String, String>> crearCheckoutSession(int polizaId) async {
    final res = await http.post(
      Uri.parse('$base/pagos/crear-checkout/'),
      headers: auth.authHeaders,
      body: jsonEncode({'poliza_id': polizaId}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return {
        'url': data['url'] as String,
        'session_id': data['session_id'] as String,
      };
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al crear sesión de pago');
  }

  /// PASO 2 (Stripe real): confirma con el backend que el pago se realizó.
  /// El backend valida contra la API real de Stripe (no confiar solo en
  /// que el navegador haya cerrado bien).
  Future<PagoModel> confirmarPagoStripe({
    required String stripeSessionId,
    required int polizaId,
  }) async {
    final res = await http.post(
      Uri.parse('$base/pagos/stripe/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'stripe_session_id': stripeSessionId,
        'poliza_id': polizaId,
      }),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return PagoModel.fromJson(data['pago']);
    }
    final err = jsonDecode(res.body);
    // Mapeamos los mensajes de la guía de integración para dar feedback claro
    final mensaje = err['error'] ?? 'No se pudo confirmar el pago.';
    throw Exception(mensaje);
  }

  /// Modo demo: simula un pago exitoso sin pasar por Stripe real.
  Future<PagoModel> simularPago(int polizaId) async {
    final res = await http.post(
      Uri.parse('$base/pagos/simular-stripe/'),
      headers: auth.authHeaders,
      body: jsonEncode({'poliza_id': polizaId}),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return PagoModel.fromJson(data['pago']);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al simular el pago');
  }

  /// Registro manual (agente en oficina: efectivo / transferencia).
  Future<PagoModel> registrarPagoManual({
    required String numeroPoliza,
    required double monto,
    required String metodoPago, // 'EFECTIVO' | 'TRANSFERENCIA'
    required String nroComprobante,
    String observaciones = '',
  }) async {
    final res = await http.post(
      Uri.parse('$base/pagos/manual/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'numero_poliza': numeroPoliza,
        'monto': monto,
        'metodo_pago': metodoPago,
        'nro_comprobante': nroComprobante,
        'observaciones': observaciones,
      }),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return PagoModel.fromJson(data['pago']);
    }
    final err = jsonDecode(res.body);
    throw Exception(err.toString());
  }

  /// Descarga el comprobante PDF del pago (bytes, para abrir con open_filex).
  Future<Uint8List> descargarComprobantePdf(int pagoId) async {
    final headers = Map<String, String>.from(auth.authHeaders)
      ..remove('Content-Type');
    final res = await http.get(
      Uri.parse('$base/pagos/$pagoId/comprobante/'),
      headers: headers,
    );
    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception('Error al descargar el comprobante (${res.statusCode})');
  }
}