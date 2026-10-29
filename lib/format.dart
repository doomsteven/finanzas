import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Cambia el símbolo aquí si quieres otra moneda (por ejemplo 'S/ ' o '€').
final _moneda = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2);

String dinero(double valor) => _moneda.format(valor);

String mesTexto(DateTime mes) {
  final texto = DateFormat('MMMM yyyy', 'es').format(mes);
  return texto[0].toUpperCase() + texto.substring(1);
}

String fechaLarga(DateTime d) {
  final texto = DateFormat('EEEE d MMM', 'es').format(d);
  return texto[0].toUpperCase() + texto.substring(1);
}

String fechaCorta(DateTime d) => DateFormat('d MMM', 'es').format(d);

const colorIngreso = Color(0xFF43A047);
const colorGasto = Color(0xFFE53935);
