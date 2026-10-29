import 'dart:math';

import 'package:flutter/foundation.dart';

import 'db.dart';
import 'models.dart';

/// Medio centavo de margen por el redondeo de los decimales.
const _margen = 0.005;

double _suma<T>(Iterable<T> items, double Function(T) monto) =>
    items.fold(0.0, (total, x) => total + monto(x));

/// Estado global de la app. Todos los cálculos viven aquí para que cada
/// número se calcule de una sola forma y se vea igual en todas las pantallas.
class AppState extends ChangeNotifier {
  DateTime mes = DateTime(DateTime.now().year, DateTime.now().month);

  /// Movimientos del mes seleccionado.
  List<Movimiento> movimientos = [];

  /// Cuotas de créditos y cobros de trabajos de todos los meses.
  List<Movimiento> vinculados = [];
  List<GastoFijo> fijos = [];
  List<Presupuesto> presupuestos = [];
  List<Credito> creditos = [];
  List<Trabajo> trabajos = [];
  List<Prestamo> prestamos = [];
  List<Abono> abonos = [];

  Future<void> cargar() async {
    movimientos = await Db.movimientosDelMes(mes);
    vinculados = await Db.movimientosVinculados();
    fijos = await Db.gastosFijos();
    presupuestos = await Db.presupuestos();
    creditos = await Db.creditos();
    trabajos = await Db.trabajos();
    prestamos = await Db.prestamos();
    abonos = await Db.abonos();
    notifyListeners();
  }

  Future<void> cambiarMes(int delta) async {
    mes = DateTime(mes.year, mes.month + delta);
    await cargar();
  }

  Future<void> irAlMesActual() async {
    if (esMesActual) return;
    mes = DateTime(DateTime.now().year, DateTime.now().month);
    await cargar();
  }

  bool get esMesActual {
    final hoy = DateTime.now();
    return mes.year == hoy.year && mes.month == hoy.month;
  }

  /// Fecha por defecto para un movimiento nuevo en el mes que se está viendo.
  DateTime get fechaSugerida => esMesActual ? DateTime.now() : mes;

