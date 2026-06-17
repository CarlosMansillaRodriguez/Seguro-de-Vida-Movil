class SiniestroModel {
  final int id;
  final int polizaId;
  final String polizaNumero;
  final String tipoSiniestro;
  final String tipoDisplay;
  final String fechaEvento;
  final String descripcion;
  final String? documentoSoporteUrl;
  final String estado;
  final String estadoDisplay;
  final String? observacionesAgente;
  final String fechaReporte;

  SiniestroModel({
    required this.id,
    required this.polizaId,
    required this.polizaNumero,
    required this.tipoSiniestro,
    required this.tipoDisplay,
    required this.fechaEvento,
    required this.descripcion,
    this.documentoSoporteUrl,
    required this.estado,
    required this.estadoDisplay,
    this.observacionesAgente,
    required this.fechaReporte,
  });

  factory SiniestroModel.fromJson(Map<String, dynamic> json) {
    return SiniestroModel(
      id: json['id'],
      polizaId: json['poliza'],
      polizaNumero: json['poliza_numero'] ?? '',
      tipoSiniestro: json['tipo_siniestro'] ?? '',
      tipoDisplay: json['tipo_display'] ?? json['tipo_siniestro'] ?? '',
      fechaEvento: json['fecha_evento'] ?? '',
      descripcion: json['descripcion'] ?? '',
      documentoSoporteUrl: json['documento_soporte_url'],
      estado: json['estado'] ?? '',
      estadoDisplay: json['estado_display'] ?? json['estado'] ?? '',
      observacionesAgente: json['observaciones_agente'],
      fechaReporte: json['fecha_reporte'] ?? '',
    );
  }
}

class IndemnizacionModel {
  final int id;
  final int siniestroId;
  final String polizaNumero;
  final String siniestroTipo;
  final double? montoAprobado;
  final double capitalAsegurado;
  final String estado;
  final String estadoDisplay;
  final String? observaciones;
  final String? comprobanteUrl;
  final String fechaCreacion;
  final String? agenteNombre;

  IndemnizacionModel({
    required this.id,
    required this.siniestroId,
    required this.polizaNumero,
    required this.siniestroTipo,
    this.montoAprobado,
    required this.capitalAsegurado,
    required this.estado,
    required this.estadoDisplay,
    this.observaciones,
    this.comprobanteUrl,
    required this.fechaCreacion,
    this.agenteNombre,
  });

  factory IndemnizacionModel.fromJson(Map<String, dynamic> json) {
    return IndemnizacionModel(
      id: json['id'],
      siniestroId: json['siniestro'],
      polizaNumero: json['poliza_numero'] ?? '',
      siniestroTipo: json['siniestro_tipo'] ?? '',
      montoAprobado: json['monto_aprobado'] != null
          ? double.parse(json['monto_aprobado'].toString())
          : null,
      capitalAsegurado: json['capital_asegurado'] != null
          ? double.parse(json['capital_asegurado'].toString())
          : 0,
      estado: json['estado'] ?? '',
      estadoDisplay:
          json['estado_display'] ?? json['estado'] ?? '',
      observaciones: json['observaciones'],
      comprobanteUrl: json['comprobante_pago_url'],
      fechaCreacion: json['fecha_creacion'] ?? '',
      agenteNombre: json['agente_nombre'],
    );
  }
}