class PagoModel {
  final int id;
  final int polizaId;
  final String numeroPoliza;
  final String clienteNombre;
  final double monto;
  final String fechaPago;
  final String metodoPago;
  final String metodoPagoDisplay;
  final String nroComprobante;
  final String estado;
  final String estadoDisplay;
  final String? observaciones;
  final int? registradoPorId;
  final String registradoPorNombre;

  PagoModel({
    required this.id,
    required this.polizaId,
    required this.numeroPoliza,
    required this.clienteNombre,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    required this.metodoPagoDisplay,
    required this.nroComprobante,
    required this.estado,
    required this.estadoDisplay,
    this.observaciones,
    this.registradoPorId,
    required this.registradoPorNombre,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: json['id'],
      polizaId: json['poliza'],
      numeroPoliza: json['numero_poliza'] ?? '',
      clienteNombre: json['cliente_nombre'] ?? '',
      monto: double.parse((json['monto'] ?? 0).toString()),
      fechaPago: json['fecha_pago'] ?? '',
      metodoPago: json['metodo_pago'] ?? '',
      metodoPagoDisplay: json['metodo_pago_display'] ?? json['metodo_pago'] ?? '',
      nroComprobante: json['nro_comprobante'] ?? '',
      estado: json['estado'] ?? '',
      estadoDisplay: json['estado_display'] ?? json['estado'] ?? '',
      observaciones: json['observaciones'],
      registradoPorId: json['registrado_por'],
      registradoPorNombre: json['registrado_por_nombre'] ?? 'Stripe (Automático)',
    );
  }

  bool get esCompletado => estado == 'COMPLETADO';
}