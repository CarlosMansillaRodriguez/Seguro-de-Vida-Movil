import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/documento_service.dart';
import '../../models/documento_model.dart';
import '../orden_medica/orden_medica_screen.dart';

/// Pantalla de KYC que aparece JUSTO DESPUÉS de que el cliente acepta
/// su cotización. Aquí sube sus documentos. Si también requiere orden
/// médica, se le informa y se le redirige al finalizar.
class DocumentosKycEmisionScreen extends StatefulWidget {
  final int cotizacionId;
  final bool requiereOrdenMedica;

  const DocumentosKycEmisionScreen({
    super.key,
    required this.cotizacionId,
    this.requiereOrdenMedica = false,
  });

  @override
  State<DocumentosKycEmisionScreen> createState() =>
      _DocumentosKycEmisionScreenState();
}

class _DocumentosKycEmisionScreenState
    extends State<DocumentosKycEmisionScreen> {
  final _svc = DocumentoService(AuthService());
  final _cloudinary = CloudinaryPublic(
    'dsxlwoyxt',
    'smart_rescue',
    cache: false,
  );

  ExpedienteModel? _expediente;
  bool _loading = true;
  bool _guardando = false;

  String? _anversoUrl;
  String? _reversoUrl;
  String? _domicilioUrl;
  String? _saludUrl;
  String? _ingresosUrl;

  @override
  void initState() {
    super.initState();
    _cargarExpediente();
  }

  Future<void> _cargarExpediente() async {
    try {
      final exp = await _svc
          .obtenerExpedientePorCotizacion(widget.cotizacionId);
      setState(() {
        _expediente = exp;
        if (exp != null) {
          _anversoUrl = exp.ciAnversoUrl;
          _reversoUrl = exp.ciReversoUrl;
          _domicilioUrl = exp.domicilioUrl;
          _saludUrl = exp.saludFirmadaUrl;
          _ingresosUrl = exp.respaldoIngresosUrl;
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<String?> _seleccionarYSubir(
      String nombre, ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return null;

    setState(() => _guardando = true);
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          picked.path,
          folder: 'kyc_seguria',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir $nombre: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _capturarDocumento(
      String nombre, Function(String url) onSubido) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(context);
                final url = await _seleccionarYSubir(
                    nombre, ImageSource.camera);
                if (url != null) onSubido(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () async {
                Navigator.pop(context);
                final url = await _seleccionarYSubir(
                    nombre, ImageSource.gallery);
                if (url != null) onSubido(url);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_anversoUrl == null ||
        _reversoUrl == null ||
        _domicilioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Los 3 documentos obligatorios deben estar subidos')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      if (_expediente == null) {
        _expediente = await _svc.crearExpediente(ExpedienteModel(
          cotizacionId: widget.cotizacionId,
          ciAnversoUrl: _anversoUrl!,
          ciReversoUrl: _reversoUrl!,
          domicilioUrl: _domicilioUrl!,
          saludFirmadaUrl: _saludUrl,
          respaldoIngresosUrl: _ingresosUrl,
        ));
      } else {
        _expediente = await _svc.actualizarExpediente(
          _expediente!.id!,
          {
            'ci_anverso_url': _anversoUrl!,
            'ci_reverso_url': _reversoUrl!,
            'domicilio_url': _domicilioUrl!,
            if (_saludUrl != null) 'salud_firmada_url': _saludUrl,
            if (_ingresosUrl != null)
              'respaldo_ingresos_url': _ingresosUrl,
          },
        );
      }

      if (!mounted) return;
      setState(() {});

      // Mostrar qué sigue
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Documentos enviados'),
          content: Text(
            widget.requiereOrdenMedica
                ? 'Tus documentos fueron enviados.\n\n'
                    'Adicionalmente, tu capital asegurado requiere una orden médica. '
                    'Deberás subir los resultados de los exámenes indicados.\n\n'
                    'Un agente revisará todo antes de emitir tu póliza.'
                : 'Tus documentos fueron enviados correctamente.\n\n'
                    'Un agente los revisará y aprobará o rechazará tu solicitud. '
                    'Te notificaremos el resultado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // cierra dialog
                if (widget.requiereOrdenMedica) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrdenMedicaScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context)
                      .popUntil((r) => r.isFirst);
                }
              },
              child: Text(widget.requiereOrdenMedica
                  ? 'Ver mi orden médica'
                  : 'Ir al inicio'),
            ),
          ],
        ),
      );
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
    final bloqueado = _expediente?.validadoPorAnalista == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sube tus documentos'),
        automaticallyImplyLeading: false, // no puede volver atrás aquí
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.requiereOrdenMedica)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.medical_services_outlined,
                              color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tu capital asegurado requiere examen médico. '
                              'Después de subir estos documentos podrás ver tu orden médica.',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_expediente != null) ...[
                    const SizedBox(height: 12),
                    _bannerEstado(_expediente!),
                  ],

                  const SizedBox(height: 16),
                  _info(
                    'Sube fotos claras de tu Carnet de Identidad (anverso y reverso) '
                    'y un comprobante de domicilio reciente (factura de agua, luz o teléfono).',
                  ),
                  const SizedBox(height: 20),

                  _seccion('Documentos obligatorios'),
                  const SizedBox(height: 12),
                  _itemDocumento(
                    label: 'CI — Anverso (frente)',
                    icono: Icons.badge,
                    urlSubida: _anversoUrl,
                    obligatorio: true,
                    bloqueado: bloqueado,
                    onTap: () => _capturarDocumento('CI Anverso',
                        (url) => setState(() => _anversoUrl = url)),
                  ),
                  const SizedBox(height: 10),
                  _itemDocumento(
                    label: 'CI — Reverso (dorso)',
                    icono: Icons.badge_outlined,
                    urlSubida: _reversoUrl,
                    obligatorio: true,
                    bloqueado: bloqueado,
                    onTap: () => _capturarDocumento('CI Reverso',
                        (url) => setState(() => _reversoUrl = url)),
                  ),
                  const SizedBox(height: 10),
                  _itemDocumento(
                    label: 'Comprobante de domicilio',
                    icono: Icons.home_outlined,
                    urlSubida: _domicilioUrl,
                    obligatorio: true,
                    bloqueado: bloqueado,
                    onTap: () => _capturarDocumento(
                        'Comprobante de domicilio',
                        (url) =>
                            setState(() => _domicilioUrl = url)),
                  ),

                  const SizedBox(height: 20),
                  _seccion('Opcionales'),
                  const SizedBox(height: 12),
                  _itemDocumento(
                    label: 'Declaración de salud firmada',
                    icono: Icons.health_and_safety_outlined,
                    urlSubida: _saludUrl,
                    obligatorio: false,
                    bloqueado: bloqueado,
                    onTap: () => _capturarDocumento(
                        'Declaración de salud',
                        (url) => setState(() => _saludUrl = url)),
                  ),
                  const SizedBox(height: 10),
                  _itemDocumento(
                    label: 'Respaldo de ingresos',
                    icono: Icons.receipt_long_outlined,
                    urlSubida: _ingresosUrl,
                    obligatorio: false,
                    bloqueado: bloqueado,
                    onTap: () => _capturarDocumento(
                        'Respaldo de ingresos',
                        (url) => setState(() => _ingresosUrl = url)),
                  ),

                  const SizedBox(height: 32),

                  if (!bloqueado)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        child: _guardando
                            ? const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white)),
                                  SizedBox(width: 12),
                                  Text('Subiendo documentos...'),
                                ],
                              )
                            : const Text('Enviar documentos',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _itemDocumento({
    required String label,
    required IconData icono,
    required String? urlSubida,
    required bool obligatorio,
    required bool bloqueado,
    required VoidCallback onTap,
  }) {
    final subido = urlSubida != null && urlSubida.isNotEmpty;
    return InkWell(
      onTap: bloqueado ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: subido
              ? Colors.green.withOpacity(0.06)
              : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: subido
                ? Colors.green.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: subido
                  ? Colors.green.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              subido ? Icons.check_circle : icono,
              color: subido ? Colors.green : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (obligatorio)
                    const Text(' *',
                        style: TextStyle(
                            color: Colors.red, fontSize: 14)),
                ]),
                const SizedBox(height: 2),
                Text(
                  subido
                      ? 'Subido correctamente ✓'
                      : bloqueado
                          ? 'Validado por analista'
                          : 'Toca para subir',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        subido ? Colors.green : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (!bloqueado)
            Icon(
              subido ? Icons.edit_outlined : Icons.upload_outlined,
              color: Colors.grey[400],
              size: 20,
            ),
        ]),
      ),
    );
  }

  Widget _bannerEstado(ExpedienteModel exp) {
    if (exp.validadoPorAnalista) {
      return _banner('✓ Documentos validados por el analista',
          'El agente revisó y aprobó tus documentos.', Colors.green);
    }
    if (exp.observacionesAnalista != null &&
        exp.observacionesAnalista!.isNotEmpty) {
      return _banner(
          '⚠ Documentos rechazados',
          'Motivo: ${exp.observacionesAnalista}\nSube nuevamente los documentos corregidos.',
          Colors.orange);
    }
    return _banner('⏳ Pendiente de revisión',
        'El agente revisará tus documentos en breve.', Colors.blue);
  }

  Widget _banner(String titulo, String desc, Color color) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(desc,
                style: TextStyle(
                    color: color.withOpacity(0.8), fontSize: 13)),
          ],
        ),
      );

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 15));

  Widget _info(String t) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t,
                  style: const TextStyle(
                      color: Colors.blue, fontSize: 13)),
            ),
          ],
        ),
      );
}