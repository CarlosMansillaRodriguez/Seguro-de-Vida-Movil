import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../models/reporte_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  final _svc = AdminService(AuthService());
  late TabController _tabs;

  // ── Metadatos ────────────────────────────────────────────────────────
  Map<String, ModeloMetadata> _metadata = {};
  bool _loadingMeta = true;

  // ── Paso 1: modelo seleccionado ──────────────────────────────────────
  String? _modeloKey;
  ModeloMetadata? get _modelo =>
      _modeloKey != null ? _metadata[_modeloKey] : null;

  // ── Paso 2: columnas ─────────────────────────────────────────────────
  final Set<String> _columnasSeleccionadas = {};

  // ── Paso 3: filtros ──────────────────────────────────────────────────
  final List<FiltroActivo> _filtros = [];

  // ── Resultados ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _datos = [];
  int _total = 0;
  bool _cargando = false;
  String? _error;

  // ── Email ────────────────────────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  bool _enviandoEmail = false;

  // ── Voz/IA ───────────────────────────────────────────────────────────
  final _vozCtrl = TextEditingController();
  bool _procesandoIA = false;

  // ── Ordenamiento ─────────────────────────────────────────────────────
  String? _orderingCampo;
  bool _orderingDesc = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _cargarMetadata();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _vozCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMetadata() async {
    try {
      final meta = await _svc.obtenerMetadata();
      setState(() {
        _metadata = meta;
        _loadingMeta = false;
      });
    } catch (e) {
      setState(() {
        _loadingMeta = false;
        _error = 'Error al cargar metadatos: $e';
      });
    }
  }

  // ── Genera el reporte JSON con los parámetros actuales ───────────────
  Future<void> _generarReporte() async {
    if (_modeloKey == null) {
      _mostrarSnack('Selecciona un módulo primero');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
      _datos = [];
    });
    try {
      final ordering = _orderingCampo != null
          ? '${_orderingDesc ? '-' : ''}$_orderingCampo'
          : null;

      final result = await _svc.obtenerReporteJson(
        modelo: _modeloKey!,
        campos: _columnasSeleccionadas.isNotEmpty
            ? _columnasSeleccionadas.toList()
            : null,
        filtros: _buildFiltrosMap(),
        ordering: ordering,
        limit: 200, // límite de previsualización
      );
      setState(() {
        _datos = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _total = result['total'] ?? 0;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Map<String, String> _buildFiltrosMap() {
    final map = <String, String>{};
    for (final f in _filtros) {
      if (f.esValido) {
        final entry = f.toQueryParam();
        map[entry.key] = entry.value;
      }
    }
    return map;
  }

  // ── Exportaciones ────────────────────────────────────────────────────
  Future<void> _exportarExcel() async {
    if (_modeloKey == null) return;
    setState(() => _cargando = true);
    try {
      final bytes = await _svc.descargarExcel(
        modelo: _modeloKey!,
        campos: _columnasSeleccionadas.isNotEmpty
            ? _columnasSeleccionadas.toList()
            : null,
        filtros: _buildFiltrosMap(),
      );
      _mostrarSnack(
        'Excel generado (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
      );
      // En producción usa open_file o path_provider para guardar/abrir el archivo.
      // Por ahora copiamos los bytes al portapapeles como base64 para demostración.
      // Para guardar en disco: ver sección "pubspec.yaml" al final.
      await _guardarYAbrirArchivo(bytes, 'reporte.xlsx');
    } catch (e) {
      _mostrarSnack('Error Excel: $e', isError: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _exportarPdf() async {
    if (_modeloKey == null) return;
    setState(() => _cargando = true);
    try {
      final bytes = await _svc.descargarPdf(
        modelo: _modeloKey!,
        campos: _columnasSeleccionadas.isNotEmpty
            ? _columnasSeleccionadas.toList()
            : null,
        filtros: _buildFiltrosMap(),
      );
      _mostrarSnack(
        'PDF generado (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
      );
      await _guardarYAbrirArchivo(bytes, 'reporte.pdf');
    } catch (e) {
      _mostrarSnack('Error PDF: $e', isError: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _enviarEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _mostrarSnack('Ingresa un email válido', isError: true);
      return;
    }
    if (_modeloKey == null) {
      _mostrarSnack('Selecciona un módulo primero', isError: true);
      return;
    }
    setState(() => _enviandoEmail = true);
    try {
      final msg = await _svc.enviarReportePorEmail(
        modelo: _modeloKey!,
        emailTo: email,
        campos: _columnasSeleccionadas.isNotEmpty
            ? _columnasSeleccionadas.toList()
            : null,
        filtros: _buildFiltrosMap(),
      );
      _mostrarSnack(msg);
      _emailCtrl.clear();
      Navigator.pop(context); // cierra el dialog
    } catch (e) {
      _mostrarSnack('Error: $e', isError: true);
    } finally {
      setState(() => _enviandoEmail = false);
    }
  }

  Future<void> _procesarComandoIA() async {
    final texto = _vozCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _procesandoIA = true);
    try {
      final res = await _svc.reportePorVoz(texto);
      final urlGenerada = res['url_generada'] as String? ?? '';
      final modeloDetectado = res['modelo_detectado'] as String? ?? '';

      // Parseamos la URL generada por la IA para extraer parámetros
      if (urlGenerada.isNotEmpty) {
        final uri = Uri.parse('http://x$urlGenerada');
        final params = uri.queryParameters;

        setState(() {
          _modeloKey =
              modeloDetectado.isNotEmpty &&
                  _metadata.containsKey(modeloDetectado)
              ? modeloDetectado
              : _modeloKey;
          // Cargamos los filtros detectados por la IA
          _filtros.clear();
          params.forEach((key, value) {
            if (key != 'modelo' && key != 'export') {
              // Buscamos el campo correspondiente
              if (_modelo != null) {
                final nombreCampo = key.split('__').first;
                final campo = _modelo!.campos
                    .where((c) => c.name == nombreCampo)
                    .firstOrNull;
                if (campo != null) {
                  final operador = key.contains('__')
                      ? '__${key.split('__').skip(1).join('__')}'
                      : '';
                  _filtros.add(
                    FiltroActivo(
                      campo: campo,
                      operador: operador,
                      valor: value,
                    ),
                  );
                }
              }
            }
          });
          _procesandoIA = false;
        });

        await _generarReporte();
        _vozCtrl.clear();
        _mostrarSnack('IA generó el reporte: "$texto"');
      }
    } catch (e) {
      _mostrarSnack('Error IA: $e', isError: true);
      setState(() => _procesandoIA = false);
    }
  }

  // ── Diálogo de descarga (muestra tamaño y permite "guardar") ─────────
  /*void _abrirDialogoDescarga(Uint8List bytes, String nombre, String mime) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archivo listo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${(bytes.length / 1024).toStringAsFixed(1)} KB',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Para guardar el archivo instala el paquete "open_filex" '
              'y llama a OpenFilex.open(path). Ver instrucciones al pie.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }*/
  Future<void> _guardarYAbrirArchivo(Uint8List bytes, String nombre) async {
    try {
      // Guarda en la carpeta temporal del dispositivo
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$nombre');
      await file.writeAsBytes(bytes);
      // Abre con la app del sistema (visor PDF, Excel, etc.)
      await OpenFilex.open(file.path);
    } catch (e) {
      _mostrarSnack('No se pudo abrir el archivo: $e', isError: true);
    }
  }

  void _mostrarSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : null,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes dinámicos'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'Constructor'),
            Tab(icon: Icon(Icons.table_chart), text: 'Resultados'),
          ],
        ),
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_tabConstructor(), _tabResultados()],
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 1 — Constructor
  // ══════════════════════════════════════════════════════════════════════

  Widget _tabConstructor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Comando IA ────────────────────────────────────────────────
          _seccionIA(),
          const SizedBox(height: 20),

          // ── Paso 1: Módulo ────────────────────────────────────────────
          _paso(
            numero: '1',
            titulo: 'Módulo de datos',
            child: _selectorModelo(),
          ),
          const SizedBox(height: 16),

          // ── Paso 2: Columnas ──────────────────────────────────────────
          if (_modelo != null) ...[
            _paso(
              numero: '2',
              titulo: 'Columnas a mostrar',
              subtitulo:
                  '${_columnasSeleccionadas.isEmpty ? "Todas" : _columnasSeleccionadas.length.toString()} seleccionadas',
              child: _selectorColumnas(),
            ),
            const SizedBox(height: 16),

            // ── Paso 3: Filtros ──────────────────────────────────────────
            _paso(
              numero: '3',
              titulo: 'Filtros',
              subtitulo: '${_filtros.where((f) => f.esValido).length} activos',
              child: _constructorFiltros(),
            ),
            const SizedBox(height: 16),

            // ── Paso 4: Ordenamiento ─────────────────────────────────────
            _paso(
              numero: '4',
              titulo: 'Ordenar por',
              child: _selectorOrdenamiento(),
            ),
            const SizedBox(height: 24),
          ],

          // ── Botón generar ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_cargando || _modeloKey == null)
                  ? null
                  : () async {
                      await _generarReporte();
                      _tabs.animateTo(1); // ir a resultados
                    },
              icon: _cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _cargando ? 'Generando...' : 'Generar reporte',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Sección de comando IA ────────────────────────────────────────────
  Widget _seccionIA() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 18),
              SizedBox(width: 8),
              Text(
                'Generar con IA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vozCtrl,
                  decoration: const InputDecoration(
                    hintText:
                        'Ej: "pólizas activas", "cotizaciones pendientes de enero"',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _procesandoIA ? null : _procesarComandoIA,
                  child: _procesandoIA
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Selector de modelo ───────────────────────────────────────────────
  Widget _selectorModelo() {
    final opciones = _metadata.entries.toList();
    return DropdownButtonFormField<String>(
      value: _modeloKey,
      decoration: const InputDecoration(
        hintText: 'Selecciona el módulo',
        border: OutlineInputBorder(),
      ),
      items: opciones.map((e) {
        return DropdownMenuItem(
          value: e.key,
          child: Text(e.value.verboseNamePlural),
        );
      }).toList(),
      onChanged: (v) {
        setState(() {
          _modeloKey = v;
          _columnasSeleccionadas.clear();
          _filtros.clear();
          _orderingCampo = null;
          _datos = [];
          _total = 0;
        });
      },
    );
  }

  // ── Selector de columnas (chips) ─────────────────────────────────────
  Widget _selectorColumnas() {
    if (_modelo == null) return const SizedBox();
    final campos = _modelo!.campos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botones rápidos
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _columnasSeleccionadas.addAll(campos.map((c) => c.name));
              }),
              child: const Text('Seleccionar todo'),
            ),
            TextButton(
              onPressed: () => setState(() => _columnasSeleccionadas.clear()),
              child: const Text('Limpiar'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: campos.map((campo) {
            final selected = _columnasSeleccionadas.contains(campo.name);
            return FilterChip(
              label: Text(campo.label, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _columnasSeleccionadas.add(campo.name);
                  } else {
                    _columnasSeleccionadas.remove(campo.name);
                  }
                });
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Constructor de filtros ───────────────────────────────────────────
  Widget _constructorFiltros() {
    if (_modelo == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._filtros.asMap().entries.map((entry) {
          return _itemFiltro(entry.key, entry.value);
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _agregarFiltro,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar filtro'),
        ),
      ],
    );
  }

  Widget _itemFiltro(int idx, FiltroActivo filtro) {
    final campos = _modelo!.campos;

    // Operadores disponibles según tipo de campo
    List<DropdownMenuItem<String>> operadores() {
      if (filtro.campo.esBooleano) {
        return [const DropdownMenuItem(value: '', child: Text('igual a'))];
      }
      if (filtro.campo.esRango) {
        return [
          const DropdownMenuItem(value: '', child: Text('igual a')),
          const DropdownMenuItem(value: '__gte', child: Text('mayor o igual')),
          const DropdownMenuItem(value: '__lte', child: Text('menor o igual')),
        ];
      }
      return [
        const DropdownMenuItem(value: '', child: Text('igual a')),
        const DropdownMenuItem(value: '__icontains', child: Text('contiene')),
        const DropdownMenuItem(value: '__in', child: Text('está en lista')),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Selector de campo
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: filtro.campo.name,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Campo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: campos
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(
                        c.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    final nuevoCampo = campos.firstWhere((c) => c.name == v);
                    _filtros[idx] = FiltroActivo(campo: nuevoCampo);
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          // Selector de operador
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: filtro.operador,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Condición',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: operadores(),
              onChanged: (v) {
                setState(() => _filtros[idx].operador = v ?? '');
              },
            ),
          ),
          const SizedBox(width: 6),
          // Valor del filtro
          Expanded(
            flex: 3,
            child: filtro.campo.esBooleano
                ? DropdownButtonFormField<String>(
                    value: filtro.valor.isEmpty ? 'true' : filtro.valor,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'true', child: Text('Sí')),
                      DropdownMenuItem(value: 'false', child: Text('No')),
                    ],
                    onChanged: (v) {
                      setState(() => _filtros[idx].valor = v ?? 'true');
                    },
                  )
                : TextFormField(
                    initialValue: filtro.valor,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Valor',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      _filtros[idx].valor = v;
                    },
                  ),
          ),
          const SizedBox(width: 6),
          // Botón eliminar
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: () => setState(() => _filtros.removeAt(idx)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  void _agregarFiltro() {
    if (_modelo == null || _modelo!.campos.isEmpty) return;
    setState(() {
      _filtros.add(FiltroActivo(campo: _modelo!.campos.first));
    });
  }

  // ── Selector de ordenamiento ─────────────────────────────────────────
  Widget _selectorOrdenamiento() {
    if (_modelo == null) return const SizedBox();
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            value: _orderingCampo,
            decoration: const InputDecoration(
              hintText: 'Sin ordenamiento',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Sin ordenamiento'),
              ),
              ..._modelo!.campos.map(
                (c) => DropdownMenuItem(value: c.name, child: Text(c.label)),
              ),
            ],
            onChanged: (v) => setState(() => _orderingCampo = v),
          ),
        ),
        const SizedBox(width: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.arrow_upward, size: 16),
              label: Text('Asc'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.arrow_downward, size: 16),
              label: Text('Desc'),
            ),
          ],
          selected: {_orderingDesc},
          onSelectionChanged: (v) => setState(() => _orderingDesc = v.first),
        ),
      ],
    );
  }

  // ── Widget de "paso" numerado ────────────────────────────────────────
  Widget _paso({
    required String numero,
    required String titulo,
    String? subtitulo,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitulo,
                    style: const TextStyle(color: Colors.blue, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 2 — Resultados
  // ══════════════════════════════════════════════════════════════════════

  Widget _tabResultados() {
    return Column(
      children: [
        // ── Barra de acciones de exportación ─────────────────────────
        if (_datos.isNotEmpty || _modeloKey != null) _barraExportacion(),

        // ── Contenido ────────────────────────────────────────────────
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _panelError()
              : _datos.isEmpty
              ? _sinDatos()
              : _tablaResultados(),
        ),
      ],
    );
  }

  Widget _barraExportacion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.withOpacity(0.06),
      child: Row(
        children: [
          if (_total > 0)
            Text(
              '$_total registro${_total == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          const Spacer(),
          // PDF
          _botonExport(
            icono: Icons.picture_as_pdf,
            label: 'PDF',
            color: Colors.red,
            onTap: _exportarPdf,
          ),
          const SizedBox(width: 8),
          // Excel
          _botonExport(
            icono: Icons.table_chart,
            label: 'Excel',
            color: Colors.green[700]!,
            onTap: _exportarExcel,
          ),
          const SizedBox(width: 8),
          // Email
          _botonExport(
            icono: Icons.email_outlined,
            label: 'Email',
            color: Colors.blue,
            onTap: _abrirDialogoEmail,
          ),
        ],
      ),
    );
  }

  Widget _botonExport({
    required IconData icono,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _cargando ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoEmail() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Enviar reporte por email'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'El reporte se generará en PDF y se enviará al correo indicado.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo destinatario',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _enviandoEmail ? null : _enviarEmail,
            child: _enviandoEmail
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ── Tabla de resultados scrolleable ──────────────────────────────────
  Widget _tablaResultados() {
    if (_datos.isEmpty) return _sinDatos();
    final columnas = _datos.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.blue.withOpacity(0.08),
          ),
          border: TableBorder.all(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
          columnSpacing: 20,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(fontSize: 12),
          columns: columnas.map((col) {
            return DataColumn(
              label: Text(col.replaceAll('_', ' ').toUpperCase()),
              onSort: (_, __) {
                setState(() {
                  if (_orderingCampo == col) {
                    _orderingDesc = !_orderingDesc;
                  } else {
                    _orderingCampo = col;
                    _orderingDesc = false;
                  }
                });
                _generarReporte();
              },
            );
          }).toList(),
          rows: _datos.map((row) {
            return DataRow(
              cells: columnas.map((col) {
                final val = row[col]?.toString() ?? '';
                return DataCell(
                  Tooltip(
                    message: val,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        val,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sinDatos() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.table_chart_outlined, size: 56, color: Colors.grey[400]),
        const SizedBox(height: 14),
        Text(
          _modeloKey == null
              ? 'Selecciona un módulo en el Constructor'
              : 'Presiona "Generar reporte" para ver los datos',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500]),
        ),
        if (_modeloKey != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generarReporte,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Generar ahora'),
          ),
        ],
      ],
    ),
  );

  Widget _panelError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generarReporte,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
