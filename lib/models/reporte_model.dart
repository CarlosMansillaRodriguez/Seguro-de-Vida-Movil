/// Metadatos de un campo devueltos por /api/reportes/metadata/
class CampoMetadata {
  final String name;
  final String label;
  final String type;

  CampoMetadata({
    required this.name,
    required this.label,
    required this.type,
  });

  factory CampoMetadata.fromJson(Map<String, dynamic> json) {
    return CampoMetadata(
      name: json['name'] ?? '',
      label: json['label'] ?? json['name'] ?? '',
      type: json['type'] ?? 'CharField',
    );
  }

  // Indica si el campo admite filtro de rango (fechas, números)
  bool get esRango =>
      type.contains('Date') ||
      type.contains('Integer') ||
      type.contains('Decimal') ||
      type.contains('Float');

  // Indica si es booleano
  bool get esBooleano => type == 'BooleanField';
}

/// Metadatos de un modelo completo
class ModeloMetadata {
  final String appLabel; // Ej: "polizas_de_seguro.poliza"
  final String verboseName;
  final String verboseNamePlural;
  final List<CampoMetadata> campos;

  ModeloMetadata({
    required this.appLabel,
    required this.verboseName,
    required this.verboseNamePlural,
    required this.campos,
  });

  factory ModeloMetadata.fromJson(String key, Map<String, dynamic> json) {
    return ModeloMetadata(
      appLabel: key,
      verboseName: json['verbose_name'] ?? key,
      verboseNamePlural: json['verbose_name_plural'] ?? key,
      campos: (json['fields'] as List? ?? [])
          .map((f) => CampoMetadata.fromJson(f))
          .toList(),
    );
  }
}

/// Filtro activo definido por el usuario
class FiltroActivo {
  final CampoMetadata campo;
  String operador; // '', '__icontains', '__gte', '__lte', '__in'
  String valor;

  FiltroActivo({
    required this.campo,
    this.operador = '',
    this.valor = '',
  });

  // Convierte a query param para el backend
  // Ej: campo.name='estado', operador='__icontains', valor='ACT'
  // → {'estado__icontains': 'ACT'}
  MapEntry<String, String> toQueryParam() {
    final key = '${campo.name}$operador';
    return MapEntry(key, valor);
  }

  bool get esValido => valor.trim().isNotEmpty;
}