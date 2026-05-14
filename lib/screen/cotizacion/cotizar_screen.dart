import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/cotizacion_service.dart';
import '../../models/cotizacion_model.dart';
import 'resultado_cotizacion_screen.dart';

class CotizarScreen extends StatefulWidget {
  const CotizarScreen({super.key});

  @override
  State<CotizarScreen> createState() => _CotizarScreenState();
}

class _CotizarScreenState extends State<CotizarScreen> {
  final _auth = AuthService();
  late final CotizacionService _svc;

  List<PlanModel> _planes = [];
  PlanModel? _planSeleccionado;
  bool _loading = false;
  bool _loadingPlanes = true;

  // Cotización
  final _capitalCtrl = TextEditingController();
  final _plazoCtrl = TextEditingController();
  String _frecuencia = 'MENSUAL';

  // Salud
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  bool _diabetes = false;
  bool _hipertension = false;
  bool _cardiaca = false;
  bool _cancer = false;
  bool _respiratoria = false;
  bool _alcohol = false;
  bool _deportes = false;
  final _otrasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _svc = CotizacionService(_auth);
    _cargarPlanes();
  }

  Future<void> _cargarPlanes() async {
    try {
      final planes = await _svc.listarPlanes();
      setState(() {
        _planes = planes;
        _loadingPlanes = false;
      });
    } catch (e) {
      setState(() => _loadingPlanes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar planes: $e')),
        );
      }
    }
  }

  Future<void> _calcular() async {
    if (_planSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un plan de seguro')),
      );
      return;
    }
    if (_capitalCtrl.text.isEmpty || _plazoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa capital y plazo')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final body = {
        'plan': _planSeleccionado!.id,
        'capital_asegurado': double.parse(_capitalCtrl.text),
        'plazo_anios': int.parse(_plazoCtrl.text),
        'frecuencia_pago': _frecuencia,
        if (_pesoCtrl.text.isNotEmpty) 'peso_kg': double.parse(_pesoCtrl.text),
        if (_alturaCtrl.text.isNotEmpty) 'altura_cm': double.parse(_alturaCtrl.text),
        'tiene_diabetes': _diabetes,
        'tiene_hipertension': _hipertension,
        'tiene_enfermedad_cardiaca': _cardiaca,
        'tiene_cancer_historial': _cancer,
        'tiene_enfermedad_respiratoria': _respiratoria,
        'consume_alcohol_frecuente': _alcohol,
        'practica_deportes_riesgo': _deportes,
        'otras_enfermedades': _otrasCtrl.text,
      };

      final resultado = await _svc.calcularCotizacion(body);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultadoCotizacionScreen(resultado: resultado),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizar seguro de vida')),
      body: _loadingPlanes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seccion('Plan de seguro'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PlanModel>(
                    value: _planSeleccionado,
                    decoration: const InputDecoration(
                      hintText: 'Selecciona un plan',
                      border: OutlineInputBorder(),
                    ),
                    items: _planes.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.nombre} — ${p.tipoPlan}'),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _planSeleccionado = v;
                      _frecuencia = v?.frecuencias.first ?? 'MENSUAL';
                    }),
                  ),

                  if (_planSeleccionado != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Capital: \$${_planSeleccionado!.capitalMinimo.toStringAsFixed(0)} – \$${_planSeleccionado!.capitalMaximo.toStringAsFixed(0)} | Plazo: ${_planSeleccionado!.plazoMinAnios}–${_planSeleccionado!.plazoMaxAnios} años',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _seccion('Datos de la póliza'),
                  const SizedBox(height: 8),
                  _campo(_capitalCtrl, 'Capital asegurado (USD)', TextInputType.number),
                  const SizedBox(height: 12),
                  _campo(_plazoCtrl, 'Plazo en años', TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _frecuencia,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia de pago',
                      border: OutlineInputBorder(),
                    ),
                    items: (_planSeleccionado?.frecuencias ?? ['MENSUAL', 'TRIMESTRAL', 'SEMESTRAL', 'ANUAL'])
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => _frecuencia = v!),
                  ),

                  const SizedBox(height: 24),
                  _seccion('Cuestionario de salud'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _campo(_pesoCtrl, 'Peso (kg)', TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(_alturaCtrl, 'Altura (cm)', TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _switch('Diabetes', _diabetes, (v) => setState(() => _diabetes = v)),
                  _switch('Hipertensión', _hipertension, (v) => setState(() => _hipertension = v)),
                  _switch('Enfermedad cardíaca', _cardiaca, (v) => setState(() => _cardiaca = v)),
                  _switch('Historial de cáncer', _cancer, (v) => setState(() => _cancer = v)),
                  _switch('Enfermedad respiratoria', _respiratoria, (v) => setState(() => _respiratoria = v)),
                  _switch('Consumo frecuente de alcohol', _alcohol, (v) => setState(() => _alcohol = v)),
                  _switch('Deportes de riesgo', _deportes, (v) => setState(() => _deportes = v)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otrasCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Otras enfermedades (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _calcular,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Calcular cotización', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _seccion(String titulo) => Text(
    titulo,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  Widget _campo(TextEditingController ctrl, String label, TextInputType tipo) =>
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      );
}