import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  final _svc = AdminService(AuthService());
  List<Map<String, dynamic>> _registros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarBitacora();
      setState(() {
        _registros = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  IconData _iconAccion(String accion) {
    switch (accion) {
      case 'LOGIN': return Icons.login;
      case 'LOGOUT': return Icons.logout;
      case 'CREAR': return Icons.add_circle_outline;
      case 'EDITAR': return Icons.edit_outlined;
      case 'ELIMINAR': return Icons.delete_outline;
      default: return Icons.info_outline;
    }
  }

  Color _colorAccion(String accion) {
    switch (accion) {
      case 'LOGIN': return Colors.green;
      case 'LOGOUT': return Colors.orange;
      case 'CREAR': return Colors.blue;
      case 'EDITAR': return Colors.purple;
      case 'ELIMINAR': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora de auditoría'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? const Center(child: Text('Sin registros'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _registros.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _tarjeta(_registros[i]),
                  ),
                ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> r) {
    final accion = r['accion'] ?? '';
    final color = _colorAccion(accion);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(_iconAccion(accion), color: color, size: 20),
        ),
        title: Text(r['detalle'] ?? '',
            style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          '${r['usuario_email'] ?? 'Sistema'} · ${r['modulo'] ?? ''} · ${r['fecha'] ?? ''}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(accion,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}