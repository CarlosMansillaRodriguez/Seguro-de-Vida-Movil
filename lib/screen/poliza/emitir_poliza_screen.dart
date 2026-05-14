import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/poliza_service.dart';
import '../../services/cotizacion_service.dart';
import '../../models/poliza_model.dart';
import '../beneficiario/beneficiarios_form_screen.dart';

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
      final aceptadas = all.where((c) => c['estado'] == 'ACEPTADA').toList();
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
      MaterialPageRoute(builder: (_) => const BeneficiariosFormScreen()),
    );
    if (result != null) {
      setState(() => _beneficiarios.add(result));
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
    if (_totalPorcentaje != 100) {
      _snack('Los porcentajes deben sumar 100%. Actual: ${_totalPorcentaje.toStringAsFixed(0)}%');
      return;
    }

    setState(() => _emitiendo = true);
    try {
      final poliza = await _polSvc.emitirPoliza(
        cotizacionId: _cotizacionSeleccionada!['id'],
        beneficiarios: _beneficiarios,
      );
      if (mounted) {
        _dialogExito(poliza);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _emitiendo = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );

  void _dialogExito(PolizaModel p) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('¡Póliza emitida!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text('Número: ${p.numeroPoliza}'),
          Text('Prima: \$${p.primaFinalFacturada.toStringAsFixed(2)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ver mis pólizas'),
        ),
      ],
    ),
  );

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
                    const Text(
                      'No tienes cotizaciones aceptadas. Acepta una cotización primero.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _cotizacionSeleccionada,
                      decoration: const InputDecoration(
                        hintText: 'Selecciona cotización',
                        border: OutlineInputBorder(),
                      ),
                      items: _cotizaciones.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('COT-${c['id'].toString().padLeft(5, '0')} — \$${c['capital_asegurado']}'),
                      )).toList(),
                      onChanged: (v) => setState(() => _cotizacionSeleccionada = v),
                    ),

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
                      child: Text('Sin beneficiarios aún.', style: TextStyle(color: Colors.grey)),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    ..._beneficiarios.asMap().entries.map((e) =>
                      _tarjetaBeneficiario(e.key, e.value),
                    ),
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Emitir póliza', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _tarjetaBeneficiario(int idx, BeneficiarioModel b) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const Icon(Icons.person),
      title: Text(b.nombreCompleto),
      subtitle: Text('${b.parentesco} — ${b.porcentajeAsignado.toStringAsFixed(0)}%'
          '${b.tutorLegal != null ? ' (tutor: ${b.tutorLegal!.nombreCompleto})' : ''}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => setState(() => _beneficiarios.removeAt(idx)),
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
        border: Border.all(color: ok ? Colors.green[200]! : Colors.orange[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total asignado:', style: TextStyle(color: ok ? Colors.green : Colors.orange)),
          Text(
            '${total.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ok ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));
}