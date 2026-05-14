class ExpedienteModel {
  final int? id;
  final int cotizacionId;
  final String ciAnversoUrl;
  final String ciReversoUrl;
  final String domicilioUrl;
  final String? saludFirmadaUrl;
  final String? respaldoIngresosUrl;
  final String? contratoFirmadoUrl;
  final bool validadoPorAnalista;
  final String? observacionesAnalista;

  ExpedienteModel({
    this.id,
    required this.cotizacionId,
    required this.ciAnversoUrl,
    required this.ciReversoUrl,
    required this.domicilioUrl,
    this.saludFirmadaUrl,
    this.respaldoIngresosUrl,
    this.contratoFirmadoUrl,
    this.validadoPorAnalista = false,
    this.observacionesAnalista,
  });

  factory ExpedienteModel.fromJson(Map<String, dynamic> json) {
    return ExpedienteModel(
      id: json['id'],
      cotizacionId: json['cotizacion'],
      ciAnversoUrl: json['ci_anverso_url'] ?? '',
      ciReversoUrl: json['ci_reverso_url'] ?? '',
      domicilioUrl: json['domicilio_url'] ?? '',
      saludFirmadaUrl: json['salud_firmada_url'],
      respaldoIngresosUrl: json['respaldo_ingresos_url'],
      contratoFirmadoUrl: json['contrato_firmado_url'],
      validadoPorAnalista: json['validado_por_analista'] ?? false,
      observacionesAnalista: json['observaciones_analista'],
    );
  }

  Map<String, dynamic> toJson() => {
    'cotizacion': cotizacionId,
    'ci_anverso_url': ciAnversoUrl,
    'ci_reverso_url': ciReversoUrl,
    'domicilio_url': domicilioUrl,
    if (saludFirmadaUrl != null) 'salud_firmada_url': saludFirmadaUrl,
    if (respaldoIngresosUrl != null) 'respaldo_ingresos_url': respaldoIngresosUrl,
    if (contratoFirmadoUrl != null) 'contrato_firmado_url': contratoFirmadoUrl,
  };
}