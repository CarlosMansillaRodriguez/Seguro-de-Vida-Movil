import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _svc = AdminService(AuthService());
  final _vozCtrl = TextEditingController();

  String _modeloSeleccionado = 'polizas_de_seguro.poliza';
  bool _cargando = false;
  bool _cargandoVoz = false;
  List<dynamic> _datos = [];
  String? _urlGenerada;
  int _total = 0;

  final List<Map<String, String>> _modelos = [
    {'key': 'polizas_de_seguro.poliza', 'label': 'Pólizas'},
    {'key': 'cotizaciones.cotizacion', 'label': 'Cotizaciones'},
    {'key': 'usuarios.usuario', 'label': 'Usuarios'},
    {'key': 'ordenes_medicas.ordenmedica', 'label': 'Órdenes Médicas'},
    {'key': 'planes_de_seguro.plandeseguro', 'label': 'Planes de Seguro'},
  ];

  Future<void> _generarReporte() async {
    setState(() {
      _cargando = true;
      _datos = [];
    });
    try {
      final res = await _svc.obtenerReporte(modelo: _modeloSeleccionado);
      setState(() {
        _datos = res['data'] ?? [];
        _total = res['total'] ?? 0;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reportePorVoz() async {
    final texto = _vozCtrl.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _cargandoVoz = true;
      _urlGenerada = null;
      _datos = [];
    });

    try {
      final res = await _svc.reportePorVoz(texto);
      final url = res['url_generada'] as String?;
      setState(() {
        _urlGenerada = url;
        _cargandoVoz = false;
      });

      // Ejecutar el reporte generado por IA
      if (url != null) {
        final params = Uri.parse('http://x$url').queryParameters;
        final modelo = params['modelo'] ?? _modeloSeleccionado;
        final filtros = Map<String, String>.from(params)..remove('modelo');
        final data = await _svc.obtenerReporte(
          modelo: modelo,
          filtros: filtros,
        );
        setState(() {
          _datos = data['data'] ?? [];
          _total = data['total'] ?? 0;
          _modeloSeleccionado = modelo;
        });
      }
    } catch (e) {
      setState(() => _cargandoVoz = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes Dinámicos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Reporte por voz ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mic, color: Colors.deepPurple, size: 20),
                      SizedBox(width: 8),
                      Text('Reporte por comando de voz / texto',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _vozCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          'Ej: "muéstrame las pólizas activas" o "cotizaciones pendientes"',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargandoVoz ? null : _reportePorVoz,
                      icon: _cargandoVoz
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search),
                      label: Text(
                          _cargandoVoz ? 'Procesando IA...' : 'Generar reporte'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white),
                    ),
                  ),
                  if (_urlGenerada != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'URL generada: $_urlGenerada',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Reporte manual ───────────────────────────────
            const Text('Reporte manual',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _modeloSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Selecciona el módulo',
                border: OutlineInputBorder(),
              ),
              items: _modelos
                  .map((m) => DropdownMenuItem(
                      value: m['key'], child: Text(m['label']!)))
                  .toList(),
              onChanged: (v) => setState(() => _modeloSeleccionado = v!),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _generarReporte,
                icon: _cargando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bar_chart),
                label: Text(_cargando ? 'Cargando...' : 'Generar reporte'),
              ),
            ),

            // ── Resultados ───────────────────────────────────
            if (_datos.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Resultados ($_total registros)',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              ..._datos.take(50).map((item) => _tarjetaDato(item)).toList(),
              if (_total > 50)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Mostrando 50 de $_total registros',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tarjetaDato(dynamic item) {
    if (item is! Map) return const SizedBox();
    final entries = item.entries.take(5).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.key}: ',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Expanded(
                          child: Text(
                            '${e.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}