  bool estaVencida(DateTime fecha) {
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day).isAfter(fecha);
  }

  // ---------------------------------------------------------------------------
  // El mes: ingresos − fijos − cuotas − presupuestos − otros gastos = libre.

  double get totalIngresos =>
      _suma(movimientos.where((m) => !m.esGasto), (m) => m.monto);

  double get totalGastos =>
      _suma(movimientos.where((m) => m.esGasto), (m) => m.monto);

  Iterable<Movimiento> get _gastosLibres =>
      movimientos.where((m) => m.esGasto && m.esLibre);

  List<GastoFijo> get fijosActivos => fijos.where((f) => f.activo).toList();

  double get totalFijos => _suma(fijosActivos, (f) => f.monto);

  /// Créditos con cuota en el mes seleccionado.
  List<Credito> get creditosDelMes => creditos
      .where((c) =>
          !DateTime(c.inicio.year, c.inicio.month).isAfter(mes) &&
          (!creditoTerminado(c) || cuotaDelMes(c) != null))
      .toList();

  double get totalCuotas => _suma(creditosDelMes, (c) => c.cuota);

  double gastadoEn(String categoria) =>
      _suma(_gastosLibres.where((m) => m.categoria == categoria), (m) => m.monto);

  Presupuesto? presupuestoDe(String categoria) =>
      presupuestos.where((p) => p.categoria == categoria).firstOrNull;

  /// Lo que queda del presupuesto (negativo si se pasó).
  double quedaEn(Presupuesto p) => p.monto - gastadoEn(p.categoria);

  /// Cada presupuesto cuenta completo, o lo gastado si se pasó.
  double get totalPresupuestos =>
      _suma(presupuestos, (p) => max(p.monto, gastadoEn(p.categoria)));

  /// Gastos del día a día en categorías sin presupuesto.
  double get otrosGastos => _suma(
      _gastosLibres.where((m) => presupuestoDe(m.categoria) == null),
      (m) => m.monto);

  double get libre =>
      totalIngresos - totalFijos - totalCuotas - totalPresupuestos - otrosGastos;

  /// Total gastado por categoría, de mayor a menor.
  List<MapEntry<String, double>> get gastosPorCategoria {
    final totales = <String, double>{};
    for (final m in movimientos.where((m) => m.esGasto)) {
      totales[m.categoria] = (totales[m.categoria] ?? 0) + m.monto;
    }
    return totales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  // ---------------------------------------------------------------------------
  // Gastos fijos

  /// El pago de este gasto fijo en el mes seleccionado, si ya se registró.
  Movimiento? pagoDe(GastoFijo f) =>
      movimientos.where((m) => m.gastoFijoId == f.id).firstOrNull;

  Future<void> alternarPago(GastoFijo f) async {
    final pago = pagoDe(f);
    if (pago != null) {
      await Db.eliminarMovimiento(pago.id!);
    } else {
      await Db.guardarMovimiento(Movimiento(
        tipo: TipoMovimiento.gasto,
        monto: f.monto,
        categoria: f.categoria,
        descripcion: f.nombre,
        fecha: esMesActual ? DateTime.now() : f.vencimientoEn(mes),
        gastoFijoId: f.id,
      ));
    }
    await cargar();
  }

  Future<void> guardarFijo(GastoFijo f) async {
    await Db.guardarGastoFijo(f);
    await cargar();
  }

  Future<void> eliminarFijo(GastoFijo f) async {
    await Db.eliminarGastoFijo(f.id!);
    await cargar();
  }

  // ---------------------------------------------------------------------------
  // Presupuestos

  Future<void> guardarPresupuesto(Presupuesto p) async {
    await Db.guardarPresupuesto(p);
    await cargar();
  }

  Future<void> eliminarPresupuesto(Presupuesto p) async {
    await Db.eliminarPresupuesto(p.id!);
    await cargar();
  }

  // ---------------------------------------------------------------------------
  // Créditos

  List<Movimiento> pagosDe(Credito c) =>
      vinculados.where((m) => m.creditoId == c.id).toList();

  Movimiento? cuotaDelMes(Credito c) =>
      movimientos.where((m) => m.creditoId == c.id).firstOrNull;

  int cuotasPagadas(Credito c) => c.cuotasPrevias + pagosDe(c).length;

  bool creditoTerminado(Credito c) => cuotasPagadas(c) >= c.numCuotas;

  double saldoCredito(Credito c) =>
      c.cuota * max(0, c.numCuotas - cuotasPagadas(c));

  List<Credito> get creditosActivos =>
      creditos.where((c) => !creditoTerminado(c)).toList();

  double get totalDeudaCreditos => _suma(creditosActivos, saldoCredito);

  Future<void> pagarCuota(Credito c, {DateTime? fecha}) async {
    await Db.guardarMovimiento(Movimiento(
      tipo: TipoMovimiento.gasto,
      monto: c.cuota,
      categoria: categoriaCuotas,
      descripcion: 'Cuota ${c.nombre}',
      fecha: fecha ?? (esMesActual ? DateTime.now() : c.vencimientoEn(mes)),
      creditoId: c.id,
    ));
    await cargar();
  }

  /// Marca o desmarca como pagada la cuota del mes seleccionado.
  Future<void> alternarCuota(Credito c) async {
    final pago = cuotaDelMes(c);
    if (pago == null) return pagarCuota(c);
    await Db.eliminarMovimiento(pago.id!);
    await cargar();
  }

  Future<void> guardarCredito(Credito c) async {
    await Db.guardarCredito(c);
    await cargar();
  }

  Future<void> eliminarCredito(Credito c) async {
    await Db.eliminarCredito(c.id!);
    await cargar();
  }

  // ---------------------------------------------------------------------------
  // Trabajos

  List<Movimiento> cobrosDe(Trabajo t) =>
      vinculados.where((m) => m.trabajoId == t.id).toList();

  double cobradoDe(Trabajo t) => _suma(cobrosDe(t), (m) => m.monto);

  double faltaDe(Trabajo t) => max(0.0, t.monto - cobradoDe(t));

  bool estaCobrado(Trabajo t) =>
      t.estado == EstadoTrabajo.terminado && faltaDe(t) < _margen;

  List<Trabajo> trabajosEn(EstadoTrabajo estado) => trabajos
      .where((t) => t.estado == estado && !estaCobrado(t))
      .toList();

  List<Trabajo> get trabajosCobrados => trabajos.where(estaCobrado).toList();

  double get totalPorCobrar => _suma(
      trabajos.where((t) => t.estado != EstadoTrabajo.cotizado), faltaDe);

  double get totalCotizado =>
      _suma(trabajosEn(EstadoTrabajo.cotizado), (t) => t.monto);

  /// Un cobro es un ingreso del mes. El primero (anticipo) aprueba la cotización.
  Future<void> registrarCobro(Trabajo t, double monto, DateTime fecha) async {
    await Db.guardarMovimiento(Movimiento(
      tipo: TipoMovimiento.ingreso,
      monto: monto,
      categoria: categoriaTrabajos,
      descripcion: t.titulo,
      fecha: fecha,
      trabajoId: t.id,
    ));
    if (t.estado == EstadoTrabajo.cotizado) {
      await Db.guardarTrabajo(t.conEstado(EstadoTrabajo.enCurso));
    }
    await cargar();
  }

  Future<void> guardarTrabajo(Trabajo t) async {
    await Db.guardarTrabajo(t);
    await cargar();
  }

  Future<void> eliminarTrabajo(Trabajo t) async {
    await Db.eliminarTrabajo(t.id!);
    await cargar();
  }

  // ---------------------------------------------------------------------------
  // Préstamos: no forman parte del mes, se muestran siempre todos.

  List<Abono> abonosDe(Prestamo p) =>
      abonos.where((a) => a.prestamoId == p.id).toList();

  double pagadoDe(Prestamo p) => _suma(abonosDe(p), (a) => a.monto);

  double saldoDe(Prestamo p) => max(0.0, p.monto - pagadoDe(p));

  bool estaSaldado(Prestamo p) => saldoDe(p) < _margen;

  bool estaVencido(Prestamo p) {
    final limite = p.fechaLimite;
    return limite != null && !estaSaldado(p) && estaVencida(limite);
  }

  List<Prestamo> pendientes(TipoPrestamo tipo) => prestamos
      .where((p) => p.tipo == tipo && !estaSaldado(p))
      .toList();

  List<Prestamo> get saldados => prestamos.where(estaSaldado).toList();

  double totalPendiente(TipoPrestamo tipo) => _suma(pendientes(tipo), saldoDe);

  Future<void> guardarPrestamo(Prestamo p) async {
    await Db.guardarPrestamo(p);
    await cargar();
  }

  Future<void> eliminarPrestamo(Prestamo p) async {
    await Db.eliminarPrestamo(p.id!);
    await cargar();
  }

  Future<void> guardarAbono(Abono a) async {
    await Db.guardarAbono(a);
    await cargar();
  }

  Future<void> eliminarAbono(Abono a) async {
    // Se quita de la lista al instante para que el Dismissible no falle.
    abonos.removeWhere((x) => x.id == a.id);
    notifyListeners();
    await Db.eliminarAbono(a.id!);
    await cargar();
  }

  // ---------------------------------------------------------------------------
  // Movimientos

  Future<void> guardarMovimiento(Movimiento m) async {
    await Db.guardarMovimiento(m);
    await cargar();
  }

  Future<void> eliminarMovimiento(Movimiento m) async {
    // Se quita de las listas al instante para que el Dismissible no falle.
    movimientos.removeWhere((x) => x.id == m.id);
    vinculados.removeWhere((x) => x.id == m.id);
    notifyListeners();
    await Db.eliminarMovimiento(m.id!);
    await cargar();
  }
}

final appState = AppState();
