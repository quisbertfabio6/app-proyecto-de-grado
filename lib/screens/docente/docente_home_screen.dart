import 'dart:async'; // <-- NUEVO: Para manejar el flujo en segundo plano
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // <-- NUEVO: Escuchador de red
import '../../services/api_service.dart';
import '../../utils/database_helper.dart';
import '../login_screen.dart';
import 'detalle_curso_screen.dart';
import '../../utils/sound_manager.dart';

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
        title: const Text('Mis Clases'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),

      floatingActionButton: _pendientesOffline > 0
          ? FloatingActionButton.extended(
              onPressed: _isLoading
                  ? null
                  : () => _sincronizar(enSegundoPlano: false),
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.cloud_upload),
              label: Text('Sincronizar ($_pendientesOffline)'),
            )
          : null,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materias.isEmpty
          ? const Center(child: Text('No tienes materias asignadas'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _materias.length,
              itemBuilder: (context, index) {
                final materia = _materias[index];
                final curso = materia['curso'];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.book, color: Colors.white),
                    ),
                    title: Text(
                      materia['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text("${curso['nombre']} (${curso['gestion']})"),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 20,
                    ),
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
                      // Al volver de escanear, verificamos si se guardó algo offline para mostrar el botón
                      _verificarOffline();

                      // Intentamos forzar una revisión de red por si el internet volvió justo al salir de la cámara
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
                  ),
                );
              },
            ),
    );
  }
}
