class RenovacionModel {
  final int id;
  final int polizaOriginal;
  final String polizaOriginalNumero;
  final int? polizaNueva;
  final String? polizaNuevaNumero;
  final String estado;
  final String estadoDisplay;
  final String motivoSolicitud;
  final String? observacionesAnalista;
  final int nuevoPlazoAnios;
  final double? nuevaPrimaFacturada;
  final String fechaSolicitud;
  final String? fechaResolucion;

  RenovacionModel({
    required this.id,
    required this.polizaOriginal,
    required this.polizaOriginalNumero,
    this.polizaNueva,
    this.polizaNuevaNumero,
    required this.estado,
    required this.estadoDisplay,
    required this.motivoSolicitud,
    this.observacionesAnalista,
    required this.nuevoPlazoAnios,
    this.nuevaPrimaFacturada,
    required this.fechaSolicitud,
    this.fechaResolucion,
  });

  factory RenovacionModel.fromJson(Map<String, dynamic> json) {
    return RenovacionModel(
      id: json['id'],
      polizaOriginal: json['poliza_original'],
      polizaOriginalNumero: json['poliza_original_numero'] ?? '',
      polizaNueva: json['poliza_nueva'],
      polizaNuevaNumero: json['poliza_nueva_numero'],
      estado: json['estado'],
      estadoDisplay: json['estado_display'] ?? json['estado'],
      motivoSolicitud: json['motivo_solicitud'],
      observacionesAnalista: json['observaciones_analista'],
      nuevoPlazoAnios: json['nuevo_plazo_anios'] ?? 1,
      nuevaPrimaFacturada: json['nueva_prima_facturada'] != null
          ? double.parse(json['nueva_prima_facturada'].toString())
          : null,
      fechaSolicitud: json['fecha_solicitud'] ?? '',
      fechaResolucion: json['fecha_resolucion'],
    );
  }
}