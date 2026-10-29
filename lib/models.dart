import 'dart:math';

import 'package:flutter/material.dart';

enum TipoMovimiento { ingreso, gasto }

/// Un ingreso o gasto registrado en una fecha concreta.
class Movimiento {
  Movimiento({
    this.id,
    required this.tipo,
    required this.monto,
    required this.categoria,
    this.descripcion = '',
    required this.fecha,
    this.gastoFijoId,
    this.creditoId,
    this.trabajoId,
  });

  final int? id;
  final TipoMovimiento tipo;
  final double monto;
  final String categoria;
  final String descripcion;
  final DateTime fecha;

  /// Si el movimiento es el pago de un gasto fijo, su id.
  final int? gastoFijoId;

  /// Si es la cuota de un crédito, su id.
  final int? creditoId;

  /// Si es un cobro (anticipo o pago) de un trabajo, su id.
  final int? trabajoId;

  bool get esGasto => tipo == TipoMovimiento.gasto;

  /// Gasto del día a día: no es un fijo ni una cuota (esos ya están en el plan).
  bool get esLibre => gastoFijoId == null && creditoId == null;

  String get titulo => descripcion.isEmpty ? categoria : descripcion;

  Map<String, Object?> toMap() => {
        'id': id,
        'tipo': tipo.name,
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': fechaIso(fecha),
        'gasto_fijo_id': gastoFijoId,
        'credito_id': creditoId,
        'trabajo_id': trabajoId,
      };

  factory Movimiento.fromMap(Map<String, Object?> m) => Movimiento(
        id: m['id'] as int,
        tipo: TipoMovimiento.values.byName(m['tipo'] as String),
        monto: (m['monto'] as num).toDouble(),
        categoria: m['categoria'] as String,
        descripcion: m['descripcion'] as String,
        fecha: DateTime.parse(m['fecha'] as String),
        gastoFijoId: m['gasto_fijo_id'] as int?,
        creditoId: m['credito_id'] as int?,
        trabajoId: m['trabajo_id'] as int?,
      );
}

/// Fecha de un día de pago dentro del mes dado (ajusta el día 31 en meses cortos).
DateTime diaEnMes(int dia, DateTime mes) {
  final diasDelMes = DateTime(mes.year, mes.month + 1, 0).day;
  return DateTime(mes.year, mes.month, min(dia, diasDelMes));
}

/// Un pago que se repite cada mes con el mismo monto (alquiler, luz, internet...).
class GastoFijo {
  GastoFijo({
    this.id,
    required this.nombre,
    required this.monto,
    required this.categoria,
    required this.diaPago,
    this.activo = true,
  });

  final int? id;
  final String nombre;
  final double monto;
  final String categoria;
  final int diaPago;
  final bool activo;

  DateTime vencimientoEn(DateTime mes) => diaEnMes(diaPago, mes);

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'monto': monto,
        'categoria': categoria,
        'dia_pago': diaPago,
        'activo': activo ? 1 : 0,
      };

  factory GastoFijo.fromMap(Map<String, Object?> m) => GastoFijo(
        id: m['id'] as int,
        nombre: m['nombre'] as String,
        monto: (m['monto'] as num).toDouble(),
        categoria: m['categoria'] as String,
        diaPago: m['dia_pago'] as int,
        activo: m['activo'] == 1,
      );
}

/// Tope mensual para una categoría de gasto (ej. Alimentación $100).
/// Cada gasto de esa categoría se descuenta; empieza de cero cada mes.
class Presupuesto {
  Presupuesto({this.id, required this.categoria, required this.monto});

  final int? id;
  final String categoria;
  final double monto;

  Map<String, Object?> toMap() =>
      {'id': id, 'categoria': categoria, 'monto': monto};

  factory Presupuesto.fromMap(Map<String, Object?> m) => Presupuesto(
        id: m['id'] as int,
        categoria: m['categoria'] as String,
        monto: (m['monto'] as num).toDouble(),
      );
}

/// Crédito que se paga en cuotas mensuales (electrodomésticos, banco...).
/// Cada cuota pagada es un gasto del mes.
class Credito {
  Credito({
    this.id,
    required this.nombre,
    required this.cuota,
    required this.numCuotas,
    this.cuotasPrevias = 0,
    required this.diaPago,
    required this.inicio,
    this.nota = '',
  });

  final int? id;
  final String nombre;
  final double cuota;
  final int numCuotas;

  /// Cuotas que ya estaban pagadas antes de registrarlo en la app.
  final int cuotasPrevias;
  final int diaPago;

  /// Primer mes en que aparece en el plan.
  final DateTime inicio;
  final String nota;

  double get total => cuota * numCuotas;

  DateTime vencimientoEn(DateTime mes) => diaEnMes(diaPago, mes);

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'cuota': cuota,
        'num_cuotas': numCuotas,
        'cuotas_previas': cuotasPrevias,
        'dia_pago': diaPago,
        'inicio': fechaIso(inicio),
        'nota': nota,
      };

  factory Credito.fromMap(Map<String, Object?> m) => Credito(
        id: m['id'] as int,
        nombre: m['nombre'] as String,
        cuota: (m['cuota'] as num).toDouble(),
        numCuotas: m['num_cuotas'] as int,
        cuotasPrevias: m['cuotas_previas'] as int,
        diaPago: m['dia_pago'] as int,
        inicio: DateTime.parse(m['inicio'] as String),
        nota: m['nota'] as String,
      );
}

