import 'package:flutter/material.dart';

class DashboardDriver extends StatelessWidget {
  const DashboardDriver({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("dashboard_driver.dart")),
      body: const Center(child: Text("Bienvenido, Conductor!")),//todo mostrar el nombre del conductor
      //todo mostrar datos del vehiculo (placa, modelo, kilometraje(variable) )--->policies backend
      //todo mostrar peticiones para unirse a organizaciones--->policies backend
      //todo dropdown list para selecionar la ruta deseada--->policies backend
      //todo boton para comenzar ruta del dia--->policies backend
      //todo boton de emergencia/ayuda/reporte--->new table + triggers backend
    );
  }
}