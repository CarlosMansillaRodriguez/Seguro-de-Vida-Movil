import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/cotizacion_service.dart';
import '../../services/orden_medica_service.dart';
import '../../models/orden_medica_model.dart';
import '../../services/documento_service.dart';
import '../../services/cu_extras_service.dart';

class CotizacionesPendientesScreen extends StatefulWidget {
  const CotizacionesPendientesScreen({super.key});

  @override
  State<CotizacionesPendientesScreen> createState() =>
      _CotizacionesPendientesScreenState();
}

class _CotizacionesPendientesScreenState
    extends State<CotizacionesPendientesScreen> {
  final _svc = AdminService(AuthService());
  final _cotSvc = CotizacionService(AuthService());
  final _ordSvc = OrdenMedicaService(AuthService());
  final _docSvc = DocumentoService(AuthService());

  List<Map<String, dynamic>> _cotizaciones = [];
  // Cache de órdenes médicas por cotización (id cotización -> orden o null)
  final Map<int, OrdenMedicaModel?> _ordenesCache = {};
  bool _loading = true;
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.listarCotizaciones();
      setState(() {
        _cotizaciones = data;
        _loading = false;
      });

      // Precargamos las órdenes médicas de las cotizaciones PENDIENTES
      // (el serializer del backend no incluye este dato, así que lo
      // resolvemos en el cliente consultando el endpoint real).
      for (final c in data.where((c) => c['estado'] == 'PENDIENTE')) {
        final id = c['id'] as int;
        if (!_ordenesCache.containsKey(id)) {
          try {
            final orden = await _ordSvc.obtenerOrdenPorCotizacion(id);
            if (mounted) {
              setState(() => _ordenesCache[id] = orden);
            }
          } catch (_) {
            if (mounted) setState(() => _ordenesCache[id] = null);
          }
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    if (_filtro == 'TODOS') return _cotizaciones;
    return _cotizaciones.where((c) => c['estado'] == _filtro).toList();
  }

  bool _puedeAceptar(Map<String, dynamic> c) {
    if (c['estado'] != 'PENDIENTE') return false;

    final expediente = c['expediente'] as Map?;
    if (expediente == null) return false;

    final tieneKyc =
        (expediente['ci_anverso_url'] ?? '').toString().isNotEmpty &&
        (expediente['ci_reverso_url'] ?? '').toString().isNotEmpty &&
        (expediente['domicilio_url'] ?? '').toString().isNotEmpty;

    if (!tieneKyc) return false;

    // Validamos la orden médica REAL (no la del JSON crudo, que no llega)
    final orden = _ordenesCache[c['id']];
    if (orden != null) {
      return orden.estado == 'COMPLETADA';
    }

    return true;
  }

  String _motivoBloqueo(Map<String, dynamic> c) {
    final expediente = c['expediente'] as Map?;
    if (expediente == null) {
      return 'El cliente aún no subió sus documentos KYC.';
    }
    final tieneKyc =
        (expediente['ci_anverso_url'] ?? '').toString().isNotEmpty &&
        (expediente['ci_reverso_url'] ?? '').toString().isNotEmpty &&
        (expediente['domicilio_url'] ?? '').toString().isNotEmpty;
    if (!tieneKyc) {
      return 'Faltan documentos KYC del cliente.';
    }
    final orden = _ordenesCache[c['id']];
    if (orden != null && orden.estado != 'COMPLETADA') {
      return 'La orden médica aún no está completada '
          '(estado: ${orden.estadoDisplay}).';
    }
    return '';
  }

  Future<void> _aceptar(int id) async {
    try {
      await _svc.aceptarCotizacion(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cotización aceptada')));
        _cargar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _verDetalles(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: _detallesCotizacion(c),
        ),
      ),
    );
  }

  /*-----------------------------------------------------*/
  Future<void> _validarExpediente(Map expediente) async {
    try {
      await _docSvc.validarExpediente(expediente['id']);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expediente validado')));

        _ordenesCache.clear();
        _cargar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rechazarExpedienteDialog(Map expediente) async {
    final motivoCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar documentos KYC'),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (motivoCtrl.text.trim().isEmpty) {
                return;
              }

              Navigator.pop(context);

              try {
                await _docSvc.rechazarExpediente(
                  expediente['id'],
                  motivoCtrl.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Documentos rechazados')),
                  );

                  _ordenesCache.clear();
                  _cargar();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<void> _emitirDictamenDialog(OrdenMedicaModel orden) async {
    String conclusion = 'APTO';
    double impacto = 0;
    final obsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Emitir dictamen médico'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: conclusion,
                decoration: const InputDecoration(
                  labelText: 'Conclusión',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'APTO', child: Text('Apto')),
                  DropdownMenuItem(
                    value: 'APTO_RESERVA',
                    child: Text('Apto con reserva'),
                  ),
                  DropdownMenuItem(value: 'NO_APTO', child: Text('No apto')),
                ],
                onChanged: (v) {
                  setSt(() => conclusion = v ?? 'APTO');
                },
              ),

              if (conclusion == 'APTO_RESERVA') ...[
                const SizedBox(height: 12),

                Slider(
                  value: impacto,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${impacto.toStringAsFixed(0)}%',
                  onChanged: (v) {
                    setSt(() => impacto = v);
                  },
                ),

                Text('${impacto.toStringAsFixed(0)}%'),
              ],

              const SizedBox(height: 12),

              TextField(
                controller: obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);

                try {
                  await _ordSvc.emitirDictamen(
                    ordenId: orden.id,
                    conclusion: conclusion,
                    impactoPrimaPct: impacto,
                    observaciones: obsCtrl.text.trim(),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dictamen emitido')),
                    );

                    _ordenesCache.clear();
                    _cargar();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Emitir'),
            ),
          ],
        ),
      ),
    );
  }
  /*----------------------------------------------------*/
  /*SP4*/
  Future<void> _ejecutarOcr(Map expediente) async {
    final svc = CuExtrasService(AuthService());
    setState(() {});
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Ejecutando OCR con Gemini Vision...'),
        ]),
      ),
    );
    try {
      final result = await svc.validarOcr(expediente['id']);
      if (!mounted) return;
      Navigator.pop(context); // cierra loading

      final estado = result['estado_ocr'] as String? ?? '';
      final datos = result['datos_extraidos'] as Map? ?? {};
      final discrepancias = result['discrepancias'] as Map? ?? {};
      final bloqueado = result['bloqueado_para_emision'] == true;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(children: [
            Icon(
              estado == 'VALIDADO_OCR'
                  ? Icons.check_circle
                  : estado == 'DISCREPANCIA'
                      ? Icons.warning_amber
                      : Icons.error_outline,
              color: estado == 'VALIDADO_OCR'
                  ? Colors.green
                  : estado == 'DISCREPANCIA'
                      ? Colors.orange
                      : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              estado == 'VALIDADO_OCR'
                  ? 'OCR Validado'
                  : estado == 'DISCREPANCIA'
                      ? 'Discrepancias encontradas'
                      : 'Error en OCR',
              style: const TextStyle(fontSize: 15),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (datos.isNotEmpty) ...[
                  const Text('Datos extraídos del documento:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 6),
                  ...datos.entries.map((e) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('${e.key}: ',
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12)),
                            Expanded(
                                child: Text('${e.value}',
                                    style: const TextStyle(
                                        fontSize: 12))),
                          ],
                        ),
                      )),
                ],
                if (discrepancias.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Discrepancias detectadas:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.orange)),
                  const SizedBox(height: 6),
                  ...discrepancias.entries.map((e) {
                    final diff = e.value as Map;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Campo: ${e.key}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          Text(
                              'En sistema: ${diff['en_sistema'] ?? '-'}',
                              style: const TextStyle(fontSize: 12)),
                          Text(
                              'En documento: ${diff['en_documento'] ?? '-'}',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  if (bloqueado)
                    const Text(
                      '⚠ Emisión de póliza bloqueada hasta resolver discrepancias.',
                      style: TextStyle(
                          color: Colors.red, fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // cierra loading
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error OCR: $e')));
    }
  }
  /*SP4*/

  Widget _detallesCotizacion(Map<String, dynamic> c) {
    final expediente = c['expediente'] as Map?;
    final orden = _ordenesCache[c['id']];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COT-${c['id'].toString().padLeft(5, '0')}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          'Cliente: ${c['cliente_nombre'] ?? c['cliente_email'] ?? '-'}',
          style: const TextStyle(color: Colors.grey),
        ),
        const Divider(height: 24),

        _fila('Capital', '\$${c['capital_asegurado'] ?? '-'}'),
        _fila('Nivel de riesgo', c['nivel_riesgo'] ?? '-'),
        _fila('Score', '${c['score_riesgo'] ?? '-'}/100'),
        _fila('Frecuencia', c['frecuencia_pago'] ?? '-'),
        _fila('Plazo', '${c['plazo_anios'] ?? '-'} años'),
        const SizedBox(height: 16),

        const Text(
          'Documentos KYC',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (expediente == null)
          const Text(
            'Sin documentos subidos',
            style: TextStyle(color: Colors.red),
          )
        else ...[
          _docItem('CI Anverso', expediente['ci_anverso_url'] ?? ''),
          _docItem('CI Reverso', expediente['ci_reverso_url'] ?? ''),
          _docItem('Domicilio', expediente['domicilio_url'] ?? ''),
          if ((expediente['salud_firmada_url'] ?? '').isNotEmpty)
            _docItem('Salud', expediente['salud_firmada_url']),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                expediente['validado_por_analista'] == true
                    ? Icons.check_circle
                    : Icons.pending,
                color: expediente['validado_por_analista'] == true
                    ? Colors.green
                    : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                expediente['validado_por_analista'] == true
                    ? 'KYC validado'
                    : 'KYC pendiente de validación',
                style: TextStyle(
                  color: expediente['validado_por_analista'] == true
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],

        // ── Orden médica (datos reales, no del JSON crudo) ────────────
        const SizedBox(height: 16),
        const Text(
          'Orden Médica',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (orden == null)
          const Text(
            'No requiere orden médica (o aún no se generó).',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          )
        else ...[
          _fila('Estado', orden.estadoDisplay),
          _fila(
            'Resultados',
            '${orden.resultados.length} / ${orden.examenesRequeridos.length}',
          ),
          if (orden.dictamen != null)
            _fila('Dictamen', orden.dictamen!.conclusionDisplay),
          const SizedBox(height: 6),
          ...orden.resultados.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${r.tipoExamen}: ${r.resultado}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (r.archivoUrl != null)
                    const Icon(Icons.attach_file, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
        /*SP4*/
        // ── HU-31: Validación de identidad por OCR ────────────────────
        if (expediente != null &&
            (expediente['ci_anverso_url'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _ejecutarOcr(expediente);
              },
              icon: const Icon(Icons.document_scanner_outlined,
                  size: 18),
              label: Text(
                expediente['estado_ocr'] == 'VALIDADO_OCR'
                    ? 'OCR: Identidad validada ✓'
                    : expediente['estado_ocr'] == 'DISCREPANCIA'
                        ? 'OCR: Ver discrepancias ⚠'
                        : 'Validar identidad con OCR',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    expediente['estado_ocr'] == 'VALIDADO_OCR'
                        ? Colors.green
                        : expediente['estado_ocr'] == 'DISCREPANCIA'
                            ? Colors.orange
                            : Colors.blue,
                side: BorderSide(
                  color:
                      expediente['estado_ocr'] == 'VALIDADO_OCR'
                          ? Colors.green
                          : expediente['estado_ocr'] ==
                                  'DISCREPANCIA'
                              ? Colors.orange
                              : Colors.blue,
                ),
              ),
            ),
          ),
        ],
        /*SP4*/
        /*----------------------------------------------*/
        // ── Acciones KYC ─────────────────────────────
        if (expediente != null &&
            expediente['validado_por_analista'] != true) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _rechazarExpedienteDialog(expediente);
                  },
                  child: const Text('Rechazar KYC'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _validarExpediente(expediente);
                  },
                  child: const Text('Validar KYC'),
                ),
              ),
            ],
          ),
        ],

        if (orden != null && orden.dictamen == null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.medical_information_outlined),
              label: Text(
                orden.tieneResultadosCompletos
                    ? 'Emitir dictamen médico'
                    : 'Faltan resultados médicos',
              ),
              onPressed: orden.tieneResultadosCompletos
                  ? () async {
                      Navigator.pop(context);
                      await _emitirDictamenDialog(orden);
                    }
                  : null,
            ),
          ),
        ],
        /*-------------------------------------------- */
      ],
    );
  }

  Widget _docItem(String label, String url) {
    final tiene = url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            tiene ? Icons.check_circle : Icons.radio_button_unchecked,
            color: tiene ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _fila(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Expanded(child: Text(valor, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ACEPTADA':
        return Colors.green;
      case 'RECHAZADA':
        return Colors.red;
      case 'EXPIRADA':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['TODOS', 'PENDIENTE', 'ACEPTADA', 'RECHAZADA']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f),
                        selected: _filtro == f,
                        onSelected: (_) => setState(() => _filtro = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                ? const Center(child: Text('Sin cotizaciones'))
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtradas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _tarjeta(_filtradas[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> c) {
    final estado = c['estado'] ?? '';
    final color = _colorEstado(estado);
    final id = c['id'];
    final puede = _puedeAceptar(c);
    final motivo = estado == 'PENDIENTE' && !puede ? _motivoBloqueo(c) : '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COT-${id.toString().padLeft(5, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cliente: ${c['cliente_nombre'] ?? c['cliente_email'] ?? '-'}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              'Capital: \$${c['capital_asegurado'] ?? '-'}',
              style: const TextStyle(fontSize: 13),
            ),

            if (motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        motivo,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _verDetalles(c),
                      child: const Text('Ver detalles'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: puede ? () => _aceptar(id) : null,
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _verDetalles(c),
                child: const Text('Ver detalles'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
