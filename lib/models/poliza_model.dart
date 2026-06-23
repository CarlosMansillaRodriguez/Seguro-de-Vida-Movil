/*class PolizaModel {
  final int id;
  final String numeroPoliza;
  final String estado;
  final String fechaEmision;
  final String fechaInicioVigencia;
  final String fechaVencimiento;
  final double primaFinalFacturada;
  final int cotizacionId;
  final List<BeneficiarioModel> beneficiarios;

  PolizaModel({
    required this.id,
    required this.numeroPoliza,
    required this.estado,
    required this.fechaEmision,
    required this.fechaInicioVigencia,
    required this.fechaVencimiento,
    required this.primaFinalFacturada,
    required this.cotizacionId,
    required this.beneficiarios,
  });

  factory PolizaModel.fromJson(Map<String, dynamic> json) {
    return PolizaModel(
      id: json['id'],
      numeroPoliza: json['numero_poliza'],
      estado: json['estado'],
      fechaEmision: json['fecha_emision'] ?? '',
      fechaInicioVigencia: json['fecha_inicio_vigencia'] ?? '',
      fechaVencimiento: json['fecha_vencimiento'] ?? '',
      primaFinalFacturada: double.parse(json['prima_final_facturada'].toString()),
      cotizacionId: json['cotizacion'],
      beneficiarios: (json['beneficiarios'] as List? ?? [])
          .map((b) => BeneficiarioModel.fromJson(b))
          .toList(),
    );
  }

  String get estadoDisplay {
    const map = {
      'ACTIVA': 'Activa',
      'SUSPENDIDA': 'Suspendida',
      'VENCIDA': 'Vencida',
      'RENOVADA': 'Renovada',
      'CANCELADA': 'Cancelada',
    };
    return map[estado] ?? estado;
  }
}

class BeneficiarioModel {
  final int? id;
  final String nombreCompleto;
  final String? documentoIdentidad;
  final String fechaNacimiento;
  final String parentesco;
  final double porcentajeAsignado;
  final TutorLegalModel? tutorLegal;

  BeneficiarioModel({
    this.id,
    required this.nombreCompleto,
    this.documentoIdentidad,
    required this.fechaNacimiento,
    required this.parentesco,
    required this.porcentajeAsignado,
    this.tutorLegal,
  });

  factory BeneficiarioModel.fromJson(Map<String, dynamic> json) {
    return BeneficiarioModel(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      documentoIdentidad: json['documento_identidad'],
      fechaNacimiento: json['fecha_nacimiento'],
      parentesco: json['parentesco'],
      porcentajeAsignado: double.parse(json['porcentaje_asignado'].toString()),
      tutorLegal: json['tutor_legal'] != null
          ? TutorLegalModel.fromJson(json['tutor_legal'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento,
      'parentesco': parentesco,
      'porcentaje_asignado': porcentajeAsignado,
      if (documentoIdentidad != null) 'documento_identidad': documentoIdentidad,
      if (tutorLegal != null) 'tutor': tutorLegal!.toJson(),
    };
    return map;
  }
}

class TutorLegalModel {
  final int? id;
  final String nombreCompleto;
  final String documentoIdentidad;
  final String fechaNacimiento;
  final String telefono;
  final String direccion;

  TutorLegalModel({
    this.id,
    required this.nombreCompleto,
    required this.documentoIdentidad,
    required this.fechaNacimiento,
    required this.telefono,
    required this.direccion,
  });

  factory TutorLegalModel.fromJson(Map<String, dynamic> json) {
    return TutorLegalModel(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      documentoIdentidad: json['documento_identidad'],
      fechaNacimiento: json['fecha_nacimiento'],
      telefono: json['telefono'] ?? '',
      direccion: json['direccion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre_completo': nombreCompleto,
    'documento_identidad': documentoIdentidad,
    'fecha_nacimiento': fechaNacimiento,
    'telefono': telefono,
    'direccion': direccion,
  };
}*/
class PolizaModel {
  final int id;
  final String numeroPoliza;
  final String estado;
  final String fechaEmision;
  final String fechaInicioVigencia;
  final String fechaVencimiento;
  final double primaFinalFacturada;
  final int cotizacionId;
  final List<BeneficiarioModel> beneficiarios;
 
  PolizaModel({
    required this.id,
    required this.numeroPoliza,
    required this.estado,
    required this.fechaEmision,
    required this.fechaInicioVigencia,
    required this.fechaVencimiento,
    required this.primaFinalFacturada,
    required this.cotizacionId,
    required this.beneficiarios,
  });
 
