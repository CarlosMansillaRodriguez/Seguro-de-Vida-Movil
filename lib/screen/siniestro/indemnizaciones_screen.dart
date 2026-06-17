import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/siniestro_service.dart';
import '../../models/siniestro_model.dart';

class IndemnizacionesScreen extends StatefulWidget {
  const IndemnizacionesScreen({super.key});

  @override
  State<IndemnizacionesScreen> createState() =>
      _IndemnizacionesScreenState();
}

class _IndemnizacionesScreenState
    extends State<IndemnizacionesScreen> {
  final _svc = SiniestroService(AuthService());
  List<IndemnizacionModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarIndemnizaciones();
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _aprobar(IndemnizacionModel ind) async {
    final montoCtrl = TextEditingController(
        text: ind.capitalAsegurado.toStringAsFixed(2));
    final obsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Aprobar indemnización #${ind.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monto aprobado *',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final monto =
                  double.tryParse(montoCtrl.text.trim()) ?? 0;
              if (monto <= 0) return;
              Navigator.pop(context);
              try {
                await _svc.aprobarIndemnizacion(
                  indemnizacionId: ind.id,
                  monto: monto,
                  observaciones: obsCtrl.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Indemnización aprobada')),
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
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  Future<void> _rechazar(IndemnizacionModel ind) async {
    final obsCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Rechazar indemnización #${ind.id}'),
        content: TextField(
          controller: obsCtrl,
          decoration: const InputDecoration(
              labelText: 'Motivo del rechazo *',
              border: OutlineInputBorder()),
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
              if (obsCtrl.text.trim().length < 5) return;
              Navigator.pop(context);
              try {
                await _svc.rechazarIndemnizacion(
                  indemnizacionId: ind.id,
                  observaciones: obsCtrl.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Indemnización rechazada')),
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
            child: const Text('Rechazar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _colorEstado(String e) {
    switch (e) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'APROBADA':
        return Colors.blue;
      case 'PAGADA':
        return Colors.green;
      case 'RECHAZADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indemnizaciones'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('Sin indemnizaciones registradas'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _tarjeta(_items[i]),
                  ),
                ),
    );
  }

  Widget _tarjeta(IndemnizacionModel ind) {
    final color = _colorEstado(ind.estado);
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
                Text('Indemnización #${ind.id}',
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
                  child: Text(ind.estadoDisplay,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Póliza: ${ind.polizaNumero}',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
            Text('Tipo: ${ind.siniestroTipo}',
                style: const TextStyle(fontSize: 13)),
            if (ind.montoAprobado != null)
              Text(
                  'Monto: \$${ind.montoAprobado!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            if (ind.estado == 'PENDIENTE') ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rechazar(ind),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _aprobar(ind),
                    child: const Text('Aprobar'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}