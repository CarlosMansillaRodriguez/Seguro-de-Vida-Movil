/*import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/cotizacion_service.dart';

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
  List<Map<String, dynamic>> _cotizaciones = [];
  bool _loading = true;
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarCotizaciones();
      setState(() {
        _cotizaciones = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    if (_filtro == 'TODOS') return _cotizaciones;
    return _cotizaciones
        .where((c) => c['estado'] == _filtro)
        .toList();
  }

  // Verifica si la cotización tiene KYC validado y (si aplica) orden médica
  bool _puedeAceptar(Map<String, dynamic> c) {
    // Solo las ACEPTADAS por el cliente (estado PENDIENTE en backend = esperando agente)
    if (c['estado'] != 'PENDIENTE') return false;

    final expediente = c['expediente'] as Map?;
    if (expediente == null) return false;

    // Debe tener al menos los 3 documentos obligatorios subidos
    final tieneKyc = (expediente['ci_anverso_url'] ?? '').toString().isNotEmpty &&
        (expediente['ci_reverso_url'] ?? '').toString().isNotEmpty &&
        (expediente['domicilio_url'] ?? '').toString().isNotEmpty;

    if (!tieneKyc) return false;

    // Si tiene orden médica, debe estar completada
    final ordenMedica = c['orden_medica'] as Map?;
    if (ordenMedica != null) {
      return ordenMedica['estado'] == 'COMPLETADA';
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
    final ordenMedica = c['orden_medica'] as Map?;
    if (ordenMedica != null && ordenMedica['estado'] != 'COMPLETADA') {
      return 'La orden médica aún no está completada '
          '(estado: ${ordenMedica['estado']}).';
    }
    return '';
  }

  Future<void> _aceptar(int id) async {
    try {
      await _svc.aceptarCotizacion(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización aceptada')),
        );
        _cargar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rechazar(int id) async {
    final motivoCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar cotización'),
        content: TextField(
          controller: motivoCtrl,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (motivoCtrl.text.trim().length < 5) return;
              Navigator.pop(context);
              // El backend no tiene endpoint de rechazo manual por agente,
              // por lo que mostramos aviso. Si se agrega en el futuro,
              // llamar al endpoint correspondiente.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Rechazo registrado localmente. Contacta al administrador si necesitas actualizar el estado en el sistema.')),
                );
              }
            },
            child: const Text('Rechazar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _verDetalles(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
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

  Widget _detallesCotizacion(Map<String, dynamic> c) {
    final expediente = c['expediente'] as Map?;
    final ordenMedica = c['orden_medica'] as Map?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COT-${c['id'].toString().padLeft(5, '0')}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(
            'Cliente: ${c['cliente_nombre'] ?? c['cliente_email'] ?? '-'}',
            style: const TextStyle(color: Colors.grey)),
        const Divider(height: 24),

        // ── Datos cotización ────────────────────────────────
        _fila('Capital', '\$${c['capital_asegurado'] ?? '-'}'),
        _fila('Nivel de riesgo', c['nivel_riesgo'] ?? '-'),
        _fila('Score', '${c['score_riesgo'] ?? '-'}/100'),
        _fila('Frecuencia', c['frecuencia_pago'] ?? '-'),
        _fila('Plazo', '${c['plazo_anios'] ?? '-'} años'),
        const SizedBox(height: 16),

        // ── KYC ────────────────────────────────────────────
        const Text('Documentos KYC',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (expediente == null)
          const Text('Sin documentos subidos',
              style: TextStyle(color: Colors.red))
        else ...[
          _docItem('CI Anverso',
              expediente['ci_anverso_url'] ?? ''),
          _docItem('CI Reverso',
              expediente['ci_reverso_url'] ?? ''),
          _docItem(
              'Domicilio', expediente['domicilio_url'] ?? ''),
          if ((expediente['salud_firmada_url'] ?? '').isNotEmpty)
            _docItem('Salud', expediente['salud_firmada_url']),
          const SizedBox(height: 8),
          Row(children: [
            Icon(
              expediente['validado_por_analista'] == true
                  ? Icons.check_circle
                  : Icons.pending,
              color:
                  expediente['validado_por_analista'] == true
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
                color:
                    expediente['validado_por_analista'] == true
                        ? Colors.green
                        : Colors.orange,
                fontSize: 13,
              ),
            ),
          ]),
        ],

        // ── Orden médica ────────────────────────────────────
        if (ordenMedica != null) ...[
          const SizedBox(height: 16),
          const Text('Orden Médica',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          _fila('Estado', ordenMedica['estado_display'] ??
              ordenMedica['estado'] ?? '-'),
          _fila('Resultados',
              '${ordenMedica['total_resultados'] ?? 0} / ${ordenMedica['total_examenes'] ?? 0}'),
        ],
      ],
    );
  }

  Widget _docItem(String label, String url) {
    final tiene = url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(
          tiene ? Icons.check_circle : Icons.radio_button_unchecked,
          color: tiene ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }

  Widget _fila(String label, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
            Expanded(
                child: Text(valor,
                    style: const TextStyle(fontSize: 13))),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['TODOS', 'PENDIENTE', 'ACEPTADA', 'RECHAZADA']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: _filtro == f,
                          onSelected: (_) =>
                              setState(() => _filtro = f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                    ? const Center(
                        child: Text('Sin cotizaciones'))
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtradas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _tarjeta(_filtradas[i]),
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
    final motivo = estado == 'PENDIENTE' && !puede
        ? _motivoBloqueo(c)
        : '';

    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('COT-${id.toString().padLeft(5, '0')}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(estado,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                'Cliente: ${c['cliente_nombre'] ?? c['cliente_email'] ?? '-'}',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
            Text('Capital: \$${c['capital_asegurado'] ?? '-'}',
                style: const TextStyle(fontSize: 13)),

            if (motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: Colors.orange[200]!),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(motivo,
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12)),
                  ),
                ]),
              ),
            ],

            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 10),
              Row(children: [
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
              ]),
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
}*/
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/cotizacion_service.dart';
import '../../services/orden_medica_service.dart';
import '../../models/orden_medica_model.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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

    final tieneKyc = (expediente['ci_anverso_url'] ?? '').toString().isNotEmpty &&
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización aceptada')),
        );
        _cargar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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

  Widget _detallesCotizacion(Map<String, dynamic> c) {
    final expediente = c['expediente'] as Map?;
    final orden = _ordenesCache[c['id']];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COT-${c['id'].toString().padLeft(5, '0')}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text('Cliente: ${c['cliente_nombre'] ?? c['cliente_email'] ?? '-'}',
            style: const TextStyle(color: Colors.grey)),
        const Divider(height: 24),

        _fila('Capital', '\$${c['capital_asegurado'] ?? '-'}'),
        _fila('Nivel de riesgo', c['nivel_riesgo'] ?? '-'),
        _fila('Score', '${c['score_riesgo'] ?? '-'}/100'),
        _fila('Frecuencia', c['frecuencia_pago'] ?? '-'),
        _fila('Plazo', '${c['plazo_anios'] ?? '-'} años'),
        const SizedBox(height: 16),

        const Text('Documentos KYC',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (expediente == null)
          const Text('Sin documentos subidos', style: TextStyle(color: Colors.red))
        else ...[
          _docItem('CI Anverso', expediente['ci_anverso_url'] ?? ''),
          _docItem('CI Reverso', expediente['ci_reverso_url'] ?? ''),
          _docItem('Domicilio', expediente['domicilio_url'] ?? ''),
          if ((expediente['salud_firmada_url'] ?? '').isNotEmpty)
            _docItem('Salud', expediente['salud_firmada_url']),
          const SizedBox(height: 8),
          Row(children: [
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
          ]),
        ],

        // ── Orden médica (datos reales, no del JSON crudo) ────────────
        const SizedBox(height: 16),
        const Text('Orden Médica',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (orden == null)
          const Text('No requiere orden médica (o aún no se generó).',
              style: TextStyle(color: Colors.grey, fontSize: 13))
        else ...[
          _fila('Estado', orden.estadoDisplay),
          _fila('Resultados',
              '${orden.resultados.length} / ${orden.examenesRequeridos.length}'),
          if (orden.dictamen != null)
            _fila('Dictamen', orden.dictamen!.conclusionDisplay),
          const SizedBox(height: 6),
          ...orden.resultados.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 16, color: Colors.blue),
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
              )),
        ],
      ],
    );
  }

  Widget _docItem(String label, String url) {
    final tiene = url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(
          tiene ? Icons.check_circle : Icons.radio_button_unchecked,
          color: tiene ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }

  Widget _fila(String label, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: _filtro == f,
                          onSelected: (_) => setState(() => _filtro = f),
                        ),
                      ))
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
                Text('COT-${id.toString().padLeft(5, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(estado,
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Cliente: ${c['cliente_nombre'] ?? c['cliente_email'] ?? '-'}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text('Capital: \$${c['capital_asegurado'] ?? '-'}',
                style: const TextStyle(fontSize: 13)),

            if (motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(motivo,
                        style: const TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
                ]),
              ),
            ],

            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 10),
              Row(children: [
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
              ]),
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