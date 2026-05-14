import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() async {
    final svc = NotificationService();

    // App estaba cerrada y se abrió por notificación
    final initial = await svc.getInitialMessage();
    if (initial != null && mounted) {
      _navigateFromMessage(initial);
    }

    // App estaba en background y el usuario tocó la notificación
    svc.onMessageOpenedApp.listen((message) {
      if (mounted) _navigateFromMessage(message);
    });
  }

  void _navigateFromMessage(RemoteMessage message) {
    final tipo = message.data['tipo'] as String?;
    switch (tipo) {
      case 'poliza':
        Navigator.pushNamed(context, '/polizas');
        break;
      case 'renovacion':
        Navigator.pushNamed(context, '/renovaciones');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Seguro"),
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
      /*body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tarjeta principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SegurIA', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  Text(
                    'Gestión de Seguros',
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

            // Accesos rápidos
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _menuItem(
                    context,
                    Icons.calculate_outlined,
                    'Cotizar',
                    '/cotizar',
                    Colors.blue,
                  ),
                  _menuItem(
                    context,
                    Icons.shield_outlined,
                    'Mis Pólizas',
                    '/polizas',
                    Colors.green,
                  ),
                  _menuItem(
                    context,
                    Icons.folder_outlined,
                    'Documentos',
                    null,
                    Colors.orange,
                    onTap: () => _irDocumentos(context),
                  ),
                  _menuItem(
                    context,
                    Icons.autorenew,
                    'Renovaciones',
                    '/renovaciones',
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),*/
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SegurIA', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  Text(
                    'Gestión de Seguros',
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
                    Icons.calculate_outlined,
                    'Cotizar',
                    '/cotizar',
                    Colors.blue,
                  ),
                  _menuItem(
                    context,
                    Icons.shield_outlined,
                    'Mis Pólizas',
                    '/polizas',
                    Colors.green,
                  ),
                  _menuItem(
                    context,
                    Icons.folder_outlined,
                    'Documentos KYC',
                    null,
                    Colors.orange,
                    onTap: () => _irDocumentos(context),
                  ),
                  _menuItem(
                    context,
                    Icons.autorenew,
                    'Renovaciones',
                    '/renovaciones',
                    Colors.purple,
                  ),
                  _menuItem(
                    context,
                    Icons.medical_services_outlined,
                    'Orden médica',
                    '/orden-medica',
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*Widget _card(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    String? route,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          (route != null ? () => Navigator.pushNamed(context, route) : null),
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

  void _irDocumentos(BuildContext context) {
    // Aquí necesitas el cotizacion_id. En producción lo obtienes de
    // la cotización aceptada del usuario. Por ahora muestra un diálogo.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Documentos KYC'),
        content: const Text(
          'Selecciona una cotización aceptada para subir sus documentos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }*/
  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    String? route,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          (route != null ? () => Navigator.pushNamed(context, route) : null),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _irDocumentos(BuildContext context) {
    // Para el cliente, primero buscamos su cotización aceptada más reciente
    // y navegamos con ese ID. Por ahora abrimos un diálogo de selección.
    // En una implementación completa, consultarías el servicio de cotizaciones
    // y tomarías el ID de la primera cotización ACEPTADA.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Documentos KYC'),
        content: const Text(
          'Ve a "Mis Pólizas", selecciona la cotización aceptada '
          'y desde allí podrás subir tus documentos de identidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/polizas');
            },
            child: const Text('Ir a mis pólizas'),
          ),
        ],
      ),
    );
  }
}