enum EstadoTrabajo { cotizado, enCurso, terminado }

const nombresEstado = {
  EstadoTrabajo.cotizado: 'Cotizado',
  EstadoTrabajo.enCurso: 'En curso',
  EstadoTrabajo.terminado: 'Terminado',
};

/// Un proyecto o presupuesto para un cliente. Lo cobrado son ingresos del mes.
class Trabajo {
  Trabajo({
    this.id,
    required this.cliente,
    this.descripcion = '',
    required this.monto,
    required this.estado,
    required this.fecha,
    this.entrega,
    this.nota = '',
  });

  final int? id;
  final String cliente;
  final String descripcion;
  final double monto;
  final EstadoTrabajo estado;
  final DateTime fecha;
  final DateTime? entrega;
  final String nota;

  String get titulo => descripcion.isEmpty ? cliente : '$cliente · $descripcion';

  Trabajo conEstado(EstadoTrabajo nuevo) => Trabajo(
        id: id,
        cliente: cliente,
        descripcion: descripcion,
        monto: monto,
        estado: nuevo,
        fecha: fecha,
        entrega: entrega,
        nota: nota,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'cliente': cliente,
        'descripcion': descripcion,
        'monto': monto,
        'estado': estado.name,
        'fecha': fechaIso(fecha),
        'entrega': entrega == null ? null : fechaIso(entrega!),
        'nota': nota,
      };

  factory Trabajo.fromMap(Map<String, Object?> m) => Trabajo(
        id: m['id'] as int,
        cliente: m['cliente'] as String,
        descripcion: m['descripcion'] as String,
        monto: (m['monto'] as num).toDouble(),
        estado: EstadoTrabajo.values.byName(m['estado'] as String),
        fecha: DateTime.parse(m['fecha'] as String),
        entrega: m['entrega'] == null
            ? null
            : DateTime.parse(m['entrega'] as String),
        nota: m['nota'] as String,
      );
}

enum TipoPrestamo { meDeben, debo }

/// Dinero prestado a alguien (me deben) o recibido prestado (debo).
/// No cuenta en el mes: se lleva aparte con sus abonos.
class Prestamo {
  Prestamo({
    this.id,
    required this.tipo,
    required this.persona,
    required this.monto,
    required this.fecha,
    this.fechaLimite,
    this.nota = '',
  });

  final int? id;
  final TipoPrestamo tipo;
  final String persona;
  final double monto;
  final DateTime fecha;
  final DateTime? fechaLimite;
  final String nota;

  bool get meDeben => tipo == TipoPrestamo.meDeben;

  Map<String, Object?> toMap() => {
        'id': id,
        'tipo': tipo.name,
        'persona': persona,
        'monto': monto,
        'fecha': fechaIso(fecha),
        'fecha_limite': fechaLimite == null ? null : fechaIso(fechaLimite!),
        'nota': nota,
      };

  factory Prestamo.fromMap(Map<String, Object?> m) => Prestamo(
        id: m['id'] as int,
        tipo: TipoPrestamo.values.byName(m['tipo'] as String),
        persona: m['persona'] as String,
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
        fechaLimite: m['fecha_limite'] == null
            ? null
            : DateTime.parse(m['fecha_limite'] as String),
        nota: m['nota'] as String,
      );
}

/// Un pago parcial (o total) de un préstamo.
class Abono {
  Abono({
    this.id,
    required this.prestamoId,
    required this.monto,
    required this.fecha,
  });

  final int? id;
  final int prestamoId;
  final double monto;
  final DateTime fecha;

  Map<String, Object?> toMap() => {
        'id': id,
        'prestamo_id': prestamoId,
        'monto': monto,
        'fecha': fechaIso(fecha),
      };

  factory Abono.fromMap(Map<String, Object?> m) => Abono(
        id: m['id'] as int,
        prestamoId: m['prestamo_id'] as int,
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
      );
}

const categoriaCuotas = 'Deudas';
const categoriaTrabajos = 'Trabajos';

const categoriasGasto = <String, IconData>{
  'Alimentación': Icons.restaurant_outlined,
  'Vivienda': Icons.home_outlined,
  'Servicios': Icons.bolt_outlined,
  'Transporte': Icons.directions_car_outlined,
  'Salud': Icons.favorite_outline,
  'Educación': Icons.school_outlined,
  'Suscripciones': Icons.subscriptions_outlined,
  categoriaCuotas: Icons.credit_card_outlined,
  'Entretenimiento': Icons.movie_outlined,
  'Compras': Icons.shopping_bag_outlined,
  'Otros': Icons.more_horiz,
};

const categoriasIngreso = <String, IconData>{
  'Sueldo': Icons.work_outline,
  categoriaTrabajos: Icons.design_services_outlined,
  'Negocio': Icons.storefront_outlined,
  'Regalo': Icons.card_giftcard_outlined,
  'Otros': Icons.more_horiz,
};

Map<String, IconData> categoriasDe(TipoMovimiento tipo) =>
    tipo == TipoMovimiento.gasto ? categoriasGasto : categoriasIngreso;

IconData iconoCategoria(String categoria) =>
    categoriasGasto[categoria] ??
    categoriasIngreso[categoria] ??
    Icons.label_outline;

String fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
