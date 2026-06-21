import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/cotizacion_service.dart';
import '../../services/orden_medica_service.dart';
import '../documentos/documentos_kyc_emision_screen.dart';
import '../orden_medica/orden_medica_screen.dart';

class MisDocumentosScreen extends StatefulWidget {
  const MisDocumentosScreen({super.key});

  @override
  State<MisDocumentosScreen> createState() => _MisDocumentosScreenState();
}

class _MisDocumentosScreenState extends State<MisDocumentosScreen> {
  final _cotSvc = CotizacionService(AuthService());
  final _ordSvc = OrdenMedicaService(AuthService());

  List<Map<String, dynamic>> _cotizaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final all = await _cotSvc.listarCotizaciones();
      setState(() {
        // Mostramos solo las que aún están en juego (no rechazadas/expiradas)
        _cotizaciones = all
            .where((c) => c['estado'] == 'PENDIENTE' || c['estado'] == 'ACEPTADA')
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    }
  }

  Future<void> _abrirCotizacion(Map<String, dynamic> c) async {
    final cotizacionId = c['id'] as int;

    // Verificamos si tiene orden médica asociada
    final orden = await _ordSvc.obtenerOrdenPorCotizacion(cotizacionId);

    if (!mounted) return;

    if (orden != null) {
      // Si ya tiene orden médica, mostramos opciones
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Documentos de identidad (KYC)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentosKycEmisionScreen(
                        cotizacionId: cotizacionId,
                        requiereOrdenMedica: true,
                      ),
                    ),
                  ).then((_) => _cargar());
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services_outlined),
                title: const Text('Orden médica'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdenMedicaScreen()),
                  ).then((_) => _cargar());
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } else {
      // Sin orden médica: solo KYC
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentosKycEmisionScreen(
            cotizacionId: cotizacionId,
            requiereOrdenMedica: false,
          ),
        ),
      ).then((_) => _cargar());
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ACEPTADA':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis documentos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cotizaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No tienes cotizaciones pendientes de documentos',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cotizaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = _cotizaciones[i];
                      final estado = c['estado'] ?? '';
                      final color = _colorEstado(estado);
                      final expediente = c['expediente'] as Map?;
                      final tieneKyc = expediente != null &&
                          (expediente['ci_anverso_url'] ?? '').toString().isNotEmpty;

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(
                              tieneKyc ? Icons.check_circle : Icons.upload_file,
                              color: color,
                            ),
                          ),
                          title: Text(
                              'COT-${c['id'].toString().padLeft(5, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            tieneKyc
                                ? 'Documentos enviados — ${c['estado_display'] ?? estado}'
                                : 'Pendiente de subir documentos KYC',
                            style: TextStyle(
                                fontSize: 12,
                                color: tieneKyc ? Colors.grey : Colors.orange),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _abrirCotizacion(c),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}