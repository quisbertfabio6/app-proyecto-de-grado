import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/asistencia_cierre_service.dart';
import '../../utils/database_helper.dart';

class ControlManualScreen extends StatefulWidget {
  final int materiaId;
  final String nombreMateria;

  const ControlManualScreen({
    super.key, 
    required this.materiaId, 
    required this.nombreMateria
  });

  @override
  State<ControlManualScreen> createState() => _ControlManualScreenState();
}

class _ControlManualScreenState extends State<ControlManualScreen> {
  List<dynamic> _estudiantes = [];
  List<String> _fechasDisponibles = []; 
  String _fechaSeleccionada = ""; 
  bool _isLoading = true;
  bool _guardando = false;

  bool get _esHoy => _fechasDisponibles.isNotEmpty &&
      _fechaSeleccionada == _fechasDisponibles.first;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  void _inicializarDatos() async {
    // 1. Definir fecha de hoy
    final now = DateTime.now();
    final hoyString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    _fechaSeleccionada = hoyString; 

    // 2. Traer historial de fechas del servidor
    final fechasServer = await ApiService.getFechasClases(widget.materiaId);
    
    if (mounted) {
      setState(() {
        // Lista: [HOY] + [Fechas anteriores]
        _fechasDisponibles = [hoyString, ...fechasServer.where((f) => f != hoyString)];
      });
      _cargarLista();
    }
  }

  Future<void> _cargarLista() async {
    setState(() => _isLoading = true);
    // Ahora sí ApiService acepta el parámetro 'fecha'
    final lista = await ApiService.getListaControl(widget.materiaId, fecha: _fechaSeleccionada);
    if (mounted) {
      setState(() {
        _estudiantes = lista;
        _isLoading = false;
      });
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    if (_guardando || _isLoading || !_esHoy) return;
    setState(() => _guardando = true);
    try {
      final resultado = await ApiService.registrarManual(
        estudianteId: id,
        materiaId: widget.materiaId,
        estado: nuevoEstado,
      );
      if (!mounted) return;
      if (resultado['success'] != true) {
        _mostrarMensaje(resultado['message']?.toString() ?? 'No se pudo registrar.');
      }
      await _cargarLista();
    } catch (_) {
      _mostrarMensaje('No se pudo registrar la asistencia.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _finalizarAsistencia() async {
    if (_guardando || _isLoading || !_esHoy || _estudiantes.isEmpty) return;
    final fecha = _fechaSeleccionada;
    setState(() => _guardando = true);
    try {
      final pendientes = await DatabaseHelper().getPendientes();
      if (!mounted) return;
      if (pendientes.any((a) =>
          a['materia_id'] == widget.materiaId && a['fecha'] == fecha)) {
        _mostrarMensaje('Hay asistencias offline pendientes de esta clase. '
            'Sincronízalas desde el inicio del docente antes de finalizar.');
        return;
      }

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Finalizar asistencia'),
          content: Text(
            'Materia: ${widget.nombreMateria}\nFecha: $fecha\n\n'
            'Se marcará falta a quienes no tengan registro y se respetarán '
            'las licencias aprobadas. Confirma que la clase se realizó y que '
            'no quedan escaneos pendientes en otros dispositivos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );
      if (!mounted || confirmar != true) return;

      final resultado = await AsistenciaCierreService.finalizar(
        materiaId: widget.materiaId,
        fecha: fecha,
      );
      if (!mounted) return;
      if (resultado['success'] != true) {
        _mostrarMensaje(resultado['message']?.toString() ?? 'No se pudo finalizar.');
        return;
      }
      await _cargarLista();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Asistencia finalizada'),
          content: Text(
            'Faltas generadas: ${resultado['faltas_generadas']}\n'
            'Licencias registradas: ${resultado['licencias_registradas']}\n'
            'Registros conservados: ${resultado['registros_conservados']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (_) {
      _mostrarMensaje('No se pudo finalizar. Revisa la conexión y vuelve a intentar.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia'), 
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _guardando || _isLoading || !_esHoy || _estudiantes.isEmpty
                ? null : _finalizarAsistencia,
            icon: const Icon(Icons.fact_check),
            label: Text(_guardando ? 'Procesando...' : 'Finalizar asistencia'),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- BARRA DE FECHAS (CARRUSEL) ---
          Container(
            height: 60,
            color: Theme.of(context).colorScheme.primary,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _fechasDisponibles.length,
              itemBuilder: (context, index) {
                final fecha = _fechasDisponibles[index];
                final esSeleccionada = fecha == _fechaSeleccionada;
                final esHoy = index == 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(
                      esHoy ? "HOY ($fecha)" : fecha,
                      style: TextStyle(
                        color: esSeleccionada ? Theme.of(context).colorScheme.onSurface : Colors.white,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    selected: esSeleccionada,
                    selectedColor: Theme.of(context).colorScheme.surface,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onSelected: _guardando || _isLoading ? null : (bool selected) {
                      if (selected) {
                        setState(() => _fechaSeleccionada = fecha);
                        _cargarLista();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // --- TÍTULO DE LISTA ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Theme.of(context).colorScheme.surface,
            child: Text(
              "Mostrando asistencia del: $_fechaSeleccionada",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
          ),

          // --- LISTA DE ESTUDIANTES ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: _estudiantes.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final est = _estudiantes[index];
                      final porcentaje = est['porcentaje'] ?? 0;
                      final esRiesgo = est['riesgo'] ?? false;
                      final estadoHoy = est['estado_hoy'];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                        leading: CircleAvatar(
                          backgroundColor: esRiesgo ? Colors.red.shade100 : Colors.green.shade100,
                          child: Text(
                            "$porcentaje%",
                            style: TextStyle(
                              color: esRiesgo ? Colors.red : Colors.green.shade800,
                              fontSize: 11, fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        title: Text(est['nombre'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(est['matricula'], style: const TextStyle(fontSize: 12)),
                        trailing: _buildAcciones(est['id'], estadoHoy),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones(int id, String? estadoHoy) {
    if (estadoHoy == 'licencia') {
       return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C3D59) : Colors.blue.shade100, borderRadius: BorderRadius.circular(15)),
        child: Text("Licencia", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9ACDFF) : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _boton(estadoHoy, 'presente', Icons.check_circle, Colors.green, id),
        _boton(estadoHoy, 'atraso', Icons.access_time_filled, Colors.orange, id),
        _boton(estadoHoy, 'falta', Icons.cancel, Colors.red, id),
      ],
    );
  }

  Widget _boton(String? actual, String target, IconData icon, Color color, int id) {
    return IconButton(
      icon: Icon(icon),
      color: actual == target ? color : Theme.of(context).colorScheme.outline,
      iconSize: actual == target ? 30 : 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: _guardando || _isLoading || !_esHoy
          ? null : () => _cambiarEstado(id, target),
    );
  }
}