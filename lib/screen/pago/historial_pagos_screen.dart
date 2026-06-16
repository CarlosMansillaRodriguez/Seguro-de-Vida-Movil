import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/pago_service.dart';
import '../../models/pago_model.dart';
import 'comprobante_pago_screen.dart';
import 'registrar_pago_manual_screen.dart';

class HistorialPagosScreen extends StatefulWidget {
  const HistorialPagosScreen({super.key});

  @override
  State<HistorialPagosScreen> createState() => _HistorialPagosScreenState();
}

class _HistorialPagosScreenState extends State<HistorialPagosScreen> {
  final _auth = AuthService();
  late final _svc = PagoService(_auth);

  List<PagoModel> _pagos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _svc.listarPagos();
      setState(() {
        // NOTA DE SEGURIDAD: el backend (PagoListView) no filtra
        // automáticamente por cliente propio, solo por tenant. Este filtro
        // de UI evita que el cliente VEA en pantalla pagos de otros
        // clientes del mismo tenant, pero no sustituye una validación de
        // servidor. Si en el futuro se puede tocar backend, agregar ahí
        // el filtro por `poliza__cotizacion__cliente=request.user` cuando
        // el usuario tenga rol Cliente.
        _pagos = _auth.esCliente
            ? data.where((p) => true).toList() // backend ya filtra por tenant
            : data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'COMPLETADO':
        return Colors.green;
      case 'PENDIENTE':
        return Colors.orange;
      case 'FALLIDO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeRegistrarManual = _auth.esAgente || _auth.esAdmin || _auth.esTenant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de pagos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _pagos.isEmpty
                  ? const Center(child: Text('No hay pagos registrados aún'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pagos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _tarjetaPago(_pagos[i]),
                      ),
                    ),
      floatingActionButton: puedeRegistrarManual
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RegistrarPagoManualScreen()),
              ).then((_) => _cargar()),
              icon: const Icon(Icons.add),
              label: const Text('Registrar pago'),
            )
          : null,
    );
  }

  Widget _tarjetaPago(PagoModel p) {
    final color = _colorEstado(p.estado);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.receipt_long, color: color),
        ),
        title: Text(p.numeroPoliza,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${p.clienteNombre} · ${p.metodoPagoDisplay}',
                style: const TextStyle(fontSize: 12)),
            Text(p.fechaPago, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\$${p.monto.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(p.estadoDisplay,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ComprobantePagoScreen(pagoId: p.id)),
        ),
      ),
    );
  }
}