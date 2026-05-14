import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';

class GestionarClientesScreen extends StatefulWidget {
  const GestionarClientesScreen({super.key});

  @override
  State<GestionarClientesScreen> createState() =>
      _GestionarClientesScreenState();
}

class _GestionarClientesScreenState extends State<GestionarClientesScreen> {
  final _svc = AdminService(AuthService());
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarClientes();
      setState(() {
        _clientes = data;
        _filtrados = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _clientes.where((c) {
        final nombre = (c['nombre_completo'] ?? '').toLowerCase();
        final email = (c['email'] ?? '').toLowerCase();
        return nombre.contains(q) || email.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Clientes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? const Center(child: Text('Sin clientes'))
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _tarjeta(_filtrados[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> c) {
    final activo = c['is_active'] ?? true;
    final id = c['id'];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activo ? Colors.teal[100] : Colors.grey[200],
          child: Icon(Icons.person,
              color: activo ? Colors.teal : Colors.grey),
        ),
        title: Text(c['nombre_completo'] ?? c['email'] ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c['email'] ?? '', style: const TextStyle(fontSize: 12)),
            if (c['telefono'] != null)
              Text(c['telefono'], style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: c['telefono'] != null,
        trailing: Switch(
          value: activo,
          onChanged: (val) async {
            try {
              await _svc.toggleClienteActivo(id, val);
              _cargar();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
        ),
      ),
    );
  }
}