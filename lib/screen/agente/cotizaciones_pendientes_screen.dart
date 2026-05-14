import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';

class CotizacionesPendientesScreen extends StatefulWidget {
  const CotizacionesPendientesScreen({super.key});

  @override
  State<CotizacionesPendientesScreen> createState() =>
      _CotizacionesPendientesScreenState();
}

class _CotizacionesPendientesScreenState
    extends State<CotizacionesPendientesScreen> {
  final _svc = AdminService(AuthService());
  List<Map<String, dynamic>> _cotizaciones = [];
  bool _loading = true;
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarCotizaciones();
      setState(() {
        _cotizaciones = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    if (_filtro == 'TODOS') return _cotizaciones;
    return _cotizaciones
        .where((c) => c['estado'] == _filtro)
        .toList();
  }

  Future<void> _aceptar(int id) async {
    try {
      await _svc.aceptarCotizacion(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización aceptada')),
      );
      _cargar();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE': return Colors.orange;
      case 'ACEPTADA': return Colors.green;
      case 'RECHAZADA': return Colors.red;
      case 'EXPIRADA': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['TODOS', 'PENDIENTE', 'ACEPTADA', 'RECHAZADA']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: _filtro == f,
                          onSelected: (_) => setState(() => _filtro = f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                    ? const Center(child: Text('Sin cotizaciones'))
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtradas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _tarjeta(_filtradas[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> c) {
    final estado = c['estado'] ?? '';
    final color = _colorEstado(estado);
    final id = c['id'];
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
                Text('COT-${id.toString().padLeft(5, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(estado,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${c['cliente_nombre'] ?? c['cliente_email'] ?? '-'}',
                style: const TextStyle(fontSize: 13)),
            Text('Capital: \$${c['capital_asegurado'] ?? '-'}',
                style: const TextStyle(fontSize: 13)),
            Text('Riesgo: ${c['nivel_riesgo'] ?? '-'}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _aceptar(id),
                  child: const Text('Aceptar cotización'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}