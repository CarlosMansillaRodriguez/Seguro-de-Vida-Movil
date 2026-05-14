class PlanModel {
  final int id;
  final String nombre;
  final String tipoPlan;
  final double capitalMinimo;
  final double capitalMaximo;
  final int plazoMinAnios;
  final int plazoMaxAnios;
  final String frecuenciasPermitidas;
  final double tasaBase;

  PlanModel({
    required this.id,
    required this.nombre,
    required this.tipoPlan,
    required this.capitalMinimo,
    required this.capitalMaximo,
    required this.plazoMinAnios,
    required this.plazoMaxAnios,
    required this.frecuenciasPermitidas,
    required this.tasaBase,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'],
      nombre: json['nombre'],
      tipoPlan: json['tipo_plan_display'] ?? json['tipo_plan'],
      capitalMinimo: double.parse(json['capital_minimo'].toString()),
      capitalMaximo: double.parse(json['capital_maximo'].toString()),
      plazoMinAnios: json['plazo_minimo_anios'],
      plazoMaxAnios: json['plazo_maximo_anios'],
      frecuenciasPermitidas: json['frecuencias_permitidas'],
      tasaBase: double.parse(json['tasa_base'].toString()),
    );
  }

  List<String> get frecuencias => frecuenciasPermitidas.split(',').map((e) => e.trim()).toList();
}

class CotizacionResultado {
  final int cotizacionId;
  final String cliente;
  final String plan;
  final double capitalAsegurado;
  final int plazoAnios;
  final String frecuenciaPago;
  final int scoreRiesgo;
  final String nivelRiesgo;
  final Map<String, dynamic> detalleRiesgo;
  final double primaBaseAnual;
  final double primaAjustadaAnual;
  final double primaPorFrecuencia;
  final String estado;
  final String? validaHasta;

  CotizacionResultado({
    required this.cotizacionId,
    required this.cliente,
    required this.plan,
    required this.capitalAsegurado,
    required this.plazoAnios,
    required this.frecuenciaPago,
    required this.scoreRiesgo,
    required this.nivelRiesgo,
    required this.detalleRiesgo,
    required this.primaBaseAnual,
    required this.primaAjustadaAnual,
    required this.primaPorFrecuencia,
    required this.estado,
    this.validaHasta,
  });

  factory CotizacionResultado.fromJson(Map<String, dynamic> json) {
    final prima = json['prima'] ?? {};
    final riesgo = json['evaluacion_riesgo'] ?? {};
    return CotizacionResultado(
      cotizacionId: json['cotizacion_id'],
      cliente: json['cliente'] ?? '',
      plan: json['plan'] ?? '',
      capitalAsegurado: double.parse(json['capital_asegurado'].toString()),
      plazoAnios: json['plazo_anios'],
      frecuenciaPago: json['frecuencia_pago'],
      scoreRiesgo: riesgo['score_riesgo'] ?? 0,
      nivelRiesgo: riesgo['nivel_riesgo'] ?? '',
      detalleRiesgo: Map<String, dynamic>.from(riesgo['detalle'] ?? {}),
      primaBaseAnual: double.parse((prima['base_anual'] ?? 0).toString()),
      primaAjustadaAnual: double.parse((prima['ajustada_anual'] ?? 0).toString()),
      primaPorFrecuencia: double.parse((prima.values.lastWhere(
        (v) => v is double || v is int,
        orElse: () => 0,
      )).toString()),
      estado: json['estado'] ?? '',
      validaHasta: json['valida_hasta']?.toString(),
    );
  }
}