import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/documento_service.dart';
import '../../models/documento_model.dart';

/// Pantalla para subir y gestionar el expediente de documentos KYC.
/// El cliente pega las URLs de los archivos ya subidos a Cloudinary/S3.
class DocumentosScreen extends StatefulWidget {
  final int cotizacionId;
  const DocumentosScreen({super.key, required this.cotizacionId});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  final _svc = DocumentoService(AuthService());
  ExpedienteModel? _expediente;
  bool _loading = true;
  bool _guardando = false;

  final _anversoCtrl = TextEditingController();
  final _reversoCtrl = TextEditingController();
  final _domicilioCtrl = TextEditingController();
  final _saludCtrl = TextEditingController();
  final _ingresosCtrl = TextEditingController();
  final _contratoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarExpediente();
  }

  Future<void> _cargarExpediente() async {
    try {
      final exp = await _svc.obtenerExpedientePorCotizacion(widget.cotizacionId);
      setState(() {
        _expediente = exp;
        if (exp != null) {
          _anversoCtrl.text = exp.ciAnversoUrl;
          _reversoCtrl.text = exp.ciReversoUrl;
          _domicilioCtrl.text = exp.domicilioUrl;
          _saludCtrl.text = exp.saludFirmadaUrl ?? '';
          _ingresosCtrl.text = exp.respaldoIngresosUrl ?? '';
          _contratoCtrl.text = exp.contratoFirmadoUrl ?? '';
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    if (_anversoCtrl.text.isEmpty || _reversoCtrl.text.isEmpty || _domicilioCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los documentos de identidad y domicilio son obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      if (_expediente == null) {
        final nuevo = ExpedienteModel(
          cotizacionId: widget.cotizacionId,
          ciAnversoUrl: _anversoCtrl.text.trim(),
          ciReversoUrl: _reversoCtrl.text.trim(),
          domicilioUrl: _domicilioCtrl.text.trim(),
          saludFirmadaUrl: _saludCtrl.text.trim().isEmpty ? null : _saludCtrl.text.trim(),
          respaldoIngresosUrl: _ingresosCtrl.text.trim().isEmpty ? null : _ingresosCtrl.text.trim(),
          contratoFirmadoUrl: _contratoCtrl.text.trim().isEmpty ? null : _contratoCtrl.text.trim(),
        );
        _expediente = await _svc.crearExpediente(nuevo);
      } else {
        final campos = {
          'ci_anverso_url': _anversoCtrl.text.trim(),
          'ci_reverso_url': _reversoCtrl.text.trim(),
          'domicilio_url': _domicilioCtrl.text.trim(),
          if (_saludCtrl.text.trim().isNotEmpty) 'salud_firmada_url': _saludCtrl.text.trim(),
          if (_ingresosCtrl.text.trim().isNotEmpty) 'respaldo_ingresos_url': _ingresosCtrl.text.trim(),
          if (_contratoCtrl.text.trim().isNotEmpty) 'contrato_firmado_url': _contratoCtrl.text.trim(),
        };
        _expediente = await _svc.actualizarExpediente(_expediente!.id!, campos);
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documentos guardados. Un analista los revisará pronto.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documentos KYC')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner de estado
                  if (_expediente != null)
                    _bannerEstado(_expediente!),

                  const SizedBox(height: 16),
                  _info('Pega las URLs públicas de tus documentos subidos a la nube (Cloudinary, Drive, etc.)'),

                  const SizedBox(height: 20),
                  _seccion('Identificación (obligatorio)'),
                  const SizedBox(height: 8),
                  _campoUrl(_anversoCtrl, 'URL Carnet de Identidad — Anverso', Icons.badge),
                  const SizedBox(height: 12),
                  _campoUrl(_reversoCtrl, 'URL Carnet de Identidad — Reverso', Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _campoUrl(_domicilioCtrl, 'URL Comprobante de domicilio', Icons.home),

                  const SizedBox(height: 24),
                  _seccion('Documentos adicionales (opcional)'),
                  const SizedBox(height: 8),
                  _campoUrl(_saludCtrl, 'URL Declaración de salud firmada', Icons.health_and_safety),
                  const SizedBox(height: 12),
                  _campoUrl(_ingresosCtrl, 'URL Respaldo de ingresos', Icons.attach_money),
                  const SizedBox(height: 12),
                  _campoUrl(_contratoCtrl, 'URL Contrato firmado', Icons.description),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_guardando || _expediente?.validadoPorAnalista == true) ? null : _guardar,
                      child: _guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _expediente?.validadoPorAnalista == true
                                  ? 'Documentos validados ✓'
                                  : _expediente != null ? 'Actualizar documentos' : 'Subir documentos',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _bannerEstado(ExpedienteModel exp) {
    if (exp.validadoPorAnalista) {
      return _banner(
        '✓ Documentos validados',
        'Un analista revisó y aprobó tus documentos.',
        Colors.green,
      );
    }
    if (exp.observacionesAnalista != null && exp.observacionesAnalista!.isNotEmpty) {
      return _banner(
        '⚠ Documentos rechazados',
        'Motivo: ${exp.observacionesAnalista}',
        Colors.orange,
      );
    }
    return _banner(
      '⏳ Pendiente de revisión',
      'Un analista revisará tus documentos próximamente.',
      Colors.blue,
    );
  }

  Widget _banner(String titulo, String desc, Color color) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(desc, style: TextStyle(color: color.withOpacity(0.8), fontSize: 13)),
      ],
    ),
  );

  Widget _seccion(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));

  Widget _info(String t) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, color: Colors.blue, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(t, style: const TextStyle(color: Colors.blue, fontSize: 13))),
    ]),
  );

  Widget _campoUrl(TextEditingController ctrl, String label, IconData icon) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    keyboardType: TextInputType.url,
  );
}