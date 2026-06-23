import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/cu_extras_service.dart';

class RecomendacionIAScreen extends StatefulWidget {
  final int? cotizacionId;
  const RecomendacionIAScreen({super.key, this.cotizacionId});

  @override
  State<RecomendacionIAScreen> createState() =>
      _RecomendacionIAScreenState();
}

class _RecomendacionIAScreenState extends State<RecomendacionIAScreen> {
  final _svc = CuExtrasService(AuthService());

  bool _tieneHijos = false;
  int _numHijos = 1;
  String _objetivo = 'PROTECCION';
  int _horizonteAnios = 10;
  String _nivelIngresos = 'MEDIO';
  bool _procesando = false;
  Map<String, dynamic>? _resultado;
  String? _error;

  static const _objetivos = [
    {'value': 'PROTECCION', 'label': 'Protección familiar'},
    {'value': 'AHORRO', 'label': 'Ahorro a largo plazo'},
    {'value': 'INVERSION', 'label': 'Inversión'},
    {'value': 'MIXTO', 'label': 'Mixto (protección + ahorro)'},
  ];

  static const _ingresos = [
    {'value': 'BAJO', 'label': 'Bajo (< \$500/mes)'},
    {'value': 'MEDIO', 'label': 'Medio (\$500 – \$2,000/mes)'},
    {'value': 'ALTO', 'label': 'Alto (> \$2,000/mes)'},
  ];

  Future<void> _obtenerRecomendacion() async {
    setState(() {
      _procesando = true;
      _resultado = null;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'tiene_hijos': _tieneHijos,
        'num_hijos': _tieneHijos ? _numHijos : 0,
        'objetivo': _objetivo,
        'horizonte_anios': _horizonteAnios,
        'nivel_ingresos': _nivelIngresos,
        if (widget.cotizacionId != null)
          'cotizacion_id': widget.cotizacionId,
      };
      final r = await _svc.recomendacionIA(body);
      setState(() {
        _resultado = r;
        _procesando = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recomendación de seguros IA')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(),
            const SizedBox(height: 20),
            if (_resultado == null) ...[
              _formulario(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      _procesando ? null : _obtenerRecomendacion,
                  icon: _procesando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_procesando
                      ? 'Analizando tu perfil con Gemini...'
                      : 'Obtener recomendación IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ),
              ],
            ] else
              _panelResultados(),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.deepPurple.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.deepPurple),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemini analiza tu perfil',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                      'Responde unas preguntas y te sugerimos los 3 planes más adecuados para ti.',
                      style: TextStyle(
                          color: Colors.deepPurple, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _formulario() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tu perfil',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('¿Tienes hijos?'),
            value: _tieneHijos,
            onChanged: (v) => setState(() => _tieneHijos = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_tieneHijos) ...[
            Text('Número de hijos: $_numHijos',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13)),
            Slider(
              value: _numHijos.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_numHijos',
              onChanged: (v) =>
                  setState(() => _numHijos = v.round()),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _objetivo,
            decoration: const InputDecoration(
                labelText: 'Objetivo principal',
                border: OutlineInputBorder()),
            items: _objetivos
                .map((o) => DropdownMenuItem(
                    value: o['value'], child: Text(o['label']!)))
                .toList(),
            onChanged: (v) =>
                setState(() => _objetivo = v ?? 'PROTECCION'),
          ),
          const SizedBox(height: 12),
          Text('Horizonte de inversión: $_horizonteAnios años',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
          Slider(
            value: _horizonteAnios.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            label: '$_horizonteAnios años',
            onChanged: (v) =>
                setState(() => _horizonteAnios = v.round()),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _nivelIngresos,
            decoration: const InputDecoration(
                labelText: 'Nivel de ingresos',
                border: OutlineInputBorder()),
            items: _ingresos
                .map((i) => DropdownMenuItem(
                    value: i['value'], child: Text(i['label']!)))
                .toList(),
            onChanged: (v) =>
                setState(() => _nivelIngresos = v ?? 'MEDIO'),
          ),
          if (widget.cotizacionId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.link, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Text(
                    'Incluye score de riesgo de cotización #${widget.cotizacionId}',
                    style: const TextStyle(
                        color: Colors.blue, fontSize: 12)),
              ]),
            ),
          ],
        ],
      );

  Widget _panelResultados() {
    final r = _resultado!;
    final recomendaciones = List<Map<String, dynamic>>.from(
        r['recomendaciones'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r['resumen_perfil'] != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[100]!)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline,
                    color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(r['resumen_perfil'],
                        style: const TextStyle(
                            color: Colors.blue, fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Planes recomendados para ti',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ...recomendaciones.map(_tarjetaRecomendacion),
        if (r['consejo_general'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text('Consejo personalizado',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ]),
                const SizedBox(height: 6),
                Text(r['consejo_general'],
                    style: const TextStyle(
                        fontSize: 13, color: Colors.green)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _resultado = null;
              _error = null;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Nueva consulta'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _tarjetaRecomendacion(Map<String, dynamic> rec) {
    final score = (rec['score_idoneidad'] ?? 0) as num;
    final puntos = List<String>.from(rec['puntos_fuertes'] ?? []);
    final consideraciones =
        List<String>.from(rec['consideraciones'] ?? []);
    final color = score >= 75
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(rec['nombre_plan'] ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text('${score.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Text(rec['justificacion'] ?? '',
                style: const TextStyle(fontSize: 13)),
            if (puntos.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Puntos fuertes',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              ...puntos.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(p,
                              style: const TextStyle(fontSize: 12))),
                    ]),
                  )),
            ],
            if (consideraciones.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('A considerar',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              ...consideraciones.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(c,
                              style: const TextStyle(fontSize: 12))),
                    ]),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}