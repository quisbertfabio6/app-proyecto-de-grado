import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

  void _cargarLista() async {
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

  void _cambiarEstado(int id, String nuevoEstado) async {
    setState(() {
      final index = _estudiantes.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _estudiantes[index]['estado_hoy'] = nuevoEstado;
      }
    });

    await ApiService.registrarManual(
      estudianteId: id,
      materiaId: widget.materiaId,
      estado: nuevoEstado,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia'), 
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- BARRA DE FECHAS (CARRUSEL) ---
          Container(
            height: 60,
            color: Colors.indigo,
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
                        color: esSeleccionada ? Colors.indigo : Colors.white,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    selected: esSeleccionada,
                    selectedColor: Colors.white,
                    backgroundColor: Colors.indigo.shade700,
                    onSelected: (bool selected) {
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
            color: Colors.grey.shade200,
            child: Text(
              "Mostrando asistencia del: $_fechaSeleccionada",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
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
        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(15)),
        child: const Text("Licencia", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
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
      color: actual == target ? color : Colors.grey.shade300,
      iconSize: actual == target ? 30 : 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => _cambiarEstado(id, target),
    );
  }
}