import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/orden_medica_service.dart';
import '../../models/orden_medica_model.dart';

class OrdenMedicaScreen extends StatefulWidget {
  const OrdenMedicaScreen({super.key});

  @override
  State<OrdenMedicaScreen> createState() => _OrdenMedicaScreenState();
}

class _OrdenMedicaScreenState extends State<OrdenMedicaScreen> {
  final _svc = OrdenMedicaService(AuthService());
  List<OrdenMedicaModel> _ordenes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final ordenes = await _svc.listarMisOrdenes();
      setState(() {
        _ordenes = ordenes;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar órdenes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis órdenes médicas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ordenes.isEmpty
              ? _sinOrdenes()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ordenes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _tarjetaOrden(_ordenes[i]),
                  ),
                ),
    );
  }

  Widget _tarjetaOrden(OrdenMedicaModel orden) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera: estado + fecha límite ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chipEstado(orden.estado),
                if (orden.fechaLimite != null)
                  Text(
                    'Límite: ${orden.fechaLimite}',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Progreso de exámenes ──────────────────────────────────
            _progresoExamenes(orden),
            const SizedBox(height: 16),

            // ── Lista de exámenes requeridos ──────────────────────────
            const Text('Exámenes requeridos',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ...orden.examenesRequeridos.asMap().entries.map((e) {
              final idx = e.key;
              final examen = e.value;
              // Verificamos si ya hay resultado cargado para este examen
              final cargado = idx < orden.resultados.length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Icon(
                    cargado
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: cargado ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(examen,
                        style: TextStyle(
                            fontSize: 13,
                            color: cargado
                                ? Colors.grey
                                : Colors.black87,
                            decoration: cargado
                                ? TextDecoration.lineThrough
                                : null)),
                  ),
                ]),
              );
            }),

            // ── Dictamen (si ya fue emitido) ──────────────────────────
            if (orden.dictamen != null) ...[
              const Divider(height: 24),
              _dictamenWidget(orden.dictamen!),
            ],

            // ── Notas adicionales ─────────────────────────────────────
            if (orden.notasAdicionales != null &&
                orden.notasAdicionales!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        orden.notasAdicionales!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Botón subir resultado (solo si no está completada) ────
            if (orden.estado != 'COMPLETADA' &&
                orden.estado != 'CANCELADA') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _subirResultado(context, orden),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Subir resultado de examen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progresoExamenes(OrdenMedicaModel orden) {
    final total = orden.examenesRequeridos.length;
    final cargados = orden.resultados.length.clamp(0, total);
    final porcentaje = total > 0 ? cargados / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Resultados entregados',
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 13)),
            Text('$cargados / $total',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentaje,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              porcentaje == 1.0 ? Colors.green : Colors.blue,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _dictamenWidget(DictamenMedicoModel dictamen) {
    Color color;
    IconData icon;
    switch (dictamen.conclusion) {
      case 'APTO':
        color = Colors.green;
        icon = Icons.verified;
        break;
      case 'APTO_RESERVA':
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      default:
        color = Colors.red;
        icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              'Dictamen: ${dictamen.conclusionDisplay}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ]),
          if (dictamen.impactoPrimaPct > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Recargo sobre la prima: +${dictamen.impactoPrimaPct.toStringAsFixed(0)}%',
              style:
                  TextStyle(color: color.withOpacity(0.8), fontSize: 13),
            ),
          ],
          if (dictamen.observaciones.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dictamen.observaciones,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipEstado(String estado) {
    Color color;
    switch (estado) {
      case 'PENDIENTE':
        color = Colors.orange;
        break;
      case 'EN_PROCESO':
        color = Colors.blue;
        break;
      case 'COMPLETADA':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        estado.replaceAll('_', ' '),
        style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sinOrdenes() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.medical_services_outlined,
            size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        const Text('No tienes órdenes médicas',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          'Las órdenes médicas se generan cuando tu capital asegurado\nsupera el umbral del plan seleccionado.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    ),
  );

  // ── Subir resultado con imagen del dispositivo ──────────────────────
  Future<void> _subirResultado(
      BuildContext context, OrdenMedicaModel orden) async {
    // Buscamos los exámenes que aún no tienen resultado
    final pendientes = orden.examenesRequeridos
        .skip(orden.resultados.length)
        .toList();

    if (pendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Todos los exámenes ya fueron entregados.')),
      );
      return;
    }

    // Selección del examen a entregar
    String? examenSeleccionado = pendientes.first;
    File? archivoSeleccionado;
    final resultadoCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subir resultado de examen',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 16),

              // Selector de examen pendiente
              DropdownButtonFormField<String>(
                value: examenSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Examen *',
                  border: OutlineInputBorder(),
                ),
                items: pendientes
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) =>
                    setSt(() => examenSeleccionado = v),
              ),
              const SizedBox(height: 12),

              // Observaciones del resultado
              TextField(
                controller: resultadoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones del resultado *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Adjuntar imagen/PDF
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                      source: ImageSource.gallery);
                  if (picked != null) {
                    setSt(() =>
                        archivoSeleccionado = File(picked.path));
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(archivoSeleccionado != null
                    ? 'Archivo seleccionado ✓'
                    : 'Adjuntar imagen o PDF'),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (examenSeleccionado == null ||
                        resultadoCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Selecciona el examen y agrega observaciones')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await _confirmarSubida(
                      context: context,
                      orden: orden,
                      tipoExamen: examenSeleccionado!,
                      resultado: resultadoCtrl.text.trim(),
                      archivo: archivoSeleccionado,
                    );
                  },
                  child: const Text('Enviar resultado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarSubida({
    required BuildContext context,
    required OrdenMedicaModel orden,
    required String tipoExamen,
    required String resultado,
    File? archivo,
  }) async {
    try {
      await _svc.subirResultado(
        ordenId: orden.id,
        tipoExamen: tipoExamen,
        resultado: resultado,
        archivo: archivo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Resultado enviado correctamente.')),
        );
        await _cargar(); // Recarga la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}