import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/poliza_model.dart';
import '../models/renovacion_model.dart';

class PolizaService {
  final AuthService auth;
  PolizaService(this.auth);

  String get base => auth.baseUrl;

  Future<List<PolizaModel>> listarPolizas() async {
    final res = await http.get(
      Uri.parse('$base/polizas/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).map((j) => PolizaModel.fromJson(j)).toList();
    }
    throw Exception('Error al listar pólizas');
  }

  Future<PolizaModel> emitirPoliza({
    required int cotizacionId,
    required List<BeneficiarioModel> beneficiarios,
  }) async {
    final body = {
      'cotizacion_id': cotizacionId,
      'beneficiarios': beneficiarios.map((b) => b.toJson()).toList(),
    };
    final res = await http.post(
      Uri.parse('$base/polizas/emitir/'),
      headers: auth.authHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return PolizaModel.fromJson(data['poliza']);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al emitir póliza');
  }

  Future<RenovacionModel> solicitarRenovacion({
    required int polizaId,
    required String motivo,
    int nuevoPlazoAnios = 1,
  }) async {
    final res = await http.post(
      Uri.parse('$base/polizas/$polizaId/solicitar_renovacion/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'motivo_solicitud': motivo,
        'nuevo_plazo_anios': nuevoPlazoAnios,
      }),
    );
    if (res.statusCode == 201) {
      // La respuesta no es un RenovacionModel completo, construimos básico
      final data = jsonDecode(res.body);
      return RenovacionModel(
        id: data['renovacion_id'],
        polizaOriginal: polizaId,
        polizaOriginalNumero: data['poliza'] ?? '',
        estado: 'PENDIENTE',
        estadoDisplay: data['estado'] ?? 'Pendiente',
        motivoSolicitud: motivo,
        nuevoPlazoAnios: nuevoPlazoAnios,
        fechaSolicitud: data['fecha_solicitud']?.toString() ?? '',
      );
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al solicitar renovación');
  }

  Future<List<RenovacionModel>> listarRenovaciones() async {
    final res = await http.get(
      Uri.parse('$base/renovaciones/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).map((j) => RenovacionModel.fromJson(j)).toList();
    }
    throw Exception('Error al listar renovaciones');
  }
}