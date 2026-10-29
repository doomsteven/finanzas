import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Base de datos local (SQLite). Todo se guarda en el teléfono.
class Db {
  Db._();

  static Database? _db;

  static Future<Database> get _database async => _db ??= await openDatabase(
        p.join(await getDatabasesPath(), 'finanzas.db'),
        version: 3,
        onUpgrade: (db, anterior, _) async {
          if (anterior < 2) await _migrarV2(db);
          if (anterior < 3) await _migrarV3(db);
        },
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE movimientos(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              tipo TEXT NOT NULL,
              monto REAL NOT NULL,
              categoria TEXT NOT NULL,
              descripcion TEXT NOT NULL DEFAULT '',
              fecha TEXT NOT NULL,
              gasto_fijo_id INTEGER
            )''');
          await db.execute('''
            CREATE TABLE gastos_fijos(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT NOT NULL,
              monto REAL NOT NULL,
              categoria TEXT NOT NULL,
              dia_pago INTEGER NOT NULL,
              activo INTEGER NOT NULL DEFAULT 1
            )''');
          await _migrarV2(db);
          await _migrarV3(db);
        },
      );

  /// Versión 2: préstamos y sus abonos.
  static Future<void> _migrarV2(Database db) async {
    await db.execute('''
      CREATE TABLE prestamos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        persona TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        fecha_limite TEXT,
        nota TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE abonos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prestamo_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL
      )''');
  }

  /// Versión 3: presupuestos, créditos y trabajos.
  static Future<void> _migrarV3(Database db) async {
    await db.execute('ALTER TABLE movimientos ADD COLUMN credito_id INTEGER');
    await db.execute('ALTER TABLE movimientos ADD COLUMN trabajo_id INTEGER');
    await db.execute('''
      CREATE TABLE presupuestos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria TEXT NOT NULL UNIQUE,
        monto REAL NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE creditos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        cuota REAL NOT NULL,
        num_cuotas INTEGER NOT NULL,
        cuotas_previas INTEGER NOT NULL DEFAULT 0,
        dia_pago INTEGER NOT NULL,
        inicio TEXT NOT NULL,
        nota TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE trabajos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT NOT NULL,
        descripcion TEXT NOT NULL DEFAULT '',
        monto REAL NOT NULL,
        estado TEXT NOT NULL,
        fecha TEXT NOT NULL,
        entrega TEXT,
        nota TEXT NOT NULL DEFAULT ''
      )''');
  }

  static Future<List<Map<String, Object?>>> _todos(String tabla,
      {String? orden}) async {
    final db = await _database;
    return db.query(tabla, orderBy: orden);
  }

  /// Inserta o reemplaza (si ya existe el id).
  static Future<void> _guardar(String tabla, Map<String, Object?> fila) async {
    final db = await _database;
    await db.insert(tabla, fila, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _eliminar(String tabla, int id) async {
    final db = await _database;
    await db.delete(tabla, where: 'id = ?', whereArgs: [id]);
  }

  /// Borra un registro pero conserva en el historial los movimientos ligados a él.
  static Future<void> _eliminarConservandoMovimientos(
      String tabla, String columna, int id) async {
    final db = await _database;
    await db.transaction((tx) async {
      await tx.update('movimientos', {columna: null},
          where: '$columna = ?', whereArgs: [id]);
      await tx.delete(tabla, where: 'id = ?', whereArgs: [id]);
    });
  }

  // Movimientos

  static Future<List<Movimiento>> movimientosDelMes(DateTime mes) async {
    final db = await _database;
    final filas = await db.query(
      'movimientos',
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [
        fechaIso(DateTime(mes.year, mes.month)),
        fechaIso(DateTime(mes.year, mes.month + 1)),
      ],
      orderBy: 'fecha DESC, id DESC',
    );
    return filas.map(Movimiento.fromMap).toList();
  }

  /// Todas las cuotas de créditos y cobros de trabajos, de cualquier mes.
  static Future<List<Movimiento>> movimientosVinculados() async {
    final db = await _database;
    final filas = await db.query(
      'movimientos',
      where: 'credito_id IS NOT NULL OR trabajo_id IS NOT NULL',
      orderBy: 'fecha DESC, id DESC',
    );
    return filas.map(Movimiento.fromMap).toList();
  }

  static Future<void> guardarMovimiento(Movimiento m) =>
      _guardar('movimientos', m.toMap());

  static Future<void> eliminarMovimiento(int id) => _eliminar('movimientos', id);

  // Gastos fijos

  static Future<List<GastoFijo>> gastosFijos() async =>
      (await _todos('gastos_fijos', orden: 'dia_pago, nombre'))
          .map(GastoFijo.fromMap)
          .toList();

  static Future<void> guardarGastoFijo(GastoFijo f) =>
      _guardar('gastos_fijos', f.toMap());

  static Future<void> eliminarGastoFijo(int id) =>
      _eliminarConservandoMovimientos('gastos_fijos', 'gasto_fijo_id', id);

  // Presupuestos

  static Future<List<Presupuesto>> presupuestos() async =>
      (await _todos('presupuestos', orden: 'categoria'))
          .map(Presupuesto.fromMap)
          .toList();

  static Future<void> guardarPresupuesto(Presupuesto p) =>
      _guardar('presupuestos', p.toMap());

  static Future<void> eliminarPresupuesto(int id) =>
      _eliminar('presupuestos', id);

  // Créditos

  static Future<List<Credito>> creditos() async =>
      (await _todos('creditos', orden: 'dia_pago, nombre'))
          .map(Credito.fromMap)
          .toList();

  static Future<void> guardarCredito(Credito c) =>
      _guardar('creditos', c.toMap());

  static Future<void> eliminarCredito(int id) =>
      _eliminarConservandoMovimientos('creditos', 'credito_id', id);

  // Trabajos

  static Future<List<Trabajo>> trabajos() async =>
      (await _todos('trabajos', orden: 'fecha DESC, id DESC'))
          .map(Trabajo.fromMap)
          .toList();

  static Future<void> guardarTrabajo(Trabajo t) =>
      _guardar('trabajos', t.toMap());

  static Future<void> eliminarTrabajo(int id) =>
      _eliminarConservandoMovimientos('trabajos', 'trabajo_id', id);

  // Préstamos

  static Future<List<Prestamo>> prestamos() async =>
      (await _todos('prestamos', orden: 'fecha DESC, id DESC'))
          .map(Prestamo.fromMap)
          .toList();

  static Future<void> guardarPrestamo(Prestamo p) =>
      _guardar('prestamos', p.toMap());

  /// Borra el préstamo junto con todos sus abonos.
  static Future<void> eliminarPrestamo(int id) async {
    final db = await _database;
    await db.transaction((tx) async {
      await tx.delete('abonos', where: 'prestamo_id = ?', whereArgs: [id]);
      await tx.delete('prestamos', where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<List<Abono>> abonos() async =>
      (await _todos('abonos', orden: 'fecha DESC, id DESC'))
          .map(Abono.fromMap)
          .toList();

  static Future<void> guardarAbono(Abono a) => _guardar('abonos', a.toMap());

  static Future<void> eliminarAbono(int id) => _eliminar('abonos', id);
}
