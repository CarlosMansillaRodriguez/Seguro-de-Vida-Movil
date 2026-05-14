class OrdenMedicaModel {
  final int id;
  final int cotizacionId;
  final int clienteId;
  final String clienteNombre;
  final List<String> examenesRequeridos;
  final String estado;
  final String estadoDisplay;
  final String fechaGeneracion;
  final String? fechaLimite;
  final String? notasAdicionales;
  final List<ResultadoMedicoModel> resultados;
  final DictamenMedicoModel? dictamen;

  OrdenMedicaModel({
    required this.id,
    required this.cotizacionId,
    required this.clienteId,
    required this.clienteNombre,
    required this.examenesRequeridos,
    required this.estado,
    required this.estadoDisplay,
    required this.fechaGeneracion,
    this.fechaLimite,
    this.notasAdicionales,
    required this.resultados,
    this.dictamen,
  });

  factory OrdenMedicaModel.fromJson(Map<String, dynamic> json) {
    return OrdenMedicaModel(
      id: json['id'],
      cotizacionId: json['cotizacion'],
      clienteId: json['cliente'],
      clienteNombre: json['cliente_nombre'] ?? '',
      examenesRequeridos:
          List<String>.from(json['examenes_requeridos'] ?? []),
      estado: json['estado'],
      estadoDisplay: json['estado_display'] ?? json['estado'],
      fechaGeneracion: json['fecha_generacion'] ?? '',
      fechaLimite: json['fecha_limite'],
      notasAdicionales: json['notas_adicionales'],
      resultados: (json['resultados'] as List? ?? [])
          .map((r) => ResultadoMedicoModel.fromJson(r))
          .toList(),
      dictamen: json['dictamen'] != null
          ? DictamenMedicoModel.fromJson(json['dictamen'])
          : null,
    );
  }

  // Indica si el cliente ya cargó todos los resultados
  bool get tieneResultadosCompletos =>
      resultados.length >= examenesRequeridos.length &&
      examenesRequeridos.isNotEmpty;
}

class ResultadoMedicoModel {
  final int id;
  final String tipoExamen;
  final String resultado;
  final String? archivoUrl;
  final bool? esNormal;
  final String? fechaExamen;

  ResultadoMedicoModel({
    required this.id,
    required this.tipoExamen,
    required this.resultado,
    this.archivoUrl,
    this.esNormal,
    this.fechaExamen,
  });

  factory ResultadoMedicoModel.fromJson(Map<String, dynamic> json) {
    return ResultadoMedicoModel(
      id: json['id'],
      tipoExamen: json['tipo_examen'] ?? '',
      resultado: json['resultado'] ?? '',
      archivoUrl: json['archivo'],
      esNormal: json['es_normal'],
      fechaExamen: json['fecha_examen'],
    );
  }
}

class DictamenMedicoModel {
  final int id;
  final String conclusion;
  final String conclusionDisplay;
  final double impactoPrimaPct;
  final String observaciones;
  final String fechaDictamen;

  DictamenMedicoModel({
    required this.id,
    required this.conclusion,
    required this.conclusionDisplay,
    required this.impactoPrimaPct,
    required this.observaciones,
    required this.fechaDictamen,
  });

  factory DictamenMedicoModel.fromJson(Map<String, dynamic> json) {
    return DictamenMedicoModel(
      id: json['id'],
      conclusion: json['conclusion'] ?? '',
      conclusionDisplay: json['conclusion_display'] ?? json['conclusion'] ?? '',
      impactoPrimaPct:
          double.parse((json['impacto_prima_pct'] ?? 0).toString()),
      observaciones: json['observaciones'] ?? '',
      fechaDictamen: json['fecha_dictamen'] ?? '',
    );
  }
}