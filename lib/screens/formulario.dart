import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';
import '../helpers/basedatos_helper.dart';
import 'package:uuid/uuid.dart';

class Formulario extends StatefulWidget {
  const Formulario({super.key});

  @override
  FormularioState createState() => FormularioState();
}

class FormularioState extends State<Formulario> {
  // Controladores para los campos de texto en el formulario de registro
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  // Variables de estado para mostrar errores de validación en los campos del formulario
  String _nombreError = '';
  String _correoError = '';
  String _fechaError = '';
  String _direccionError = '';
  String _contrasenaError = '';
  String _mensajeRegistro = '';

  List<Usuario> _usuarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  // MÉTODOS ASINCRÓNICOS

  /// Abre un cuadro de diálogo para seleccionar una fecha utilizando [showDatePicker]
  ///
  /// - [context] es el contexto actual de la aplicación, requerido para mostrar el selector de fecha
  ///
  /// Parámetros de [showDatePicker]:
  /// - `initialDate`: La fecha que se muestra inicialmente en el selector, en este caso la fecha actual
  /// - `firstDate`: La fecha mínima seleccionable, en este caso el 1 de enero de 1900
  /// - `lastDate`: La fecha máxima seleccionable, en este caso la fecha actual
  ///
  /// Si el usuario selecciona una fecha válida, se actualiza el campo de texto asociado a [_fechaController]
  /// con la fecha seleccionada, formateada mediante [_formatDate]
  ///
  /// Luego se utiliza [setState] para asegurarse de que la interfaz de usuario refleje el cambio en el campo de fecha
  Future<void> _seleccionFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaController.text = _formatDate(picked);
      });
    }
  }

  /// Obtiene datos de una API externa y actualiza los campos de la interfaz con la información recibida
  ///
  /// Esta función realiza una solicitud HTTP GET a la API [https://randomuser.me/api/] y, si la respuesta es exitosa (código de estado 200):
  /// - Limpia los mensajes de error previos mediante [_limpiarErrores]
  /// - Activa el estado de carga mientras se realiza la solicitud con [_setLoading]
  /// - Si la solicitud es exitosa, los datos obtenidos se procesan y se actualizan en los campos mediante [_actualizarCamposConDatos]
  /// - Si ocurre un error, el código de estado o el mensaje de error se imprime en la consola
  /// - Finalmente, desactiva el estado de carga en ambos casos
  Future<void> obtenerDatosDeApi() async {
    _limpiarErrores();
    _setLoading(true);

    try {
      final response = await http.get(Uri.parse('https://randomuser.me/api/'));
      if (response.statusCode == 200) {
        _actualizarCamposConDatos(jsonDecode(response.body));
      } else {
        _mensajeRegistro = 'Error al obtener datos: ${response.statusCode}';
      }
    } catch (e) {
      _mensajeRegistro = 'Error al obtener datos: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Agrega un nuevo usuario a la base de datos, si los campos son válidos y el correo no está registrado
  ///
  /// Esta función realiza varias operaciones en el siguiente orden:
  /// 1. Limpia cualquier mensaje de error previo
  /// 2. Valida los campos ingresados. Si no son válidos, la función se detiene
  /// 3. Crea una instancia de la base de datos utilizando [BaseDatosHelper]
  /// 4. Verifica si el correo ya está registrado. Si es así, la función se detiene
  /// 5. Crea un objeto [Usuario] con los datos proporcionados por los controladores de texto
  /// 6. Inserta el usuario en la base de datos
  /// 7. Muestra un mensaje de éxito y recarga la lista de usuarios registrados
  /// 8. Limpia los campos de entrada después de completar el registro
  Future<void> _agregarUsuario() async {
    _limpiarErrores();

    if (!_validarCampos()) return;

    final db = BaseDatosHelper();
    if (await _existeCorreoRegistrado(db)) return;

    final usuario = Usuario(
      id: Uuid().v4(),
      nombre: _nombreController.text,
      correo: _correoController.text,
      fechaNacimiento: _fechaController.text,
      direccion: _direccionController.text,
      contrasena: _contrasenaController.text,
    );

    await db.insertarUsuario(usuario);
    _mensajeRegistro = 'Usuario registrado con éxito';
    _cargarUsuarios();
    _limpiarCampos();
  }

  /// Carga la lista de usuarios desde la base de datos y actualiza el estado del widget
  ///
  /// Esta función interactúa con la base de datos para obtener los usuarios
  /// previamente registrados utilizando el método [BaseDatosHelper.obtenerUsuarios] de la clase [BaseDatosHelper].
  /// Luego, actualiza el estado del widget almacenando los usuarios obtenidos en la lista [_usuarios].
  ///
  /// Al completar la operación, actualiza el estado de la aplicación utilizando [setState] para que los cambios
  /// se reflejen en la interfaz de usuario.
  ///
  Future<void> _cargarUsuarios() async {
    final db = BaseDatosHelper();
    final usuarios = await db.obtenerUsuarios();
    setState(() {
      _usuarios = usuarios;
    });
  }

  // VALIDACIONES

  /// Valida los campos del formulario
  ///
  /// - Devuelve `true` si todos los campos cumplen con las reglas de validación
  ///   y `false` si al menos uno de los campos no es válido
  ///
  /// Validaciones realizadas:
  /// - El nombre debe tener al menos 3 caracteres y contener solo letras y espacios.
  ///   Si no se cumple, se asigna un mensaje de error a [_nombreError]
  /// - El correo debe cumplir con un formato válido de email utilizando [RegExp].
  ///   Si no se cumple, se asigna un mensaje de error a [_correoError]
  /// - La fecha de nacimiento no puede estar vacía.
  ///   Si no se cumple, se asigna un mensaje de error a [_fechaError]
  /// - La dirección no puede estar vacía.
  ///   Si no se cumple, se asigna un mensaje de error a [_direccionError]
  /// - La contraseña debe tener al menos 6 caracteres.
  ///   Si no se cumple, se asigna un mensaje de error a [_contrasenaError]
  ///
  /// Después de realizar las validaciones, llama a [setState] para actualizar
  /// los mensajes de error en el estado de la interfaz de usuario
  bool _validarCampos() {
    bool esValido = true;

    if (_nombreController.text.isEmpty ||
        _nombreController.text.length < 3 ||
        !_nombreController.text
            .contains(RegExp(r'^[\p{L}\s]+$', unicode: true))) {
      _nombreError =
          'El nombre debe tener al menos 3 caracteres y solo letras.';
      esValido = false;
    }

    RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(_correoController.text)) {
      _correoError = 'Por favor, ingrese un correo electrónico válido.';
      esValido = false;
    }

    if (_fechaController.text.isEmpty) {
      _fechaError = 'Por favor, seleccione la fecha de nacimiento';
      esValido = false;
    }

    if (_direccionController.text.isEmpty) {
      _direccionError = 'Por favor, ingrese la dirección';
      esValido = false;
    }

    if (_contrasenaController.text.length < 6) {
      _contrasenaError = 'La contraseña debe tener al menos 6 caracteres';
      esValido = false;
    }

    setState(() {});
    return esValido;
  }

  /// Verifica si el correo ingresado ya está registrado en la base de datos
  ///
  /// - [db] es una instancia de [BaseDatosHelper] que permite acceder a los usuarios almacenados
  /// - Se obtiene una lista de todos los usuarios registrados llamando a [obtenerUsuarios]
  /// - Luego se utiliza [any] para verificar si algún usuario en la lista tiene un correo
  ///   que coincida con el correo ingresado en el controlador [_correoController]
  /// - Si se encuentra un correo duplicado, se actualiza el estado de [_correoError]
  ///   con un mensaje de error y se retorna `true`
  /// - Si no hay coincidencias, se retorna `false`, indicando que el correo no está registrado
  Future<bool> _existeCorreoRegistrado(BaseDatosHelper db) async {
    final usuariosExistentes = await db.obtenerUsuarios();
    final existeCorreo = usuariosExistentes.any(
      (usuario) => usuario.correo == _correoController.text,
    );

    if (existeCorreo) {
      setState(() {
        _correoError = 'Este correo electrónico ya está registrado';
      });
      return true;
    }
    return false;
  }

  // MÉTODOS UTILITARIOS

  /// Limpia los mensajes de error en el formulario
  void _limpiarErrores() {
    setState(() {
      _nombreError = '';
      _correoError = '';
      _fechaError = '';
      _direccionError = '';
      _contrasenaError = '';
      _mensajeRegistro = '';
    });
  }

  /// Establece el estado de carga para mostrar un indicador mientras se procesan las tareas
  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  //Limpia los campos del formulario
  void _limpiarCampos() {
    _nombreController.clear();
    _correoController.clear();
    _fechaController.clear();
    _direccionController.clear();
    _contrasenaController.clear();
  }

  /// Formatea la fecha en el formato `YYYY-MM-DD`
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Actualiza los campos del formulario con los datos obtenidos de la API
  ///
  /// - [data] es la respuesta JSON recibida de la API, se espera que contenga
  ///   información de un usuario en la clave 'results'
  /// - Dentro de [setState], se extrae el primer resultado del array 'results'
  ///   y se asignan valores a los controladores de texto del formulario:
  ///   - [_nombreController] se actualiza con el nombre completo del usuario concatenando
  ///     el primer nombre y el apellido
  ///   - [_correoController] se asigna con el correo electrónico del usuario
  ///   - [_fechaController] se establece con la fecha de nacimiento del usuario,
  ///     tomando solo los primeros 10 caracteres del campo 'dob' para obtener el formato de fecha
  ///   - [_direccionController] se actualiza con el número y nombre de la calle del usuario
  ///   - [_contrasenaController] se fija con un valor predeterminado de '12345678'
  ///
  /// Este método asegura que los campos del formulario sean actualizados cuando
  /// se reciben nuevos datos de usuario
  void _actualizarCamposConDatos(dynamic data) {
    setState(() {
      var user = data['results'][0];
      _nombreController.text =
          '${user['name']['first']} ${user['name']['last']}';
      _correoController.text = user['email'];
      _fechaController.text = user['dob']['date'].substring(0, 10);
      _direccionController.text =
          '${user['location']['street']['number']} ${user['location']['street']['name']}';
      _contrasenaController.text = '12345678';
    });
  }

  // INTERFAZ DE USUARIO

  /// Este Sobrescribe el método [build] para construir la interfaz de usuario
  /// - Utiliza un [Scaffold] como contenedor principal de la pantalla
  /// - Dentro del cuerpo hay una columna que contiene los siguientes widgets:
  ///   - Si [_mensajeRegistro] no está vacío, se muestra el mensaje de registro exitoso mediante [_mostrarMensajeRegistro]
  ///   - [_buildForm] construye el formulario de registro que incluye varios campos
  ///   - [_buildBotones] genera los botones del formulario, como el botón de enviar o limpiar
  ///   - [_buildDataTable] genera una tabla que muestra la lista de usuarios registrados
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Usuario',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_mensajeRegistro.isNotEmpty) _mostrarMensajeRegistro(),
            _buildForm(),
            const SizedBox(height: 20),
            _buildBotones(),
            const SizedBox(height: 20),
            _buildDataTable(),
          ],
        ),
      ),
    );
  }

  /// Construye el formulario con los diferentes campos
  ///
  /// - Utiliza un [Column] para organizar los elementos del formulario en una sola columna
  /// - Cada campo del formulario se construye usando la función [_buildTextField] para crear entradas de texto y [_buildDateField] para la fecha de nacimiento
  /// - Los campos incluyen:
  ///   - 'Nombre completo': Entrada de texto controlada por [_nombreController] y con posibles errores mostrados en [_nombreError]
  ///   - 'Correo electrónico': Entrada de texto controlada por [_correoController] y con posibles errores mostrados en [_correoError]
  ///   - 'Fecha de nacimiento': Campo de selección de fecha gestionado por [_buildDateField]
  ///   - 'Dirección': Entrada de texto controlada por [_direccionController] y con posibles errores mostrados en [_direccionError]
  ///   - 'Contraseña': Entrada de texto controlada por [_contrasenaController] con enmascaramiento (al ser una contraseña), y posibles errores mostrados en [_contrasenaError]
  ///
  /// - El parámetro opcional [isPassword] permite que el campo de la contraseña oculte el texto ingresado
  ///
  /// Retorna una columna que contiene los campos del formulario
  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField('Nombre completo', _nombreController, _nombreError),
        _buildTextField('Correo electrónico', _correoController, _correoError),
        _buildDateField(),
        _buildTextField('Dirección', _direccionController, _direccionError),
        _buildTextField('Contraseña', _contrasenaController, _contrasenaError,
            isPassword: true),
      ],
    );
  }

  /// Construye los campos de texto para el formulario
  Widget _buildTextField(
      String label, TextEditingController controller, String error,
      {bool isPassword = false}) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
              labelText: label,
              errorText: error.isNotEmpty ? error : null,
              labelStyle: const TextStyle(color: Colors.blue)),
          obscureText: isPassword,
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  /// Crea un campo de texto para que el usuario seleccione su fecha de nacimiento
  ///
  /// Este widget es básicamente un campo que el usuario puede tocar para elegir
  /// su fecha de nacimiento. Cuando se toca el campo, llama a la función
  /// [_seleccionFecha] para abrir un selector de fechas
  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _seleccionFecha(context),
      child: AbsorbPointer(
        child: TextField(
          controller: _fechaController,
          decoration: InputDecoration(
            labelText: 'Fecha de Nacimiento',
            suffixIcon: const Icon(Icons.calendar_today),
            errorText: _fechaError.isNotEmpty ? _fechaError : null,
            labelStyle: const TextStyle(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  /// Construye un widget de columna que contiene dos botones de acción
  ///
  /// - **Registrar**: Al hacer clic en este botón, se invoca la función
  ///   [_agregarUsuario] para manejar la lógica de registro de un nuevo usuario
  ///
  /// - **Obtener desde API**: Este botón llama a la función [obtenerDatosDeApi],
  ///   para obtener los datos del usuario. El parámetro
  ///   `isLoading` controla si el botón debe mostrar un estado de carga
  ///   mientras se espera la respuesta de la API
  Widget _buildBotones() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildSubmitButton('Registrar', _agregarUsuario),
        const SizedBox(height: 10),
        _buildSubmitButton('Obtener desde API', obtenerDatosDeApi,
            isLoading: _isLoading),
      ],
    );
  }

  /// Construye un botón de envío con funcionalidad de carga opcional
  ///
  /// [text] es el texto que aparecerá en el botón
  /// [onPressed] es la función que se ejecutará cuando se presione el botón
  /// [isLoading] indica si debe mostrarse un indicador de carga en lugar del texto (por defecto es `false`)
  Widget _buildSubmitButton(String text, Function onPressed,
      {bool isLoading = false}) {
    return ElevatedButton(
      onPressed: () => onPressed(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      child: isLoading
          ? const CircularProgressIndicator()
          : Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  /// Construye una tabla para mostrar los usuarios registrados
  /// - Utiliza [DataTable] para mostrar los datos en un formato de tabla
  /// - La tabla tiene tres columnas: Nombre, Correo, y Fecha de Nacimiento, con estilos personalizados para los encabezados
  /// - El contenido de la tabla se genera dinámicamente a partir de la lista de usuarios [_usuarios] utilizando [DataRow] y [DataCell] para cada fila
  /// - La tabla está envuelta en dos [SingleChildScrollView] para permitir el desplazamiento horizontal y vertical si el contenido excede el tamaño disponible
  /// - [Expanded] permite que la tabla se expanda para ocupar el espacio disponible dentro de un layout flexible
  Widget _buildDataTable() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blue),
            columnSpacing: 15.0,
            columns: const [
              DataColumn(
                label: Text('Nombre',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              DataColumn(
                label: Text('Correo',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              DataColumn(
                label: Text('Fecha de Nacimiento',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
            rows: _usuarios
                .map((usuario) => DataRow(cells: [
                      DataCell(Text(usuario.nombre)),
                      DataCell(Text(usuario.correo)),
                      DataCell(Text(usuario.fechaNacimiento)),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }

  /// Muestra un mensaje en caso de éxito al registrar un usuario
  Widget _mostrarMensajeRegistro() {
    return Text(
      _mensajeRegistro,
      style: const TextStyle(color: Colors.green, fontSize: 16),
    );
  }
}
