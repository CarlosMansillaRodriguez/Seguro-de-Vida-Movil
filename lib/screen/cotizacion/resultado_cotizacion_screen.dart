/*
import 'package:flutter/material.dart';
import '../../models/cotizacion_model.dart';
import '../../services/auth_service.dart';
import '../../services/cotizacion_service.dart';

class ResultadoCotizacionScreen extends StatelessWidget {
  final CotizacionResultado resultado;
  const ResultadoCotizacionScreen({super.key, required this.resultado});

  Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'BAJO':
        return Colors.green;
      case 'NORMAL':
        return Colors.blue;
      case 'MODERADO':
        return Colors.orange;
      case 'ALTO':
        return Colors.deepOrange;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Convierte la clave del backend (ej: "edad") en un label legible
  String _labelFactor(String clave) {
    const map = {
      'edad': 'Edad',
      'tabaquismo': 'Tabaquismo',
      'profesion': 'Profesión',
      'imc': 'Índice de masa corporal',
      'enfermedades': 'Enfermedades preexistentes',
      'habitos': 'Hábitos de riesgo',
      'capital': 'Capital solicitado',
    };
    return map[clave] ?? clave;
  }

  @override
  Widget build(BuildContext context) {
    final colorNivel = _colorNivel(resultado.nivelRiesgo);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de cotización')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bloque principal: nivel de riesgo + score ──────────────
            _bloqueRiesgo(colorNivel),

            const SizedBox(height: 20),

            // ── Prima (solo si NO fue rechazado) ───────────────────────
            if (!resultado.esRechazado) ...[
              _tarjeta(
                titulo: 'Prima calculada por el sistema',
                hijos: [
                  _fila('Prima base anual',
                      '\$${resultado.primaBaseAnual.toStringAsFixed(2)}'),
                  _fila('Prima ajustada anual',
                      '\$${resultado.primaAjustadaAnual.toStringAsFixed(2)}'),
                  _fila(
                    'Pago ${resultado.frecuenciaPago.toLowerCase()}',
                    '\$${resultado.primaPorFrecuencia.toStringAsFixed(2)}',
                    destacado: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Desglose de factores de riesgo (visible siempre) ───────
            _tarjeta(
              titulo: resultado.esRechazado
                  ? 'Motivos del rechazo'
                  : 'Desglose de factores de riesgo',
              hijos: _buildDesglose(),
            ),

            const SizedBox(height: 24),

            // ── Acción final ───────────────────────────────────────────
            if (resultado.esRechazado)
              _bannerRechazo()
            else
              _botonAceptar(context),

            const SizedBox(height: 12),
            if (resultado.validaHasta != null && !resultado.esRechazado)
              Center(
                child: Text(
                  'Cotización válida hasta: ${resultado.validaHasta}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Score visual ──────────────────────────────────────────────────────
  Widget _bloqueRiesgo(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(children: [
        Text('Nivel de riesgo evaluado',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 8),
        Text(
          resultado.nivelRiesgo,
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text('Score: ${resultado.scoreRiesgo} / 100',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: resultado.scoreRiesgo / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        // Escala de referencia
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 — Bajo riesgo',
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text('100 — Rechazado',
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ]),
    );
  }

  // ── Desglose de cada factor ───────────────────────────────────────────
  List<Widget> _buildDesglose() {
    if (resultado.detalleRiesgo.isEmpty) {
      return [
        const Text('Sin detalle disponible.',
            style: TextStyle(color: Colors.grey))
      ];
    }

    return resultado.detalleRiesgo.entries.map((entry) {
      final factor = entry.value as Map? ?? {};
      final puntos = factor['puntos'] ?? 0;
      final descripcion =
          factor['descripcion'] ?? 'Sin descripción';
      final label = _labelFactor(entry.key);

      // Color del factor según puntos
      Color colorPuntos = Colors.green;
      if (puntos >= 30) colorPuntos = Colors.red;
      else if (puntos >= 15) colorPuntos = Colors.orange;
      else if (puntos >= 5) colorPuntos = Colors.amber[700]!;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Puntos con color
            Container(
              width: 44,
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: colorPuntos.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colorPuntos.withOpacity(0.4)),
              ),
              child: Text(
                '+$puntos',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorPuntos),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(descripcion,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Banner de rechazo con explicación clara ───────────────────────────
  Widget _bannerRechazo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Cotización rechazada',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Tu perfil de riesgo obtuvo un score de ${resultado.scoreRiesgo}/100. '
            'El sistema rechaza automáticamente perfiles con score superior a 80. '
            'Revisa el desglose de factores para entender qué impactó en la evaluación.',
            style: TextStyle(color: Colors.red[800], fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            'Si crees que hay un error en los datos declarados, '
            'contacta a un agente para revisar tu caso.',
            style: TextStyle(
                color: Colors.red[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ── Botón aceptar (solo si no es rechazado) ───────────────────────────
  Widget _botonAceptar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _aceptar(context),
        child:
            const Text('Aceptar cotización', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _aceptar(BuildContext context) async {
    final svc = CotizacionService(AuthService());
    try {
      final resp = await svc.aceptarCotizacion(resultado.cotizacionId);
      if (!context.mounted) return;

      final requiereExamen = resp['requiere_examen_medico'] == true;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¡Cotización aceptada!'),
          content: Text(
            requiereExamen
                ? '✅ Se generará una orden médica porque tu capital supera el umbral del plan.\n\n'
                    'Podrás ver y gestionar tu orden médica desde el menú principal.'
                : '✅ No se requiere examen médico para este capital.\n\n'
                    'El siguiente paso es subir tus documentos de identidad (KYC).',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Helpers visuales ──────────────────────────────────────────────────
  Widget _tarjeta(
      {required String titulo, required List<Widget> hijos}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const Divider(height: 16),
            ...hijos,
          ],
        ),
      );

  Widget _fila(String label, String valor, {bool destacado = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13))),
            const SizedBox(width: 8),
            Text(
              valor,
              style: TextStyle(
                fontWeight:
                    destacado ? FontWeight.bold : FontWeight.normal,
                fontSize: destacado ? 16 : 13,
              ),
            ),
          ],
        ),
      );
}*/
import 'package:flutter/material.dart';
import '../../models/cotizacion_model.dart';
import '../../services/auth_service.dart';
import '../../services/cotizacion_service.dart';
import '../documentos/documentos_kyc_emision_screen.dart';

