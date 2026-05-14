import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../models/agente_model.dart';

class GestionarAgentesScreen extends StatefulWidget {
  const GestionarAgentesScreen({super.key});

  @override
  State<GestionarAgentesScreen> createState() =>
      _GestionarAgentesScreenState();
}

class _GestionarAgentesScreenState extends State<GestionarAgentesScreen> {
  final _svc = AdminService(AuthService());
  List<AgenteModel> _agentes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _svc.listarAgentes();
      setState(() {
        _agentes = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _crearAgente() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final licenciaCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo agente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(emailCtrl, 'Email *'),
              const SizedBox(height: 10),
              _campo(passCtrl, 'Contraseña *', obscure: true),
              const SizedBox(height: 10),
              _campo(nombreCtrl, 'Nombre *'),
              const SizedBox(height: 10),
              _campo(apellidoCtrl, 'Apellido *'),
              const SizedBox(height: 10),
              _campo(licenciaCtrl, 'Código de licencia'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
              Navigator.pop(context);
              try {
                await _svc.crearAgente({
                  'email': emailCtrl.text.trim(),
                  'username': emailCtrl.text.trim(),
                  'password': passCtrl.text,
                  'first_name': nombreCtrl.text.trim(),
                  'last_name': apellidoCtrl.text.trim(),
                  if (licenciaCtrl.text.isNotEmpty)
                    'codigo_licencia': licenciaCtrl.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agente creado exitosamente')),
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
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Agentes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _agentes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay agentes registrados'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _crearAgente,
                        child: const Text('Crear primer agente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _agentes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _tarjeta(_agentes[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearAgente,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo agente'),
      ),
    );
  }

  Widget _tarjeta(AgenteModel a) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              a.isActive ? Colors.indigo[100] : Colors.grey[200],
          child: Icon(Icons.person,
              color: a.isActive ? Colors.indigo : Colors.grey),
        ),
        title: Text(a.nombreCompleto.isNotEmpty ? a.nombreCompleto : a.email,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(a.email, style: const TextStyle(fontSize: 12)),
        trailing: Switch(
          value: a.isActive,
          onChanged: (val) async {
            try {
              await _svc.toggleAgenteActivo(a.id, val);
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

  Widget _campo(TextEditingController ctrl, String label,
          {bool obscure = false}) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}