import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/sita_dashboard_ui.dart';

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
        backgroundColor: sitaSurfaceFor(context),
        foregroundColor: sitaInkFor(context),
        title: const Text(
          'Mis trámites',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              itemCount: _licencias.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SitaHeroBanner(
                        section: 'LICENCIAS',
                        title: 'Mis solicitudes',
                        description:
                            'Consulta el estado de los trámites que enviaste.',
                        counterLabel: '${_licencias.length} solicitudes',
                        icon: Icons.assignment_turned_in_outlined,
                      ),
                      const SizedBox(height: 27),
                      const SitaSectionTitle(
                        title: 'Historial',
                        subtitle: 'Revisa las fechas y el estado de tus licencias.',
                      ),
                      const SizedBox(height: 15),
                      if (_licencias.isEmpty)
                        const SitaEmptyPanel(
                          icon: Icons.inbox_outlined,
                          title: 'Todavía no tienes solicitudes',
                          description:
                              'Cuando envíes una licencia, aparecerá aquí.',
                        ),
                    ],
                  );
                }

                final lic = _licencias[index - 1];
                final esPendiente = lic['estado'] == 'pendiente';

                return Container(
                  margin: const EdgeInsets.only(bottom: 13),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: sitaSurfaceFor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sitaBorderFor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF23334A).withAlpha(10),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: sitaIsDark(context) ? const Color(0xFF28374A) : const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _getIconoEstado(lic['estado']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lic['motivo'] ?? 'Sin motivo',
                              style: TextStyle(
                                color: sitaInkFor(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _getTagEstado(lic['estado']),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 17,
                            color: sitaMutedFor(context),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              "Fechas: ${lic['fecha_inicio']} al ${lic['fecha_fin']}",
                              style: TextStyle(
                                color: sitaMutedFor(context),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (lic['comentario_admin'] != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Obs: ${lic['comentario_admin']}",
                          style: TextStyle(
                            color: sitaIsDark(context) ? const Color(0xFFFF8A80) : const Color(0xFFB42318),
                            fontStyle: FontStyle.italic,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (esPendiente) ...[
                        const Divider(height: 25),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _anularSolicitud(lic['id']),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Anular solicitud'),
                            style: TextButton.styleFrom(
                              foregroundColor: sitaIsDark(context) ? const Color(0xFFFF8A80) : const Color(0xFFB42318),
                            ),
                          ),
                        ),
                      ],
                    ],
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