/*import 'package:flutter/material.dart';
import '../../models/poliza_model.dart';
import 'tutor_legal_form_screen.dart';

/// Formulario para registrar UN beneficiario con opción de agregar tutor legal.
class BeneficiariosFormScreen extends StatefulWidget {
  const BeneficiariosFormScreen({super.key});

  @override
  State<BeneficiariosFormScreen> createState() => _BeneficiariosFormScreenState();
}

class _BeneficiariosFormScreenState extends State<BeneficiariosFormScreen> {
  final _nombreCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _parentescoCtrl = TextEditingController();
  final _porcentajeCtrl = TextEditingController();
  TutorLegalModel? _tutor;
  bool _esMenor = false;

  final List<String> _parentescos = [
    'Cónyuge', 'Hijo/a', 'Padre', 'Madre', 'Hermano/a', 'Otro'
  ];
  String? _parentescoSel;

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final s = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _fechaCtrl.text = s;
      // Detectar menor de edad
      final edad = DateTime.now().difference(picked).inDays ~/ 365;
      setState(() => _esMenor = edad < 18);
    }
  }

  Future<void> _agregarTutor() async {
    final tutor = await Navigator.push<TutorLegalModel>(
      context,
      MaterialPageRoute(builder: (_) => const TutorLegalFormScreen()),
    );
    if (tutor != null) setState(() => _tutor = tutor);
  }

  void _confirmar() {
    if (_nombreCtrl.text.isEmpty || _fechaCtrl.text.isEmpty ||
        _parentescoSel == null || _porcentajeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios')),
      );
      return;
    }
    if (_esMenor && _tutor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El beneficiario es menor de edad: registra un tutor legal')),
      );
      return;
    }

    final beneficiario = BeneficiarioModel(
      nombreCompleto: _nombreCtrl.text.trim(),
      documentoIdentidad: _docCtrl.text.trim().isEmpty ? null : _docCtrl.text.trim(),
      fechaNacimiento: _fechaCtrl.text,
      parentesco: _parentescoSel!,
      porcentajeAsignado: double.parse(_porcentajeCtrl.text),
      tutorLegal: _tutor,
    );
    Navigator.pop(context, beneficiario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar beneficiario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campo(_nombreCtrl, 'Nombre completo *'),
            const SizedBox(height: 12),
            _campo(_docCtrl, 'Número de documento (opcional)'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: AbsorbPointer(
                child: _campo(_fechaCtrl, 'Fecha de nacimiento *'),
              ),
            ),

            if (_esMenor)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  const Text('Menor de edad — se requiere tutor legal', style: TextStyle(color: Colors.orange, fontSize: 13)),
                ]),
              ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _parentescoSel,
              decoration: const InputDecoration(
                labelText: 'Parentesco *',
                border: OutlineInputBorder(),
              ),
              items: _parentescos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _parentescoSel = v),
            ),
            const SizedBox(height: 12),
            _campo(_porcentajeCtrl, 'Porcentaje asignado % *', TextInputType.number),

            if (_esMenor) ...[
              const SizedBox(height: 24),
              const Text('Tutor legal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              if (_tutor == null)
                OutlinedButton.icon(
                  onPressed: _agregarTutor,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrar tutor legal'),
                )
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text(_tutor!.nombreCompleto),
                    subtitle: Text('CI: ${_tutor!.documentoIdentidad}'),
                    trailing: TextButton(
                      onPressed: _agregarTutor,
                      child: const Text('Cambiar'),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmar,
                child: const Text('Agregar beneficiario', style: TextStyle(fontSize: 16)),
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
}*/
import 'package:flutter/material.dart';
import '../../models/poliza_model.dart';
import 'tutor_legal_form_screen.dart';

/// Formulario para registrar o EDITAR un beneficiario.
class BeneficiariosFormScreen extends StatefulWidget {
  /// Si se pasa, el formulario se pre-llena para edición.
  final BeneficiarioModel? inicial;

  const BeneficiariosFormScreen({super.key, this.inicial});

  @override
  State<BeneficiariosFormScreen> createState() =>
      _BeneficiariosFormScreenState();
}

