import 'package:flutter/material.dart';
import 'screens/formulario.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Usuarios',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Formulario(),
    );
  }
}
