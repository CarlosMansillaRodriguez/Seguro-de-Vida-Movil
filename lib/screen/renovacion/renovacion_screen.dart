import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/poliza_service.dart';
import '../../models/poliza_model.dart';
import '../../models/renovacion_model.dart';

class RenovacionScreen extends StatefulWidget {
  const RenovacionScreen({super.key});

  @override
  State<RenovacionScreen> createState() => _RenovacionScreenState();
}

class _RenovacionScreenState extends State<RenovacionScreen>
    with SingleTickerProviderStateMixin {
  final _svc = PolizaService(AuthService());
  late TabController _tabs;

  List<PolizaModel> _polizas = [];
  List<RenovacionModel> _renovaciones = [];
  bool _loadingPolizas = true;
  bool _loadingRenovaciones = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _cargarPolizas();
    _cargarRenovaciones();
  }

  Future<void> _cargarPolizas() async {
    try {
      final all = await _svc.listarPolizas();
      setState(() {
        _polizas = all.where((p) => p.estado == 'ACTIVA' || p.estado == 'VENCIDA').toList();
        _loadingPolizas = false;
      });
    } catch (_) {
      setState(() => _loadingPolizas = false);
    }
  }

  Future<void> _cargarRenovaciones() async {
    try {
      final r = await _svc.listarRenovaciones();
      setState(() {
        _renovaciones = r;
        _loadingRenovaciones = false;
      });
    } catch (_) {
      setState(() => _loadingRenovaciones = false);
    }
  }

  Future<void> _solicitarRenovacion(PolizaModel poliza) async {
    final motivoCtrl = TextEditingController();
    int plazo = 1;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Renovar póliza ${poliza.numeroPoliza}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo de renovación *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Nuevo plazo: '),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: plazo > 1 ? () => setSt(() => plazo--) : null,
                  ),
                  Text('$plazo año(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: plazo < 30 ? () => setSt(() => plazo++) : null,
                  ),
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
                if (motivoCtrl.text.trim().length < 10) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('El motivo debe tener al menos 10 caracteres')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _enviarSolicitud(poliza.id, motivoCtrl.text.trim(), plazo);
              },
              child: const Text('Solicitar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarSolicitud(int polizaId, String motivo, int plazo) async {
    try {
      await _svc.solicitarRenovacion(
        polizaId: polizaId,
        motivo: motivo,
        nuevoPlazoAnios: plazo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud de renovación enviada. Un analista la revisará pronto.')),
        );
        await _cargarRenovaciones();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renovaciones'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Solicitar'),
            Tab(text: 'Mis solicitudes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _tabSolicitar(),
          _tabHistorial(),
        ],
      ),
    );
  }

  Widget _tabSolicitar() {
    if (_loadingPolizas) return const Center(child: CircularProgressIndicator());
    if (_polizas.isEmpty) return const Center(
      child: Text('No tienes pólizas activas o vencidas para renovar.', style: TextStyle(color: Colors.grey)),
    );
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _polizas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = _polizas[i];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              Icons.shield,
              color: p.estado == 'ACTIVA' ? Colors.green : Colors.orange,
            ),
            title: Text(p.numeroPoliza, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Vence: ${p.fechaVencimiento} — ${p.estadoDisplay}'),
            trailing: ElevatedButton(
              onPressed: () => _solicitarRenovacion(p),
              child: const Text('Renovar'),
            ),
          ),
        );
      },
    );
  }

  Widget _tabHistorial() {
    if (_loadingRenovaciones) return const Center(child: CircularProgressIndicator());
    if (_renovaciones.isEmpty) return const Center(
      child: Text('Sin solicitudes de renovación.', style: TextStyle(color: Colors.grey)),
    );
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _renovaciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = _renovaciones[i];
        return _tarjetaRenovacion(r);
      },
    );
  }

  Widget _tarjetaRenovacion(RenovacionModel r) {
    Color color;
    IconData icon;
    switch (r.estado) {
      case 'APROBADA':
        color = Colors.green; icon = Icons.check_circle;
        break;
      case 'RECHAZADA':
        color = Colors.red; icon = Icons.cancel;
        break;
      default:
        color = Colors.blue; icon = Icons.pending;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(r.estadoDisplay, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text('Póliza: ${r.polizaOriginalNumero}', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Motivo: ${r.motivoSolicitud}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (r.polizaNuevaNumero != null)
              Text('Nueva póliza: ${r.polizaNuevaNumero}', style: const TextStyle(fontSize: 13, color: Colors.green)),
            if (r.observacionesAnalista != null && r.observacionesAnalista!.isNotEmpty)
              Text('Analista: ${r.observacionesAnalista}', style: const TextStyle(fontSize: 13, color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}