class ResultadoCotizacionScreen extends StatelessWidget {
  final CotizacionResultado resultado;
  const ResultadoCotizacionScreen({super.key, required this.resultado});

  Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'BAJO':
        return Colors.green;
      case 'NORMAL':
        return Colors.blue;
      case 'MODERADO':
        return Colors.orange;
      case 'ALTO':
        return Colors.deepOrange;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _labelFactor(String clave) {
    const map = {
      'edad': 'Edad',
      'tabaquismo': 'Tabaquismo',
      'profesion': 'Profesión',
      'imc': 'Índice de masa corporal',
      'enfermedades': 'Enfermedades preexistentes',
      'habitos': 'Hábitos de riesgo',
      'capital': 'Capital solicitado',
    };
    return map[clave] ?? clave;
  }

  @override
  Widget build(BuildContext context) {
    final colorNivel = _colorNivel(resultado.nivelRiesgo);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de cotización')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bloqueRiesgo(colorNivel),
            const SizedBox(height: 20),

            // ── Prima (solo si NO fue rechazado) ───────────────────────
            if (!resultado.esRechazado) ...[
              _tarjeta(
                titulo: 'Prima calculada',
                hijos: [
                  _fila('Prima base anual',
                      '\$${resultado.primaBaseAnual.toStringAsFixed(2)}'),
                  _fila('Prima ajustada anual',
                      '\$${resultado.primaAjustadaAnual.toStringAsFixed(2)}'),
                  _fila(
                    'Pago ${resultado.frecuenciaPago.toLowerCase()}',
                    '\$${resultado.primaPorFrecuencia.toStringAsFixed(2)}',
                    destacado: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Desglose factores ───────────────────────────────────────
            _tarjeta(
              titulo: resultado.esRechazado
                  ? 'Motivos del rechazo'
                  : 'Desglose de factores de riesgo',
              hijos: _buildDesglose(),
            ),

            const SizedBox(height: 24),

            // ── Acción ─────────────────────────────────────────────────
            if (resultado.esRechazado)
              _bannerRechazo()
            else
              _botonAceptar(context),

            const SizedBox(height: 12),
            if (resultado.validaHasta != null && !resultado.esRechazado)
              Center(
                child: Text(
                  'Cotización válida hasta: ${resultado.validaHasta}',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _bloqueRiesgo(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(children: [
        Text('Nivel de riesgo evaluado',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 8),
        Text(
          resultado.nivelRiesgo,
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text('Score: ${resultado.scoreRiesgo} / 100',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: resultado.scoreRiesgo / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 — Bajo riesgo',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text('100 — Rechazado',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ]),
    );
  }

  List<Widget> _buildDesglose() {
    if (resultado.detalleRiesgo.isEmpty) {
      return [
        const Text('Sin detalle disponible.',
            style: TextStyle(color: Colors.grey))
      ];
    }

    return resultado.detalleRiesgo.entries.map((entry) {
      final factor = entry.value as Map? ?? {};
      final puntos = factor['puntos'] ?? 0;
      final descripcion = factor['descripcion'] ?? 'Sin descripción';
      final label = _labelFactor(entry.key);

      Color colorPuntos = Colors.green;
      if (puntos >= 30) colorPuntos = Colors.red;
      else if (puntos >= 15) colorPuntos = Colors.orange;
      else if (puntos >= 5) colorPuntos = Colors.amber[700]!;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: colorPuntos.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: colorPuntos.withOpacity(0.4)),
              ),
              child: Text(
                '+$puntos',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorPuntos),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(descripcion,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _bannerRechazo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Cotización rechazada',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Tu perfil de riesgo obtuvo un score de ${resultado.scoreRiesgo}/100. '
            'El sistema rechaza automáticamente perfiles con score superior a 80.',
            style: TextStyle(color: Colors.red[800], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // El cliente acepta → el agente podrá verla y revisarla
  /*Widget _botonAceptar(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Text(
            'Al aceptar esta cotización, un agente la revisará y la aprobará '
            'o rechazará. También deberás subir tus documentos de identidad (KYC).',
            style: TextStyle(color: Colors.blue, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _aceptar(context),
            child: const Text('Aceptar cotización',
                style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Future<void> _aceptar(BuildContext context) async {
    final svc = CotizacionService(AuthService());
    try {
      final resp =
          await svc.aceptarCotizacion(resultado.cotizacionId);
      if (!context.mounted) return;

      final requiereExamen = resp['requiere_examen_medico'] == true;

      // Navegar directamente a subir KYC (con bandera de orden médica si aplica)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentosKycEmisionScreen(
            cotizacionId: resultado.cotizacionId,
            requiereOrdenMedica: requiereExamen,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }*/
  Widget _botonAceptar(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Text(
            'Tu cotización quedará pendiente de revisión. Sube tus documentos '
            'de identidad (KYC) ahora; un agente la aprobará o rechazará luego.',
            style: TextStyle(color: Colors.blue, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _continuar(context),
            child: const Text('Aceptar Cotizacion y subir documentos',
                style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _continuar(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentosKycEmisionScreen(
          cotizacionId: resultado.cotizacionId,
          requiereOrdenMedica: false,
        ),
      ),
    );
  }

  Widget _tarjeta(
          {required String titulo, required List<Widget> hijos}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const Divider(height: 16),
            ...hijos,
          ],
        ),
      );

  Widget _fila(String label, String valor,
          {bool destacado = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13))),
            const SizedBox(width: 8),
            Text(
              valor,
              style: TextStyle(
                fontWeight:
                    destacado ? FontWeight.bold : FontWeight.normal,
                fontSize: destacado ? 16 : 13,
              ),
            ),
          ],
        ),
      );
}