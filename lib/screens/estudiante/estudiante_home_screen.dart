import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'licencia_form_screen.dart';
import 'mis_licencias_screen.dart';
import '../../widgets/sita_dashboard_ui.dart';

class EstudianteHomeScreen extends StatefulWidget {
  const EstudianteHomeScreen({super.key});

  @override
  State<EstudianteHomeScreen> createState() => _EstudianteHomeScreenState();
}

class _EstudianteHomeScreenState extends State<EstudianteHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _materias = []; 

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    setState(() => _isLoading = true);
    final materias = await ApiService.getMateriasEstudiante();
    
    if (mounted) {
      setState(() {
        _materias = materias;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: sitaInk,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, color: sitaRed, size: 27),
            SizedBox(width: 9),
            Text(
              'SITA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: sitaInk,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar materias',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarDatos,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                SitaHeroBanner(
                  section: 'ESTUDIANTE',
                  title: 'Mi rendimiento\nacadémico',
                  description:
                      'Consulta tus asistencias y gestiona tus solicitudes en un solo lugar.',
                  counterLabel: '${_materias.length} materias registradas',
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 27),
                const SitaSectionTitle(
                  title: 'Accesos rápidos',
                  subtitle: 'Tus gestiones más importantes, a un toque.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final unaColumna = constraints.maxWidth < 600;
                    final ancho = unaColumna
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: ancho,
                          child: SitaActionTile(
                            icon: Icons.note_add_outlined,
                            title: 'Pedir licencia',
                            subtitle: 'Nueva solicitud',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LicenciaFormScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: ancho,
                          child: SitaActionTile(
                            icon: Icons.assignment_outlined,
                            title: 'Mis trámites',
                            subtitle: 'Ver solicitudes',
                            accent: const Color(0xFF344E86),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MisLicenciasScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 29),
                const SitaSectionTitle(
                  title: 'Mis materias',
                  subtitle: 'Seguimiento de asistencia por asignatura.',
                ),
                const SizedBox(height: 15),
                if (_materias.isEmpty)
                  const SitaEmptyPanel(
                    icon: Icons.menu_book_outlined,
                    title: 'Todavía no hay materias',
                    description:
                        'Tus asignaturas aparecerán aquí cuando estén disponibles.',
                  ),
                ..._materias.map((materia) {
                  final porcentaje = materia['porcentaje'];
                  final esRiesgo = materia['riesgo'];
                  final colorEstado = esRiesgo
                      ? const Color(0xFFB42318)
                      : const Color(0xFF15803D);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 13),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: esRiesgo
                            ? const Color(0xFFF3C2BE)
                            : const Color(0xFFE8ECF2),
                      ),
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
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sitaRed.withAlpha(18),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.auto_stories_outlined,
                                color: sitaRed,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                materia['nombre'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: sitaInk,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: colorEstado.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$porcentaje%',
                                style: TextStyle(
                                  color: colorEstado,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 21),
                        Row(
                          children: [
                            const Text(
                              'Asistencia',
                              style: TextStyle(
                                color: sitaInk,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                "${materia['asistencias_puntos']} de ${materia['total_clases']} clases",
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: sitaMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: porcentaje / 100,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFEDF0F5),
                            color: colorEstado,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              esRiesgo
                                  ? Icons.info_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 16,
                              color: colorEstado,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                esRiesgo
                                    ? 'Asistencia en riesgo'
                                    : 'Seguimiento de asistencia',
                                style: TextStyle(
                                  color: colorEstado,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
