/// Clase que representa un usuario en la aplicación.
/// Esta clase contiene la información básica de un usuario,
/// incluyendo su identificación, nombre, correo electrónico,
/// fecha de nacimiento, dirección y contraseña.
class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String fechaNacimiento;
  final String direccion;
  final String contrasena;

  /// Constructor que inicializa los campos de la clase [Usuario].
  /// - [id]: El identificador único del usuario.
  /// - [nombre]: El nombre completo del usuario.
  /// - [correo]: El correo electrónico del usuario.
  /// - [fechaNacimiento]: La fecha de nacimiento del usuario.
  /// - [direccion]: La dirección del usuario.
  /// - [contrasena]: La contraseña del usuario.
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.fechaNacimiento,
    required this.direccion,
    required this.contrasena,
  });

  /// Convierte la instancia de [Usuario] a un mapa que puede ser almacenado en la base de datos.
  /// - Retorna un [Map] que contiene las propiedades del usuario.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'fechaNacimiento': fechaNacimiento,
      'direccion': direccion,
      'contrasena': contrasena,
    };
  }

  /// Crea una instancia de [Usuario] a partir de un mapa.
  /// - [map]: Un [Map] que contiene las propiedades del usuario.
  /// - Retorna una nueva instancia de [Usuario] con los valores del mapa.
  static Usuario fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nombre: map['nombre'],
      correo: map['correo'],
      fechaNacimiento: map['fechaNacimiento'],
      direccion: map['direccion'],
      contrasena: map['contrasena'],
    );
  }
}
