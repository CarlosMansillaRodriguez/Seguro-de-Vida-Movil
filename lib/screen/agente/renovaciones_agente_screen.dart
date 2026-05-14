import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';

class RenovacionesAgenteScreen extends StatefulWidget {
  const RenovacionesAgenteScreen({super.key});

  @override
  State<RenovacionesAgenteScreen> createState() =>
      _RenovacionesAgenteScreenState();
}

class _RenovacionesAgenteScreenState extends State<RenovacionesAgenteScreen> {
  final _svc = AdminService(AuthService());
  List<Map<String, dynamic>> _renovaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarRenovaciones();
      setState(() {
        _renovaciones = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _aprobar(int id) async {
    final obsCtrl = TextEditingController();
    double ajuste = 0;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Aprobar renovación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Ajuste prima: '),
                  Expanded(
                    child: Slider(
                      value: ajuste,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: '${ajuste.toStringAsFixed(0)}%',
                      onChanged: (v) => setSt(() => ajuste = v),
                    ),
                  ),
                  Text('${ajuste.toStringAsFixed(0)}%'),
                ],
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
                  await _svc.aprobarRenovacion(id,
                      obs: obsCtrl.text, ajuste: ajuste);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Renovación aprobada')),
                    );
                    _cargar();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rechazar(int id) async {
    final motivoCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar renovación'),
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (motivoCtrl.text.trim().length < 5) return;
              Navigator.pop(context);
              try {
                await _svc.rechazarRenovacion(id, motivoCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Renovación rechazada')),
                  );
                  _cargar();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
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

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'APROBADA': return Colors.green;
      case 'RECHAZADA': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renovaciones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _renovaciones.isEmpty
              ? const Center(child: Text('Sin renovaciones pendientes'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _renovaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _tarjeta(_renovaciones[i]),
                  ),
                ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> r) {
    final estado = r['estado'] ?? '';
    final color = _colorEstado(estado);
    final id = r['id'];
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
                Text('Póliza: ${r['poliza_original_numero'] ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(r['estado_display'] ?? estado,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Motivo: ${r['motivo_solicitud'] ?? '-'}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rechazar(id),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _aprobar(id),
                      child: const Text('Aprobar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}