import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/pago_service.dart';

class RegistrarPagoManualScreen extends StatefulWidget {
  const RegistrarPagoManualScreen({super.key});

  @override
  State<RegistrarPagoManualScreen> createState() =>
      _RegistrarPagoManualScreenState();
}

class _RegistrarPagoManualScreenState
    extends State<RegistrarPagoManualScreen> {
  final _svc = PagoService(AuthService());
  final _polizaCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  String _metodo = 'EFECTIVO';
  bool _guardando = false;

  Future<void> _guardar() async {
    if (_polizaCtrl.text.trim().isEmpty ||
        _montoCtrl.text.trim().isEmpty ||
        _comprobanteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    final monto = double.tryParse(_montoCtrl.text.trim());
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser un número mayor a 0')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await _svc.registrarPagoManual(
        numeroPoliza: _polizaCtrl.text.trim(),
        monto: monto,
        metodoPago: _metodo,
        nroComprobante: _comprobanteCtrl.text.trim(),
        observaciones: _obsCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado. La póliza fue activada.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago manual')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Usa esta pantalla para registrar pagos en efectivo o '
                'transferencia bancaria realizados en oficina.',
                style: TextStyle(color: Colors.blue, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _polizaCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de póliza *',
                hintText: 'Ej: POL-12-ABCDEF',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto pagado *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _metodo,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                DropdownMenuItem(
                    value: 'TRANSFERENCIA', child: Text('Transferencia bancaria')),
              ],
              onChanged: (v) => setState(() => _metodo = v ?? 'EFECTIVO'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _comprobanteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nro. de comprobante / recibo *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrar pago', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}