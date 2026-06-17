import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'gestionar_agentes_screen.dart';
import 'gestionar_clientes_screen.dart';
import 'reportes_screen.dart';
import 'bitacora_screen.dart';
import '../agente/cotizaciones_pendientes_screen.dart';
import '../agente/renovaciones_agente_screen.dart';
import '../poliza/polizas_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
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
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SegurIA', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text(
                    'Panel Administrador',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _seccion('Gestión'),
            const SizedBox(height: 10),
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
                  Icons.people_outline,
                  'Agentes',
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GestionarAgentesScreen(),
                    ),
                  ),
                ),
                _menuItem(
                  context,
                  Icons.person_outline,
                  'Clientes',
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GestionarClientesScreen(),
                    ),
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            _seccion('Operaciones'),
            const SizedBox(height: 10),
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
                  Icons.bar_chart,
                  'Reportes',
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportesScreen()),
                  ),
                ),
                _menuItem(
                  context,
                  Icons.history,
                  'Bitácora',
                  Colors.brown,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BitacoraScreen()),
                  ),
                ),
                _menuItem(
                  context,
                  Icons.payment,
                  'Pagos',
                  Colors.indigo,
                  () => Navigator.pushNamed(context, '/admin/pagos'),
                ),
                _menuItem(
                  context,
                  Icons.account_balance_wallet_outlined,
                  'Indemnizaciones',
                  Colors.teal,
                  () => Navigator.pushNamed(context, '/admin/indemnizaciones'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Text(
    titulo,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

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
}
