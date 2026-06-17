import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'cotizaciones_pendientes_screen.dart';
import 'renovaciones_agente_screen.dart';
import '../poliza/polizas_screen.dart';

class AgenteDashboardScreen extends StatelessWidget {
  const AgenteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Agente'),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.teal, Colors.tealAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SegurIA', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text(
                    'Panel de Agente',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _menuItem(
                    context,
                    Icons.assignment_outlined,
                    'Cotizaciones',
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CotizacionesPendientesScreen(),
                      ),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.shield_outlined,
                    'Pólizas',
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PolizasScreen()),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.autorenew,
                    'Renovaciones',
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RenovacionesAgenteScreen(),
                      ),
                    ),
                  ),
                  _menuItem(
                    context,
                    Icons.people_outline,
                    'Mis Clientes',
                    Colors.orange,
                    () => _verClientes(context),
                  ),
                  _menuItem(
                    context,
                    Icons.warning_amber_outlined,
                    'Siniestros',
                    Colors.orange,
                    () => Navigator.pushNamed(context, '/agente/siniestros'),
                  ),
                  _menuItem(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Indemnizaciones',
                    Colors.teal,
                    () =>
                        Navigator.pushNamed(context, '/agente/indemnizaciones'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verClientes(BuildContext context) {
    Navigator.pushNamed(context, '/admin/clientes');
  }
}
