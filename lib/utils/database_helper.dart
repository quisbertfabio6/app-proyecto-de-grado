import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 1. Inicializar la Base de Datos Local
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sita_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Creamos la tabla para guardar asistencias pendientes
        return db.execute(
          'CREATE TABLE asistencias_offline('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'codigo_qr TEXT, '
          'materia_id INTEGER, '
          'fecha TEXT, '
          'hora TEXT, '
          'nombre_materia TEXT' // Guardamos el nombre solo para mostrarlo en la lista
          ')',
        );
      },
    );
  }

  // 2. Guardar una asistencia offline
  Future<int> insertarAsistencia({
    required String codigoQr,
    required int materiaId,
    required String nombreMateria,
  }) async {
    final db = await database;
    final now = DateTime.now();
    
    // Formato fecha/hora igual que Laravel
    final fecha = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final hora = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return await db.insert('asistencias_offline', {
      'codigo_qr': codigoQr,
      'materia_id': materiaId,
      'fecha': fecha,
      'hora': hora,
      'nombre_materia': nombreMateria,
    });
  }

  // 3. Obtener todas las pendientes (para sincronizar luego)
  Future<List<Map<String, dynamic>>> getPendientes() async {
    final db = await database;
    return await db.query('asistencias_offline');
  }

  // 4. Borrar una asistencia (cuando ya se sincronizó)
  Future<void> borrarAsistencia(int id) async {
    final db = await database;
    await db.delete('asistencias_offline', where: 'id = ?', whereArgs: [id]);
  }
  
  // Borrar todo (opcional)
  Future<void> borrarTodo() async {
    final db = await database;
    await db.delete('asistencias_offline');
  }
}