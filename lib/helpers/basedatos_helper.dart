import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/usuario.dart';

/// Clase que ayuda a gestionar la base de datos de usuarios
class BaseDatosHelper {
  /// Instancia única de la clase [BaseDatosHelper]
  static final BaseDatosHelper _instance = BaseDatosHelper._internal();

  /// Instancia de la base de datos
  static Database? _database;

  /// Constructor interno para implementar el patrón Singleton
  BaseDatosHelper._internal();

  /// Constructor factory que retorna la única instancia de [BaseDatosHelper]
  factory BaseDatosHelper() {
    return _instance;
  }

  /// Getter que devuelve la base de datos inicializada, si ya existe, la retorna,
  /// de lo contrario, la inicializa
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _inicializarBaseDatos();
    return _database!;
  }

  /// Inicializa la base de datos y crea la tabla de usuarios si no existe
  Future<Database> _inicializarBaseDatos() async {
    String path = join(await getDatabasesPath(), 'usuarios.db');
    return await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute('''
        CREATE TABLE usuarios(
          id TEXT PRIMARY KEY, 
          nombre TEXT, 
          correo TEXT, 
          fechaNacimiento TEXT, 
          direccion TEXT, 
          contrasena TEXT
        );
      ''');
      },
      version: 1,
    );
  }

  /// Inserta un usuario en la tabla de usuarios. Si ya existe, reemplaza el registro
  /// - [usuario]: El objeto [Usuario] que será insertado en la base de datos
  Future<void> insertarUsuario(Usuario usuario) async {
    final db = await database;
    await db.insert(
      'usuarios',
      usuario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todos los usuarios de la tabla de usuarios y los devuelve como una lista
  ///
  /// Retorna una lista de objetos [Usuario]
  Future<List<Usuario>> obtenerUsuarios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('usuarios');

    return List.generate(maps.length, (i) {
      return Usuario.fromMap(maps[i]);
    });
  }
}
