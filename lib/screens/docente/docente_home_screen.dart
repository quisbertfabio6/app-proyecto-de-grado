import 'dart:async'; // <-- NUEVO: Para manejar el flujo en segundo plano
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // <-- NUEVO: Escuchador de red
import '../../services/api_service.dart';
import '../../utils/database_helper.dart';
import '../login_screen.dart';
import 'detalle_curso_screen.dart';
import '../../utils/sound_manager.dart';
import '../../widgets/sita_dashboard_ui.dart';

class DocenteHomeScreen extends StatefulWidget {
  const DocenteHomeScreen({super.key});

  @override
  State<DocenteHomeScreen> createState() => _DocenteHomeScreenState();
}

class _DocenteHomeScreenState extends State<DocenteHomeScreen> {
  List<dynamic> _materias = [];
  bool _isLoading = true;
  int _pendientesOffline = 0;

  // --- NUEVAS VARIABLES PARA SINCRONIZACIÓN AUTOMÁTICA ---
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isSyncing =
      false; // Evita que se disparen múltiples sincronizaciones a la vez
  // -------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _iniciarListenerConectividad(); // <-- Iniciamos el vigía de internet
  }

  @override
  void dispose() {
    _connectivitySubscription
        .cancel(); // <-- Apagamos el vigía al cerrar la pantalla para no gastar batería
    super.dispose();
  }

  void _cargarDatos() async {
    final materias = await ApiService.getMateriasDocente();
    _verificarOffline();

    if (mounted) {
      setState(() {
        _materias = materias;
        _isLoading = false;
      });
    }
  }

  void _verificarOffline() async {
    final pendientes = await DatabaseHelper().getPendientes();
    if (mounted) {
      setState(() {
        _pendientesOffline = pendientes.length;
      });
    }
  }

  // --- INICIO NUEVA LÓGICA: Escuchador de Internet ---
  void _iniciarListenerConectividad() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      // Si el resultado NO es "none" (es decir, hay Wifi o Datos)
      if (!result.contains(ConnectivityResult.none)) {
        // Y si tenemos pendientes guardados y no estamos ya sincronizando...
        if (_pendientesOffline > 0 && !_isSyncing) {
          _sincronizar(enSegundoPlano: true); // ¡Magia! Se sincroniza solo.
        }
      }
    });
  }
  // --- FIN NUEVA LÓGICA ---

  // Modificamos la función para que acepte trabajar en "Segundo Plano"
  void _sincronizar({bool enSegundoPlano = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    // Si el usuario presionó el botón manualmente, bloqueamos la pantalla. Si es automático, no.
    if (!enSegundoPlano) {
      setState(() => _isLoading = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronizando datos con la nube...')),
      );
    }

    final cantidad = await ApiService.sincronizarPendientes();

    await Future.delayed(const Duration(seconds: 1));
    _verificarOffline();

    if (!enSegundoPlano && mounted) {
      setState(() => _isLoading = false);
    }

    // Solo mostramos mensaje de éxito si realmente subió algo
    if (cantidad > 0 && mounted) {
      SoundManager.playScan();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enSegundoPlano
                ? '¡Conexión recuperada! Se sincronizaron $cantidad registros automáticamente.'
                : 'Se sincronizaron $cantidad registros.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    _isSyncing = false;
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: _pendientesOffline > 0
          ? FloatingActionButton.extended(
              onPressed: _isLoading
                  ? null
                  : () => _sincronizar(enSegundoPlano: false),
              backgroundColor: const Color(0xFFF4A340),
              foregroundColor: sitaInk,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text('Sincronizar ($_pendientesOffline)'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
              children: [
                SitaHeroBanner(
                  section: 'DOCENTE',
                  title: 'Mis clases\ny asignaturas',
                  description:
                      'Accede a tus cursos y administra el registro de asistencia.',
                  counterLabel: '${_materias.length} materias asignadas',
                  icon: Icons.co_present_outlined,
                ),
                if (_pendientesOffline > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5E7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF9D9A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFFB66B0A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tienes $_pendientesOffline registros pendientes de sincronizar.',
                            style: const TextStyle(
                              color: Color(0xFF8A530F),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 29),
                const SitaSectionTitle(
                  title: 'Asignaturas a cargo',
                  subtitle: 'Selecciona una materia para ver sus estudiantes.',
                ),
                const SizedBox(height: 15),
                if (_materias.isEmpty)
                  const SitaEmptyPanel(
                    icon: Icons.menu_book_outlined,
                    title: 'No tienes materias asignadas',
                    description:
                        'Tus cursos aparecerán aquí cuando sean asignados.',
                  ),
                ..._materias.map((materia) {
                  final curso = materia['curso'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalleCursoScreen(
                                materiaId: materia['id'],
                                nombreMateria: materia['nombre'],
                                nombreCurso:
                                    "${curso['nombre']} (${curso['gestion']})",
                              ),
                            ),
                          );
                          // Se mantiene la revisión de registros sin conexión.
                          _verificarOffline();
                          if (_pendientesOffline > 0) {
                            final connectivityResult = await Connectivity()
                                .checkConnectivity();
                            if (!connectivityResult.contains(
                              ConnectivityResult.none,
                            )) {
                              _sincronizar(enSegundoPlano: true);
                            }
                          }
                        },
                        child: Ink(
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE8ECF2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: sitaRed.withAlpha(19),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: const Icon(
                                  Icons.auto_stories_outlined,
                                  color: sitaRed,
                                  size: 29,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      materia['nombre'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: sitaInk,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      "${curso['nombre']} · Gestión ${curso['gestion']}",
                                      style: const TextStyle(
                                        color: sitaMuted,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F0F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: sitaRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
