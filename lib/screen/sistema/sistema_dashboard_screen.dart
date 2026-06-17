import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'tenants_lista_screen.dart';
import '../admin/reportes_screen.dart';

class SistemaDashboardScreen extends StatelessWidget {
  const SistemaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SegurIA — Sistema',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 8),
                  Text(
                    'Administrador Global',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestión de todas las agencias del sistema',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Gestión Global',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _menuItem(
                  context,
                  Icons.business,
                  'Agencias',
                  Colors.indigo,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const TenantsListaScreen())),
                ),
                _menuItem(
                  context,
                  Icons.bar_chart,
                  'Reportes\nGlobales',
                  Colors.orange,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ReportesScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}