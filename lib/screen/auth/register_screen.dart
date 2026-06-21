/*import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: const Center(
        child: Text('Pantalla de registro (pendiente)'),
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  List<Map<String, dynamic>> _tenants = [];
  Map<String, dynamic>? _tenantSeleccionado;
  bool _loadingTenants = true;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _cargarTenants();
  }

  Future<void> _cargarTenants() async {
    try {
      final res = await http.get(Uri.parse('${_auth.baseUrl}/tenants/publico/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _tenants = List<Map<String, dynamic>>.from(data);
          _loadingTenants = false;
        });
      } else {
        setState(() => _loadingTenants = false);
      }
    } catch (_) {
      setState(() => _loadingTenants = false);
    }
  }

  Future<void> _registrar() async {
    if (_tenantSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la empresa de seguros')),
      );
      return;
    }
    if (_nombreCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty ||
        _ciCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios')),
      );
      return;
    }

    setState(() => _registrando = true);
    try {
      final res = await http.post(
        Uri.parse('${_auth.baseUrl}/registro/'),
        headers: {
          'Content-Type': 'application/json',
          'X-Tenant-Slug': _tenantSeleccionado!['slug'],
        },
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'username': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
          'first_name': _nombreCtrl.text.trim(),
          'last_name': _apellidoCtrl.text.trim(),
          'ci': _ciCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 201) {
        // Login automático tras registrarse
        final loginOk = await _auth.login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
        if (!mounted) return;

        if (loginOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso! Ya puedes cotizar.')),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${err.toString()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Empresa de seguros *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _loadingTenants
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Map<String, dynamic>>(
                    value: _tenantSeleccionado,
                    decoration: const InputDecoration(
                      hintText: 'Selecciona una empresa',
                      border: OutlineInputBorder(),
                    ),
                    items: _tenants
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t['nombre'] ?? '-'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _tenantSeleccionado = v),
                  ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoCtrl,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ciCtrl,
              decoration: const InputDecoration(
                labelText: 'Cédula de identidad *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _registrando ? null : _registrar,
                child: _registrando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrarme', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}