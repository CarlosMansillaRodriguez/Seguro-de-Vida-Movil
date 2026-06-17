import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class TenantsListaScreen extends StatefulWidget {
  const TenantsListaScreen({super.key});

  @override
  State<TenantsListaScreen> createState() => _TenantsListaScreenState();
}

class _TenantsListaScreenState extends State<TenantsListaScreen> {
  final _auth = AuthService();
  List<Map<String, dynamic>> _tenants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await http.get(
        Uri.parse('${_auth.baseUrl}/tenants/admin/lista/'),
        headers: _auth.authHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list =
            data is List ? data : (data['results'] ?? []);
        setState(() {
          _tenants =
              List<Map<String, dynamic>>.from(list);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agencias registradas'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tenants.isEmpty
              ? const Center(child: Text('Sin agencias registradas'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tenants.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _tarjeta(_tenants[i]),
                  ),
                ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> t) {
    final activo = t['suscripcion_activa'] ?? false;
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              activo ? Colors.indigo[100] : Colors.grey[200],
          child: Icon(Icons.business,
              color: activo ? Colors.indigo : Colors.grey),
        ),
        title: Text(t['nombre'] ?? '-',
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Slug: ${t['slug'] ?? '-'}',
                style: const TextStyle(fontSize: 12)),
            Text('Plan: ${t['plan'] ?? '-'}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: activo
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            activo ? 'Activa' : 'Inactiva',
            style: TextStyle(
                color: activo ? Colors.green : Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}