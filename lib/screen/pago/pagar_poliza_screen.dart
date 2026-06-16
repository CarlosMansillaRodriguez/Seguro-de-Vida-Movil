import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/pago_service.dart';
import '../../models/poliza_model.dart';
import 'comprobante_pago_screen.dart';

class PagarPolizaScreen extends StatefulWidget {
  final PolizaModel poliza;
  const PagarPolizaScreen({super.key, required this.poliza});

  @override
  State<PagarPolizaScreen> createState() => _PagarPolizaScreenState();
}

class _PagarPolizaScreenState extends State<PagarPolizaScreen> {
  final _svc = PagoService(AuthService());
  bool _procesando = false;
  String? _sessionIdPendiente;

  Future<void> _pagarConStripe() async {
    setState(() => _procesando = true);
    try {
      final sesion = await _svc.crearCheckoutSession(widget.poliza.id);
      _sessionIdPendiente = sesion['session_id'];

      final uri = Uri.parse(sesion['url']!);
      final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto && mounted) {
        _mostrarError('No se pudo abrir el navegador para pagar.');
        return;
      }

      if (mounted) _mostrarDialogoConfirmacion();
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¿Completaste el pago?'),
        content: const Text(
          'Si ya completaste el pago en el navegador, confirma aquí para '
          'activar tu póliza. Si cancelaste o no llegaste a pagar, presiona "Aún no".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aún no'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmarPagoStripe();
            },
            child: const Text('Sí, ya pagué'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarPagoStripe() async {
    if (_sessionIdPendiente == null) {
      _mostrarError(
        'No se pudo identificar la sesión de pago. Intenta nuevamente desde "Pagar con Stripe".',
      );
      return;
    }
    setState(() => _procesando = true);
    try {
      final pago = await _svc.confirmarPagoStripe(
        stripeSessionId: _sessionIdPendiente!,
        polizaId: widget.poliza.id,
      );
      if (mounted) _irAComprobante(pago.id);
    } catch (e) {
      _mostrarError('$e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _simular() async {
    setState(() => _procesando = true);
    try {
      final pago = await _svc.simularPago(widget.poliza.id);
      if (mounted) _irAComprobante(pago.id);
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _irAComprobante(int pagoId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ComprobantePagoScreen(pagoId: pagoId)),
    );
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red[700]));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.poliza;
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar póliza')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.numeroPoliza,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Prima a pagar', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    '\$${p.primaFinalFacturada.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Selecciona un método de pago',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _pagarConStripe,
                icon: const Icon(Icons.credit_card),
                label: _procesando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Pagar con Stripe (tarjeta)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _procesando ? null : _simular,
                icon: const Icon(Icons.bolt),
                label: const Text('Simular pago (demo)'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'El pago se procesa de forma segura. Tu póliza se activará '
              'automáticamente apenas el backend confirme el pago con Stripe.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}