import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/poliza_service.dart';
import '../../models/poliza_model.dart';
import 'emitir_poliza_screen.dart';
import 'valor_rescate_screen.dart';

class PolizasScreen extends StatefulWidget {
  const PolizasScreen({super.key});

  @override
  State<PolizasScreen> createState() => _PolizasScreenState();
}

class _PolizasScreenState extends State<PolizasScreen> {
  final _svc = PolizaService(AuthService());
  List<PolizaModel> _polizas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /*Future<void> _cargar() async {
    try {
      final polizas = await _svc.listarPolizas();
      setState(() {
        _polizas = polizas;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }*/
  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final polizas = await _svc.listarPolizas();
      setState(() {
        _polizas = polizas;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pólizas: $e'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'ACTIVA': return Colors.green;
      case 'SUSPENDIDA': return Colors.orange;
      case 'VENCIDA': return Colors.red;
      case 'RENOVADA': return Colors.blue;
      case 'CANCELADA': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pólizas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
          : _polizas.isEmpty
              ? _vacio()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _polizas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _tarjetaPoliza(_polizas[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmitirPolizaScreen()),
        ).then((_) => _cargar()),
        icon: const Icon(Icons.add),
        label: const Text('Emitir póliza'),
      ),
    );
  }

  Widget _tarjetaPoliza(PolizaModel p) {
    final color = _colorEstado(p.estado);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.numeroPoliza,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    p.estadoDisplay,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _fila(Icons.calendar_today, 'Vigencia', '${p.fechaInicioVigencia} → ${p.fechaVencimiento}'),
            const SizedBox(height: 6),
            _fila(Icons.attach_money, 'Prima', '\$${p.primaFinalFacturada.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            //_fila(Icons.people, 'Beneficiarios', '${p.beneficiarios.length} registrado(s)'),
            /*SP4*/
            _fila(Icons.people, 'Beneficiarios',
                '${p.beneficiarios.length} registrado(s)'),
            if (p.estado == 'ACTIVA') ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ValorRescateScreen(
                        polizaId: p.id,
                        numeroPoliza: p.numeroPoliza,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.savings_outlined, size: 16),
                  label: const Text('Ver valor de rescate',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
            /*SP4*/
          ],
        ),
      ),
    );
  }

  Widget _fila(IconData icon, String label, String valor) => Row(children: [
    Icon(icon, size: 16, color: Colors.grey),
    const SizedBox(width: 6),
    Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
    Expanded(child: Text(valor, style: const TextStyle(fontSize: 13))),
  ]);

  Widget _vacio() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('No tienes pólizas aún', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmitirPolizaScreen()),
          ).then((_) => _cargar()),
          child: const Text('Emitir primera póliza'),
        ),
      ],
    ),
  );
}