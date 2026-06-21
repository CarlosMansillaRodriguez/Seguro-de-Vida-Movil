/*import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/poliza_service.dart';
import '../../services/cotizacion_service.dart';
import '../../models/poliza_model.dart';
import '../beneficiario/beneficiarios_form_screen.dart';
import '../pago/pagar_poliza_screen.dart';

class EmitirPolizaScreen extends StatefulWidget {
  const EmitirPolizaScreen({super.key});

  @override
  State<EmitirPolizaScreen> createState() => _EmitirPolizaScreenState();
}

class _EmitirPolizaScreenState extends State<EmitirPolizaScreen> {
  final _cotSvc = CotizacionService(AuthService());
  final _polSvc = PolizaService(AuthService());

  List<Map<String, dynamic>> _cotizaciones = [];
  Map<String, dynamic>? _cotizacionSeleccionada;
  List<BeneficiarioModel> _beneficiarios = [];
  bool _loading = true;
  bool _emitiendo = false;

  @override
  void initState() {
    super.initState();
    _cargarCotizaciones();
  }

  Future<void> _cargarCotizaciones() async {
    try {
      final all = await _cotSvc.listarCotizaciones();
      // Solo cotizaciones ACEPTADAS por el agente
      final aceptadas =
          all.where((c) => c['estado'] == 'ACEPTADA').toList();
      setState(() {
        _cotizaciones = aceptadas;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _agregarBeneficiario() async {
    final result = await Navigator.push<BeneficiarioModel>(
      context,
      MaterialPageRoute(
          builder: (_) => const BeneficiariosFormScreen()),
    );
    if (result != null) setState(() => _beneficiarios.add(result));
  }

  double get _totalPorcentaje =>
      _beneficiarios.fold(0.0, (s, b) => s + b.porcentajeAsignado);

  Future<void> _emitir() async {
    if (_cotizacionSeleccionada == null) {
      _snack('Selecciona una cotización');
      return;
    }
    if (_beneficiarios.isEmpty) {
      _snack('Agrega al menos un beneficiario');
      return;
    }
    if (_totalPorcentaje != 100) {
      _snack(
          'Los porcentajes deben sumar 100%. Actual: ${_totalPorcentaje.toStringAsFixed(0)}%');
      return;
    }

    setState(() => _emitiendo = true);
    try {
      final poliza = await _polSvc.emitirPoliza(
        cotizacionId: _cotizacionSeleccionada!['id'],
        beneficiarios: _beneficiarios,
      );
      if (mounted) {
        // Redirigir directamente al pago
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PagarPolizaScreen(poliza: poliza),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _emitiendo = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emitir póliza')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seccion('1. Selecciona la cotización aceptada'),
                  const SizedBox(height: 8),
                  if (_cotizaciones.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Text(
                        'No tienes cotizaciones aceptadas por un agente.\n\n'
                        'Primero cotiza un seguro y espera a que un agente revise '
                        'tu solicitud y documentos.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    )
                  else
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _cotizacionSeleccionada,
                      decoration: const InputDecoration(
                        hintText: 'Selecciona cotización',
                        border: OutlineInputBorder(),
                      ),
                      items: _cotizaciones
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                    'COT-${c['id'].toString().padLeft(5, '0')} — \$${c['capital_asegurado']}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _cotizacionSeleccionada = v),
                    ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _seccion('2. Beneficiarios'),
                      TextButton.icon(
                        onPressed: _agregarBeneficiario,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),

                  if (_beneficiarios.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin beneficiarios aún.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    ..._beneficiarios
                        .asMap()
                        .entries
                        .map((e) =>
                            _tarjetaBeneficiario(e.key, e.value)),
                    const SizedBox(height: 8),
                    _totalBar(),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _emitiendo ? null : _emitir,
                      child: _emitiendo
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Emitir póliza',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _tarjetaBeneficiario(int idx, BeneficiarioModel b) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text(b.nombreCompleto),
          subtitle: Text(
              '${b.parentesco} — ${b.porcentajeAsignado.toStringAsFixed(0)}%'
              '${b.tutorLegal != null ? ' (tutor: ${b.tutorLegal!.nombreCompleto})' : ''}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () =>
                setState(() => _beneficiarios.removeAt(idx)),
          ),
        ),
      );

  Widget _totalBar() {
    final total = _totalPorcentaje;
    final ok = total == 100;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: ok ? Colors.green[200]! : Colors.orange[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total asignado:',
              style: TextStyle(
                  color: ok ? Colors.green : Colors.orange)),
          Text('${total.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ok ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 15));
}*/
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/poliza_service.dart';
import '../../services/cotizacion_service.dart';
import '../../models/poliza_model.dart';
import '../beneficiario/beneficiarios_form_screen.dart';
import '../pago/pagar_poliza_screen.dart';