class _BeneficiariosFormScreenState
    extends State<BeneficiariosFormScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _docCtrl;
  late final TextEditingController _fechaCtrl;
  late final TextEditingController _porcentajeCtrl;
  TutorLegalModel? _tutor;
  bool _esMenor = false;

  final List<String> _parentescos = [
    'Cónyuge', 'Hijo/a', 'Padre', 'Madre', 'Hermano/a', 'Otro'
  ];
  String? _parentescoSel;

  @override
  void initState() {
    super.initState();
    final ini = widget.inicial;
    _nombreCtrl =
        TextEditingController(text: ini?.nombreCompleto ?? '');
    _docCtrl =
        TextEditingController(text: ini?.documentoIdentidad ?? '');
    _fechaCtrl =
        TextEditingController(text: ini?.fechaNacimiento ?? '');
    _porcentajeCtrl = TextEditingController(
        text: ini != null
            ? ini.porcentajeAsignado.toStringAsFixed(0)
            : '');
    _parentescoSel = ini?.parentesco;
    _tutor = ini?.tutorLegal;

    // Detectar si es menor a partir de la fecha pre-cargada
    if (ini?.fechaNacimiento != null) {
      try {
        final fecha = DateTime.parse(ini!.fechaNacimiento);
        final edad = DateTime.now().difference(fecha).inDays ~/ 365;
        _esMenor = edad < 18;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _docCtrl.dispose();
    _fechaCtrl.dispose();
    _porcentajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final s =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _fechaCtrl.text = s;
      final edad = DateTime.now().difference(picked).inDays ~/ 365;
      setState(() => _esMenor = edad < 18);
    }
  }

  Future<void> _agregarTutor() async {
    final tutor = await Navigator.push<TutorLegalModel>(
      context,
      MaterialPageRoute(builder: (_) => const TutorLegalFormScreen()),
    );
    if (tutor != null) setState(() => _tutor = tutor);
  }

  void _confirmar() {
    if (_nombreCtrl.text.isEmpty ||
        _fechaCtrl.text.isEmpty ||
        _parentescoSel == null ||
        _porcentajeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Completa todos los campos obligatorios')),
      );
      return;
    }
    if (_esMenor && _tutor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'El beneficiario es menor de edad: registra un tutor legal')),
      );
      return;
    }

    final pct = double.tryParse(_porcentajeCtrl.text);
    if (pct == null || pct <= 0 || pct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('El porcentaje debe estar entre 1 y 100')),
      );
      return;
    }

    final beneficiario = BeneficiarioModel(
      id: widget.inicial?.id,
      nombreCompleto: _nombreCtrl.text.trim(),
      documentoIdentidad: _docCtrl.text.trim().isEmpty
          ? null
          : _docCtrl.text.trim(),
      fechaNacimiento: _fechaCtrl.text,
      parentesco: _parentescoSel!,
      porcentajeAsignado: pct,
      tutorLegal: _tutor,
    );
    Navigator.pop(context, beneficiario);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.inicial != null;

    return Scaffold(
      appBar: AppBar(
          title: Text(
              esEdicion ? 'Editar beneficiario' : 'Agregar beneficiario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campo(_nombreCtrl, 'Nombre completo *'),
            const SizedBox(height: 12),
            _campo(_docCtrl, 'Número de documento (opcional)'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: AbsorbPointer(
                child: _campo(_fechaCtrl, 'Fecha de nacimiento *'),
              ),
            ),

            if (_esMenor)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  const Text(
                      'Menor de edad — se requiere tutor legal',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 13)),
                ]),
              ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _parentescoSel,
              decoration: const InputDecoration(
                labelText: 'Parentesco *',
                border: OutlineInputBorder(),
              ),
              items: _parentescos
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _parentescoSel = v),
            ),
            const SizedBox(height: 12),
            _campo(_porcentajeCtrl, 'Porcentaje asignado % *',
                TextInputType.number),

            if (_esMenor) ...[
              const SizedBox(height: 24),
              const Text('Tutor legal',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              if (_tutor == null)
                OutlinedButton.icon(
                  onPressed: _agregarTutor,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrar tutor legal'),
                )
              else
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.person, color: Colors.blue),
                    title: Text(_tutor!.nombreCompleto),
                    subtitle:
                        Text('CI: ${_tutor!.documentoIdentidad}'),
                    trailing: TextButton(
                      onPressed: _agregarTutor,
                      child: const Text('Cambiar'),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmar,
                child: Text(
                    esEdicion
                        ? 'Guardar cambios'
                        : 'Agregar beneficiario',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label,
          [TextInputType? tipo]) =>
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}