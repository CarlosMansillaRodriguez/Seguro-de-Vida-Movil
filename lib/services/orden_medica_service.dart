/*import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/orden_medica_model.dart';

class OrdenMedicaService {
  final AuthService auth;
  OrdenMedicaService(this.auth);

  String get base => auth.baseUrl;

  // Obtiene la orden médica asociada a una cotización.
  // El backend devuelve 404 si no existe (cotización sin orden médica).
  Future<OrdenMedicaModel?> obtenerOrdenPorCotizacion(
      int cotizacionId) async {
    // El endpoint lista las órdenes, filtramos por cotización
    final res = await http.get(
      Uri.parse('$base/ordenes-medicas/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      // Buscamos la orden cuya cotización coincide
      final match = (list as List).where((o) {
        return o['cotizacion'] == cotizacionId;
      }).toList();
      if (match.isEmpty) return null;
      // Pedimos el detalle completo (con resultados y dictamen)
      return await obtenerOrdenDetalle(match.first['id']);
    }
    return null;
  }

  // Detalle completo de una orden (incluye resultados y dictamen)
  Future<OrdenMedicaModel> obtenerOrdenDetalle(int ordenId) async {
    final res = await http.get(
      Uri.parse('$base/ordenes-medicas/$ordenId/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      return OrdenMedicaModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Error al obtener orden médica');
  }

  // Lista todas las órdenes del cliente autenticado
  Future<List<OrdenMedicaModel>> listarMisOrdenes() async {
    final res = await http.get(
      Uri.parse('$base/ordenes-medicas/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      // Para cada elemento de la lista pedimos el detalle completo
      // para tener los resultados y dictamen incluidos
      final ordenes = <OrdenMedicaModel>[];
      for (final item in list) {
        try {
          final detalle = await obtenerOrdenDetalle(item['id']);
          ordenes.add(detalle);
        } catch (_) {
          // Si falla el detalle individual, usamos el resumen
          ordenes.add(OrdenMedicaModel.fromJson(item));
        }
      }
      return ordenes;
    }
    throw Exception('Error al listar órdenes médicas');
  }

  // Subir resultado médico con archivo (multipart)
  Future<void> subirResultado({
    required int ordenId,
    required String tipoExamen,
    required String resultado,
    File? archivo,
  }) async {
    final uri =
        Uri.parse('$base/ordenes-medicas/$ordenId/resultados/');
    final request = http.MultipartRequest('POST', uri);

    // Headers de autenticación (sin Content-Type, lo pone multipart)
    auth.authHeaders.forEach((key, value) {
      if (key != 'Content-Type') request.headers[key] = value;
    });

    request.fields['tipo_examen'] = tipoExamen;
    request.fields['resultado'] = resultado;

    if (archivo != null) {
      request.files.add(
        await http.MultipartFile.fromPath('archivo', archivo.path),
      );
    }

    final streamed = await request.send();
    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Error al subir resultado: $body');
    }
  }
}*/
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/orden_medica_model.dart';

class OrdenMedicaService {
  final AuthService auth;
  OrdenMedicaService(this.auth);

  String get base => auth.baseUrl;

  // Obtiene la orden médica asociada a una cotización.
  Future<OrdenMedicaModel?> obtenerOrdenPorCotizacion(
      int cotizacionId) async {
    final res = await http.get(
      Uri.parse('$base/ordenes-medicas/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      // FIX: comparar como String para evitar fallos por tipos
      // inconsistentes (int vs String) que llegan desde JSON.
      final match = (list as List).where((o) {
        return o['cotizacion'].toString() == cotizacionId.toString();
      }).toList();
      if (match.isEmpty) return null;
      return await obtenerOrdenDetalle(match.first['id']);
    }
    return null;
  }

  Future<OrdenMedicaModel> obtenerOrdenDetalle(int ordenId) async {
    final res = await http.get(
      Uri.parse('$base/ordenes-medicas/$ordenId/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      return OrdenMedicaModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Error al obtener orden médica');
  }

  Future<List<OrdenMedicaModel>> listarMisOrdenes() async {
    final res = await http.get(
      Uri.parse('$base/ordenes-medicas/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      final ordenes = <OrdenMedicaModel>[];
      for (final item in list) {
        try {
          final detalle = await obtenerOrdenDetalle(item['id']);
          ordenes.add(detalle);
        } catch (_) {
          ordenes.add(OrdenMedicaModel.fromJson(item));
        }
      }
      return ordenes;
    }
    throw Exception('Error al listar órdenes médicas');
  }

  Future<void> subirResultado({
    required int ordenId,
    required String tipoExamen,
    required String resultado,
    File? archivo,
  }) async {
    final uri = Uri.parse('$base/ordenes-medicas/$ordenId/resultados/');
    final request = http.MultipartRequest('POST', uri);

    auth.authHeaders.forEach((key, value) {
      if (key != 'Content-Type') request.headers[key] = value;
    });

    request.fields['tipo_examen'] = tipoExamen;
    request.fields['resultado'] = resultado;

    if (archivo != null) {
      request.files.add(
        await http.MultipartFile.fromPath('archivo', archivo.path),
      );
    }

    final streamed = await request.send();
    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Error al subir resultado: $body');
    }
  }
  /*-------------------------------------------------------------*/
  Future<void> emitirDictamen({
    required int ordenId,
    required String conclusion, // 'APTO' | 'APTO_RESERVA' | 'NO_APTO'
    double impactoPrimaPct = 0,
    String observaciones = '',
  }) async {
    final res = await http.post(
      Uri.parse('$base/ordenes-medicas/$ordenId/dictamen/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'conclusion': conclusion,
        'impacto_prima_pct': impactoPrimaPct,
        'observaciones': observaciones,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? body.toString());
    }
  }
  /*-------------------------------------------------------------*/
}