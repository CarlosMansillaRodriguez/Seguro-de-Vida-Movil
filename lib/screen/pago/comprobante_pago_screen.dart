import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/pago_service.dart';

class ComprobantePagoScreen extends StatefulWidget {
  final int pagoId;
  const ComprobantePagoScreen({super.key, required this.pagoId});

  @override
  State<ComprobantePagoScreen> createState() => _ComprobantePagoScreenState();
}

class _ComprobantePagoScreenState extends State<ComprobantePagoScreen> {
  final _svc = PagoService(AuthService());
  bool _descargando = false;

  Future<void> _descargarYAbrir() async {
    setState(() => _descargando = true);
    try {
      final bytes = await _svc.descargarComprobantePdf(widget.pagoId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/comprobante_${widget.pagoId}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir comprobante: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago confirmado')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              '¡Pago registrado con éxito!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu póliza ha sido activada. Puedes descargar tu comprobante en PDF.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _descargando ? null : _descargarYAbrir,
                icon: const Icon(Icons.picture_as_pdf),
                label: _descargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ver comprobante PDF'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Ir al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}