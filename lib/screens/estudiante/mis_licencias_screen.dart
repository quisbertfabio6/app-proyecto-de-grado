import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MisLicenciasScreen extends StatefulWidget {
  const MisLicenciasScreen({super.key});

  @override
  State<MisLicenciasScreen> createState() => _MisLicenciasScreenState();
}

class _MisLicenciasScreenState extends State<MisLicenciasScreen> {
  List<dynamic> _licencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final datos = await ApiService.getMisLicencias();
    if (mounted) {
      setState(() {
        _licencias = datos;
        _isLoading = false;
      });
    }
  }

  // Función para borrar
  void _anularSolicitud(int id) async {
    // Diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Anular Solicitud?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí, Anular", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      final result = await ApiService.anularLicencia(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ));
        _cargarDatos(); // Recargar lista
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trámites'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _licencias.isEmpty
              ? const Center(child: Text('No tienes solicitudes enviadas'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _licencias.length,
                  itemBuilder: (context, index) {
                    final lic = _licencias[index];
                    final esPendiente = lic['estado'] == 'pendiente';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: _getIconoEstado(lic['estado']),
                        title: Text(lic['motivo'] ?? 'Sin motivo', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Fechas: ${lic['fecha_inicio']} al ${lic['fecha_fin']}"),
                            if (lic['comentario_admin'] != null)
                              Text(
                                "Obs: ${lic['comentario_admin']}",
                                style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        // SI ES PENDIENTE: Botón de Borrar. SI NO: Chip de Estado.
                        trailing: esPendiente
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Anular Solicitud',
                                onPressed: () => _anularSolicitud(lic['id']),
                              )
                            : _getTagEstado(lic['estado']),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _getIconoEstado(String estado) {
    switch (estado) {
      case 'aprobada': return const Icon(Icons.check_circle, color: Colors.green, size: 30);
      case 'rechazada': return const Icon(Icons.cancel, color: Colors.red, size: 30);
      default: return const Icon(Icons.access_time_filled, color: Colors.orange, size: 30);
    }
  }

  Widget _getTagEstado(String estado) {
    Color color;
    switch (estado) {
      case 'aprobada': color = Colors.green; break;
      case 'rechazada': color = Colors.red; break;
      default: color = Colors.orange; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: color)),
      child: Text(estado.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}