import 'package:flutter/material.dart';
import '../../models/poliza_model.dart';

class TutorLegalFormScreen extends StatefulWidget {
  const TutorLegalFormScreen({super.key});

  @override
  State<TutorLegalFormScreen> createState() => _TutorLegalFormScreenState();
}

class _TutorLegalFormScreenState extends State<TutorLegalFormScreen> {
  final _nombreCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _fechaCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _confirmar() {
    if (_nombreCtrl.text.isEmpty || _docCtrl.text.isEmpty ||
        _fechaCtrl.text.isEmpty || _telCtrl.text.isEmpty || _dirCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos del tutor son obligatorios')),
      );
      return;
    }
    final tutor = TutorLegalModel(
      nombreCompleto: _nombreCtrl.text.trim(),
      documentoIdentidad: _docCtrl.text.trim(),
      fechaNacimiento: _fechaCtrl.text,
      telefono: _telCtrl.text.trim(),
      direccion: _dirCtrl.text.trim(),
    );
    Navigator.pop(context, tutor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar tutor legal')),
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
                'El tutor legal es requerido cuando el beneficiario es menor de 18 años.',
                style: TextStyle(color: Colors.blue, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            _campo(_nombreCtrl, 'Nombre completo del tutor'),
            const SizedBox(height: 12),
            _campo(_docCtrl, 'Número de documento de identidad'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: AbsorbPointer(child: _campo(_fechaCtrl, 'Fecha de nacimiento del tutor')),
            ),
            const SizedBox(height: 12),
            _campo(_telCtrl, 'Teléfono', TextInputType.phone),
            const SizedBox(height: 12),
            TextField(
              controller: _dirCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmar,
                child: const Text('Guardar tutor legal', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, [TextInputType? tipo]) => TextField(
    controller: ctrl,
    keyboardType: tipo,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}