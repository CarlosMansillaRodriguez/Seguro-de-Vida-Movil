import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/siniestro_service.dart';
import '../../services/poliza_service.dart';
import '../../models/poliza_model.dart';

class ReportarSiniestroScreen extends StatefulWidget {
  const ReportarSiniestroScreen({super.key});

  @override
  State<ReportarSiniestroScreen> createState() =>
      _ReportarSiniestroScreenState();
}

class _ReportarSiniestroScreenState
    extends State<ReportarSiniestroScreen> {
  final _svc = SiniestroService(AuthService());
  final _polSvc = PolizaService(AuthService());

  List<PolizaModel> _polizas = [];
  PolizaModel? _polizaSel;
  String _tipo = 'FALLECIMIENTO';
  final _fechaCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = true;
  bool _enviando = false;

  final List<Map<String, String>> _tipos = [
    {'value': 'FALLECIMIENTO', 'label': 'Fallecimiento'},
    {'value': 'INVALIDEZ_TOTAL', 'label': 'Invalidez Total'},
    {'value': 'INVALIDEZ_PARCIAL', 'label': 'Invalidez Parcial'},
    {'value': 'ENFERMEDAD_CRITICA', 'label': 'Enfermedad Crítica'},
    {'value': 'OTRO', 'label': 'Otro'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarPolizas();
  }

  Future<void> _cargarPolizas() async {
    try {
      final all = await _polSvc.listarPolizas();
      setState(() {
        _polizas = all
            .where((p) =>
                p.estado == 'ACTIVA' || p.estado == 'SUSPENDIDA')
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _fechaCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _enviar() async {
    if (_polizaSel == null ||
        _fechaCtrl.text.isEmpty ||
        _descCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Completa todos los campos. La descripción debe tener al menos 20 caracteres.')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await _svc.reportarSiniestro(
        polizaId: _polizaSel!.id,
        tipoSiniestro: _tipo,
        fechaEvento: _fechaCtrl.text,
        descripcion: _descCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Siniestro reportado. Un agente lo revisará.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar siniestro')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reporta un evento que activa la cobertura de tu póliza. '
                      'Un agente revisará tu caso y te contactará.',
                      style:
                          TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Póliza *',
                      style: TextStyle(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  if (_polizas.isEmpty)
                    const Text(
                        'No tienes pólizas activas para reportar un siniestro.',
                        style: TextStyle(color: Colors.grey))
                  else
                    DropdownButtonFormField<PolizaModel>(
                      value: _polizaSel,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Selecciona tu póliza'),
                      items: _polizas
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.numeroPoliza),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _polizaSel = v),
                    ),

                  const SizedBox(height: 16),
                  const Text('Tipo de siniestro *',
                      style: TextStyle(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: _tipos
                        .map((t) => DropdownMenuItem(
                              value: t['value'],
                              child: Text(t['label']!),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _tipo = v ?? 'FALLECIMIENTO'),
                  ),

                  const SizedBox(height: 16),
                  const Text('Fecha del evento *',
                      style: TextStyle(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _fechaCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Toca para seleccionar fecha',
                          border: OutlineInputBorder(),
                          suffixIcon:
                              Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Descripción del evento *',
                      style: TextStyle(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe detalladamente lo ocurrido (mínimo 20 caracteres)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviar,
                      child: _enviando
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Enviar reporte',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}