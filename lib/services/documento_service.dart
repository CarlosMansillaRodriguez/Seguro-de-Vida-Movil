import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/documento_model.dart';

class DocumentoService {
  final AuthService auth;
  DocumentoService(this.auth);

  String get base => auth.baseUrl;

  Future<ExpedienteModel> crearExpediente(ExpedienteModel expediente) async {
    final res = await http.post(
      Uri.parse('$base/expedientes/'),
      headers: auth.authHeaders,
      body: jsonEncode(expediente.toJson()),
    );
    if (res.statusCode == 201) {
      return ExpedienteModel.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err.toString());
  }

  Future<ExpedienteModel> actualizarExpediente(int id, Map<String, dynamic> campos) async {
    final res = await http.patch(
      Uri.parse('$base/expedientes/$id/'),
      headers: auth.authHeaders,
      body: jsonEncode(campos),
    );
    if (res.statusCode == 200) {
      return ExpedienteModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Error al actualizar expediente');
  }

  Future<ExpedienteModel?> obtenerExpedientePorCotizacion(int cotizacionId) async {
    final res = await http.get(
      Uri.parse('$base/expedientes/?cotizacion=$cotizacionId'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      if ((list as List).isEmpty) return null;
      return ExpedienteModel.fromJson(list.first);
    }
    return null;
  }
}