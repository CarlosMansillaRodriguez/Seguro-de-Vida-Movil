import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/siniestro_service.dart';
import '../../models/siniestro_model.dart';
import 'reportar_siniestro_screen.dart';

class SiniestrosScreen extends StatefulWidget {
  final bool soloMios;
  const SiniestrosScreen({super.key, this.soloMios = true});

  @override
  State<SiniestrosScreen> createState() => _SiniestrosScreenState();
}

class _SiniestrosScreenState extends State<SiniestrosScreen> {
  final _auth = AuthService();
  late final _svc = SiniestroService(_auth);

  List<SiniestroModel> _siniestros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarSiniestros();
      setState(() {
        _siniestros = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _revisar(SiniestroModel s) async {
    String estadoSel = 'EN_REVISION';
    final obsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Revisar siniestro #${s.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: estadoSel,
                decoration: const InputDecoration(
                    labelText: 'Nuevo estado',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'EN_REVISION',
                      child: Text('En revisión')),
                  DropdownMenuItem(
                      value: 'APROBADO', child: Text('Aprobado')),
                  DropdownMenuItem(
                      value: 'RECHAZADO', child: Text('Rechazado')),
                ],
                onChanged: (v) =>
                    setSt(() => estadoSel = v ?? 'EN_REVISION'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _svc.revisarSiniestro(
                    siniestroId: s.id,
                    estado: estadoSel,
                    observaciones: obsCtrl.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Siniestro actualizado')),
                    );
                    _cargar();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(String e) {
    switch (e) {
      case 'REPORTADO':
        return Colors.orange;
      case 'EN_REVISION':
        return Colors.blue;
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCliente = _auth.esCliente;

    return Scaffold(
      appBar: AppBar(
        title: Text(esCliente ? 'Mis siniestros' : 'Siniestros'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _siniestros.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No hay siniestros registrados',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _siniestros.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _tarjeta(_siniestros[i]),
                  ),
                ),
      floatingActionButton: esCliente
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const ReportarSiniestroScreen()),
              ).then((_) => _cargar()),
              icon: const Icon(Icons.add),
              label: const Text('Reportar'),
            )
          : null,
    );
  }

  Widget _tarjeta(SiniestroModel s) {
    final color = _colorEstado(s.estado);
    final esStaff = _auth.esStaff;

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
                Text('Siniestro #${s.id}',
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
                  child: Text(s.estadoDisplay,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Póliza: ${s.polizaNumero}',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
            Text('Tipo: ${s.tipoDisplay}',
                style: const TextStyle(fontSize: 13)),
            Text('Fecha evento: ${s.fechaEvento}',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
            if (s.observacionesAgente != null &&
                s.observacionesAgente!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Agente: ${s.observacionesAgente}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.orange)),
            ],
            if (esStaff &&
                s.estado != 'APROBADO' &&
                s.estado != 'RECHAZADO') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _revisar(s),
                  child: const Text('Revisar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}