class EmitirPolizaScreen extends StatefulWidget {
  const EmitirPolizaScreen({super.key});

  @override
  State<EmitirPolizaScreen> createState() => _EmitirPolizaScreenState();
}

class _EmitirPolizaScreenState extends State<EmitirPolizaScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  late final CotizacionService _cotSvc;
  late final PolizaService _polSvc;
  late TabController _tabs;

  // ── Tab 1: Emitir ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _cotizaciones = [];
  Map<String, dynamic>? _cotizacionSeleccionada;
  List<BeneficiarioModel> _beneficiarios = [];
  bool _loadingCot = true;
  bool _emitiendo = false;

  // ── Tab 2: Mis pólizas activas ───────────────────────────────────────────
  List<PolizaModel> _polizasActivas = [];
  bool _loadingPol = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _cotSvc = CotizacionService(_auth);
    _polSvc = PolizaService(_auth);
    _cargarCotizaciones();
    _cargarPolizas();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargarCotizaciones() async {
    setState(() => _loadingCot = true);
    try {
      final all = await _cotSvc.listarCotizaciones();

      // Filtramos: solo ACEPTADAS que tengan KYC validado
      // (esas son las que realmente pueden emitir póliza)
      final listas = all.where((c) {
        if (c['estado'] != 'ACEPTADA') return false;

        // Si ya tiene póliza activa emitida, no mostrar
        // (esto lo controlamos en la pestaña de pólizas activas)
        // Aquí mostramos todas las ACEPTADAS para que el cliente pueda emitir
        return true;
      }).toList();

      setState(() {
        _cotizaciones = listas;
        _loadingCot = false;
      });
    } catch (e) {
      setState(() => _loadingCot = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cargarPolizas() async {
    setState(() => _loadingPol = true);
    try {
      final all = await _polSvc.listarPolizas();
      setState(() {
        // Solo pólizas ACTIVAS del cliente logueado
        _polizasActivas =
            all.where((p) => p.estado == 'ACTIVA').toList();
        _loadingPol = false;
      });
    } catch (_) {
      setState(() => _loadingPol = false);
    }
  }

  Future<void> _agregarBeneficiario() async {
    final result = await Navigator.push<BeneficiarioModel>(
      context,
      MaterialPageRoute(
          builder: (_) => const BeneficiariosFormScreen()),
    );
    if (result != null) setState(() => _beneficiarios.add(result));
  }

  Future<void> _editarBeneficiario(int idx) async {
    final actual = _beneficiarios[idx];
    final result = await Navigator.push<BeneficiarioModel>(
      context,
      MaterialPageRoute(
        builder: (_) => BeneficiariosFormScreen(inicial: actual),
      ),
    );
    if (result != null) {
      setState(() => _beneficiarios[idx] = result);
    }
  }

  double get _totalPorcentaje =>
      _beneficiarios.fold(0.0, (s, b) => s + b.porcentajeAsignado);

  Future<void> _emitir() async {
    if (_cotizacionSeleccionada == null) {
      _snack('Selecciona una cotización');
      return;
    }
    if (_beneficiarios.isEmpty) {
      _snack('Agrega al menos un beneficiario');
      return;
    }
    if ((_totalPorcentaje - 100).abs() > 0.01) {
      _snack(
          'Los porcentajes deben sumar 100%. Actual: ${_totalPorcentaje.toStringAsFixed(0)}%');
      return;
    }

    setState(() => _emitiendo = true);
    try {
      final poliza = await _polSvc.emitirPoliza(
        cotizacionId: _cotizacionSeleccionada!['id'],
        beneficiarios: _beneficiarios,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PagarPolizaScreen(poliza: poliza),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _emitiendo = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pólizas'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Emitir nueva'),
            Tab(text: 'Pólizas activas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_tabEmitir(), _tabPolizasActivas()],
      ),
    );
  }

  // ── TAB 1: Emitir póliza ─────────────────────────────────────────────────
  Widget _tabEmitir() {
    if (_loadingCot) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccion('1. Cotización aprobada por el agente'),
          const SizedBox(height: 8),

          if (_cotizaciones.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏳ Sin cotizaciones listas para emitir',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Para emitir una póliza necesitas:\n'
                    '1. Haber cotizado un seguro\n'
                    '2. Subir tus documentos KYC\n'
                    '3. Que un agente haya aceptado tu cotización',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _cotizacionSeleccionada,
              decoration: const InputDecoration(
                hintText: 'Selecciona cotización aceptada',
                border: OutlineInputBorder(),
              ),
              items: _cotizaciones.map((c) {
                final capital = c['capital_asegurado'] ?? '-';
                final plan = c['plan_detalle']?['nombre'] ?? 'Plan';
                final id = c['id'].toString().padLeft(5, '0');
                return DropdownMenuItem(
                  value: c,
                  child: Text('COT-$id — $plan — \$$capital'),
                );
              }).toList(),
              onChanged: (v) =>
                  setState(() => _cotizacionSeleccionada = v),
            ),

          if (_cotizacionSeleccionada != null) ...[
            const SizedBox(height: 8),
            _infoCotizacion(_cotizacionSeleccionada!),
          ],

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _seccion('2. Beneficiarios'),
              TextButton.icon(
                onPressed: _agregarBeneficiario,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),

          if (_beneficiarios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Sin beneficiarios aún.',
                  style: TextStyle(color: Colors.grey)),
            )
          else ...[
            const SizedBox(height: 8),
            ..._beneficiarios.asMap().entries.map(
                  (e) => _tarjetaBeneficiario(e.key, e.value),
                ),
            const SizedBox(height: 8),
            _totalBar(),
          ],

          const SizedBox(height: 32),
          if (_cotizaciones.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _emitiendo ? null : _emitir,
                child: _emitiendo
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Emitir póliza',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoCotizacion(Map<String, dynamic> c) {
    final expediente = c['expediente'] as Map?;
    final kycValidado = expediente?['validado_por_analista'] == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kycValidado ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                kycValidado ? Colors.green[200]! : Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              kycValidado ? Icons.check_circle : Icons.info_outline,
              color: kycValidado ? Colors.green : Colors.blue,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              kycValidado
                  ? 'Documentos KYC validados ✓'
                  : 'Documentos KYC pendientes de validación',
              style: TextStyle(
                  color: kycValidado ? Colors.green : Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Capital: \$${c['capital_asegurado'] ?? '-'} · '
            'Frecuencia: ${c['frecuencia_pago'] ?? '-'} · '
            'Plazo: ${c['plazo_anios'] ?? '-'} años',
            style: TextStyle(
                fontSize: 12,
                color: kycValidado ? Colors.green[800] : Colors.blue[800]),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Pólizas activas ───────────────────────────────────────────────
  Widget _tabPolizasActivas() {
    if (_loadingPol) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_polizasActivas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No tienes pólizas activas aún',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text(
              'Emite tu primera póliza desde la pestaña "Emitir nueva"',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarPolizas,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _polizasActivas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _tarjetaPoliza(_polizasActivas[i]),
      ),
    );
  }

  Widget _tarjetaPoliza(PolizaModel p) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(p.numeroPoliza,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: const Text('ACTIVA',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            _fila(Icons.calendar_today, 'Vigencia',
                '${p.fechaInicioVigencia} → ${p.fechaVencimiento}'),
            const SizedBox(height: 4),
            _fila(Icons.attach_money, 'Prima',
                '\$${p.primaFinalFacturada.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _fila(Icons.people, 'Beneficiarios',
                '${p.beneficiarios.length} registrado(s)'),
          ],
        ),
      ),
    );
  }

  Widget _fila(IconData icon, String label, String valor) =>
      Row(children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(child: Text(valor, style: const TextStyle(fontSize: 13))),
      ]);

  Widget _tarjetaBeneficiario(int idx, BeneficiarioModel b) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text(b.nombreCompleto),
          subtitle: Text(
              '${b.parentesco} — ${b.porcentajeAsignado.toStringAsFixed(0)}%'
              '${b.tutorLegal != null ? ' · tutor: ${b.tutorLegal!.nombreCompleto}' : ''}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón EDITAR
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                tooltip: 'Editar',
                onPressed: () => _editarBeneficiario(idx),
              ),
              // Botón ELIMINAR
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Eliminar',
                onPressed: () => setState(() => _beneficiarios.removeAt(idx)),
              ),
            ],
          ),
        ),
      );

  Widget _totalBar() {
    final total = _totalPorcentaje;
    final ok = (total - 100).abs() < 0.01;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: ok ? Colors.green[200]! : Colors.orange[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total asignado:',
              style:
                  TextStyle(color: ok ? Colors.green : Colors.orange)),
          Text('${total.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ok ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));
}