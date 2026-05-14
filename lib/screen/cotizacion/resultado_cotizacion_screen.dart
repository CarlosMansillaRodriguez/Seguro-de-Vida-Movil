import 'package:flutter/material.dart';
import '../../models/cotizacion_model.dart';
import '../../services/auth_service.dart';
import '../../services/cotizacion_service.dart';

class ResultadoCotizacionScreen extends StatelessWidget {
  final CotizacionResultado resultado;
  const ResultadoCotizacionScreen({super.key, required this.resultado});

  Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'BAJO': return Colors.green;
      case 'NORMAL': return Colors.blue;
      case 'MODERADO': return Colors.orange;
      case 'ALTO': return Colors.deepOrange;
      case 'RECHAZADO': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esRechazado = resultado.nivelRiesgo == 'RECHAZADO';
    final colorNivel = _colorNivel(resultado.nivelRiesgo);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de cotización')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score de riesgo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorNivel.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorNivel.withOpacity(0.4)),
              ),
              child: Column(children: [
                Text('Nivel de Riesgo', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(
                  resultado.nivelRiesgo,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorNivel,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Score: ${resultado.scoreRiesgo}/100',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: resultado.scoreRiesgo / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(colorNivel),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            if (!esRechazado) ...[
              // Prima
              _tarjeta(
                titulo: 'Prima calculada',
                hijos: [
                  _fila('Prima base anual', '\$${resultado.primaBaseAnual.toStringAsFixed(2)}'),
                  _fila('Prima ajustada anual', '\$${resultado.primaAjustadaAnual.toStringAsFixed(2)}'),
                  _fila(
                    'Por ${resultado.frecuenciaPago.toLowerCase()}',
                    '\$${resultado.primaPorFrecuencia.toStringAsFixed(2)}',
                    destacado: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Desglose de riesgo
            _tarjeta(
              titulo: 'Desglose de factores de riesgo',
              hijos: resultado.detalleRiesgo.entries.map((e) {
                final v = e.value as Map?;
                return _fila(
                  e.key.toUpperCase(),
                  '${v?['puntos'] ?? 0} pts — ${v?['descripcion'] ?? ''}',
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (esRechazado)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: const Text(
                  'Lo sentimos. El perfil de riesgo no cumple los criterios de aceptación.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _aceptar(context),
                  child: const Text('Aceptar cotización', style: TextStyle(fontSize: 16)),
                ),
              ),

            const SizedBox(height: 12),
            if (resultado.validaHasta != null)
              Text(
                'Válida hasta: ${resultado.validaHasta}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _aceptar(BuildContext context) async {
    final svc = CotizacionService(AuthService());
    try {
      final resp = await svc.aceptarCotizacion(resultado.cotizacionId);
      if (context.mounted) {
        final requiereExamen = resp['requiere_examen_medico'] == true;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('¡Cotización aceptada!'),
            content: Text(
              requiereExamen
                  ? 'Se requiere un examen médico. El próximo paso es generar la orden médica.'
                  : 'El próximo paso es subir tus documentos de identidad (KYC).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _tarjeta({required String titulo, required List<Widget> hijos}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const Divider(height: 16),
        ...hijos,
      ],
    ),
  );

  Widget _fila(String label, String valor, {bool destacado = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            valor,
            style: TextStyle(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              fontSize: destacado ? 15 : 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}