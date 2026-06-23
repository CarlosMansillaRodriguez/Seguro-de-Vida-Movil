import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/cu_extras_service.dart';

class ValorRescateScreen extends StatefulWidget {
  final int polizaId;
  final String numeroPoliza;
  const ValorRescateScreen({
    super.key,
    required this.polizaId,
    required this.numeroPoliza,
  });

  @override
  State<ValorRescateScreen> createState() => _ValorRescateScreenState();
}

class _ValorRescateScreenState extends State<ValorRescateScreen> {
  final _svc = CuExtrasService(AuthService());
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await _svc.proyectarRescate(widget.polizaId);
      setState(() {
        _data = r;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Valor de rescate — ${widget.numeroPoliza}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _cargar,
                            child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _data?['aplica'] == false
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.savings_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _data?['mensaje'] ??
                                  'Este plan no genera valor de rescate.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tipo de plan: ${_data?['tipo_plan'] ?? '-'}',
                              style:
                                  const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _vistaRescate(),
    );
  }

  Widget _vistaRescate() {
    final actual = _data!['valor_rescate_actual'] as Map?;
    final tabla = List<Map<String, dynamic>>.from(
        _data!['tabla_completa'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen de la póliza
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Póliza: ${_data!['poliza']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Plan: ${_data!['tipo_plan']}',
                  style: const TextStyle(color: Colors.grey)),
              Text(
                  'Prima anual: \$${double.parse(_data!['prima_anual_facturada'].toString()).toStringAsFixed(2)}'),
              Text('Plazo total: ${_data!['plazo_total_anios']} años'),
              Text('Inicio vigencia: ${_data!['fecha_inicio_vigencia']}'),
            ],
          ),
        ),

        // Valor actual de rescate
        if (actual != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Valor de rescate actual',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  '\$${double.parse(actual['valor_rescate'].toString()).toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                Text(
                    'Año ${actual['anio']} · Factor ${actual['factor_rescate_pct']}%'),
                Text('Fecha: ${actual['fecha_proyectada']}'),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        const Text('Proyección completa',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          _data!['nota'] ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Tabla
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
            border: TableBorder.all(
                color: Colors.grey[200]!, width: 0.5),
            columns: const [
              DataColumn(
                  label: Text('Año',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
              DataColumn(
                  label: Text('Fecha',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
              DataColumn(
                  label: Text('Factor',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
              DataColumn(
                  label: Text('Rescate',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
            ],
            rows: tabla.map((r) {
              final transcurrido = r['ya_transcurrido'] == true;
              return DataRow(
                color: transcurrido
                    ? WidgetStateProperty.all(Colors.green[50])
                    : WidgetStateProperty.all(Colors.white),
                cells: [
                  DataCell(Text('${r['anio']}',
                      style: TextStyle(
                          fontWeight: transcurrido
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12))),
                  DataCell(Text('${r['fecha_proyectada']}',
                      style: const TextStyle(fontSize: 11))),
                  DataCell(Text(
                      '${r['factor_rescate_pct']}%',
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(
                    '\$${double.parse(r['valor_rescate'].toString()).toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: transcurrido
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: transcurrido
                            ? Colors.green[700]
                            : Colors.black87),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}