  factory PolizaModel.fromJson(Map<String, dynamic> json) {
    // El campo 'cotizacion' puede llegar como int (ID) o como Map (objeto anidado).
    // El backend puede devolver cualquiera de los dos según el serializer usado.
    int cotId = 0;
    final cotRaw = json['cotizacion'];
    if (cotRaw is int) {
      cotId = cotRaw;
    } else if (cotRaw is Map) {
      cotId = (cotRaw['id'] as int?) ?? 0;
    }
 
    // 'beneficiarios' puede llegar como lista de Maps o lista de ints (IDs).
    // Solo mapeamos si son Maps completos.
    List<BeneficiarioModel> bens = [];
    final bensRaw = json['beneficiarios'];
    if (bensRaw is List) {
      for (final b in bensRaw) {
        if (b is Map<String, dynamic>) {
          bens.add(BeneficiarioModel.fromJson(b));
        }
        // Si es int (solo ID) lo ignoramos; no tenemos datos para construir el modelo.
      }
    }
 
    return PolizaModel(
      id: json['id'] as int,
      numeroPoliza: (json['numero_poliza'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      fechaEmision: (json['fecha_emision'] ?? '').toString(),
      fechaInicioVigencia: (json['fecha_inicio_vigencia'] ?? '').toString(),
      fechaVencimiento: (json['fecha_vencimiento'] ?? '').toString(),
      primaFinalFacturada: double.parse(
          (json['prima_final_facturada'] ?? 0).toString()),
      cotizacionId: cotId,
      beneficiarios: bens,
    );
  }
 
  String get estadoDisplay {
    const map = {
      'ACTIVA': 'Activa',
      'SUSPENDIDA': 'Suspendida',
      'VENCIDA': 'Vencida',
      'RENOVADA': 'Renovada',
      'CANCELADA': 'Cancelada',
    };
    return map[estado] ?? estado;
  }
}
 
class BeneficiarioModel {
  final int? id;
  final String nombreCompleto;
  final String? documentoIdentidad;
  final String fechaNacimiento;
  final String parentesco;
  final double porcentajeAsignado;
  final TutorLegalModel? tutorLegal;
 
  BeneficiarioModel({
    this.id,
    required this.nombreCompleto,
    this.documentoIdentidad,
    required this.fechaNacimiento,
    required this.parentesco,
    required this.porcentajeAsignado,
    this.tutorLegal,
  });
 
  factory BeneficiarioModel.fromJson(Map<String, dynamic> json) {
    return BeneficiarioModel(
      id: json['id'] as int?,
      nombreCompleto: (json['nombre_completo'] ?? '').toString(),
      documentoIdentidad: json['documento_identidad']?.toString(),
      fechaNacimiento: (json['fecha_nacimiento'] ?? '').toString(),
      parentesco: (json['parentesco'] ?? '').toString(),
      porcentajeAsignado: double.parse(
          (json['porcentaje_asignado'] ?? 0).toString()),
      tutorLegal: json['tutor_legal'] is Map<String, dynamic>
          ? TutorLegalModel.fromJson(
              json['tutor_legal'] as Map<String, dynamic>)
          : null,
    );
  }
 
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento,
      'parentesco': parentesco,
      'porcentaje_asignado': porcentajeAsignado,
      if (documentoIdentidad != null)
        'documento_identidad': documentoIdentidad,
      if (tutorLegal != null) 'tutor': tutorLegal!.toJson(),
    };
  }
}
 
class TutorLegalModel {
  final int? id;
  final String nombreCompleto;
  final String documentoIdentidad;
  final String fechaNacimiento;
  final String telefono;
  final String direccion;
 
  TutorLegalModel({
    this.id,
    required this.nombreCompleto,
    required this.documentoIdentidad,
    required this.fechaNacimiento,
    required this.telefono,
    required this.direccion,
  });
 
  factory TutorLegalModel.fromJson(Map<String, dynamic> json) {
    return TutorLegalModel(
      id: json['id'] as int?,
      nombreCompleto: (json['nombre_completo'] ?? '').toString(),
      documentoIdentidad: (json['documento_identidad'] ?? '').toString(),
      fechaNacimiento: (json['fecha_nacimiento'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
    );
  }
 
  Map<String, dynamic> toJson() => {
        'nombre_completo': nombreCompleto,
        'documento_identidad': documentoIdentidad,
        'fecha_nacimiento': fechaNacimiento,
        'telefono': telefono,
        'direccion': direccion,
      };
}