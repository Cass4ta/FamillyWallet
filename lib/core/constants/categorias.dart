import 'package:flutter/material.dart';

class Categoria {
  final String id;
  final String nombre;
  final IconData icono;
  final Color color;
  const Categoria({required this.id, required this.nombre, required this.icono, required this.color});
}

const List<Categoria> categorias = [
  Categoria(id: 'comida', nombre: 'Comida', icono: Icons.restaurant, color: Colors.orange),
  Categoria(id: 'transporte', nombre: 'Transporte', icono: Icons.directions_car, color: Colors.blue),
  Categoria(id: 'hogar', nombre: 'Hogar', icono: Icons.home, color: Colors.green),
  Categoria(id: 'salud', nombre: 'Salud', icono: Icons.medical_services, color: Colors.red),
  Categoria(id: 'servicios', nombre: 'Servicios', icono: Icons.receipt_long, color: Colors.purple),
  Categoria(id: 'otros', nombre: 'Otros', icono: Icons.more_horiz, color: Colors.grey),
  Categoria(id: 'ingresos', nombre: 'Ingresos', icono: Icons.attach_money, color: Colors.teal),
];

Categoria getCategoriaById(String id) {
  return categorias.firstWhere(
    (c) => c.id == id,
    orElse: () => categorias.firstWhere((c) => c.id == 'otros')
  );
}
