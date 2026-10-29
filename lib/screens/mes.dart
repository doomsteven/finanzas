import 'dart:math';

import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class MesScreen extends StatelessWidget {
  const MesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        // Sin const: las secciones deben reconstruirse con cada cambio de appState.
        children: [
          _TarjetaPlan(),
          _Presupuestos(),
          _PorPagar(),
          _Pendientes(),
          _PorCategoria(),
        ],
      ),
    );
  }
}

/// La cuenta del mes: ingresos − compromisos = libre para gastar.
class _TarjetaPlan extends StatelessWidget {
  const _TarjetaPlan();

  @override
  Widget build(BuildContext context) {
    final s = appState;
    final texto = Theme.of(context).textTheme;
    final libre = s.libre;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Libre para gastar', style: texto.labelLarge),
            Text(
              dinero(libre),
              style: texto.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: libre < 0 ? colorGasto : null,
              ),
            ),
            if (s.totalIngresos == 0)
              Text('Registra tu sueldo o un cobro para empezar.',
                  style: texto.bodySmall),
            const Divider(height: 28),
            _FilaCuenta('Ingresos', s.totalIngresos, entra: true),
            if (s.totalFijos > 0) _FilaCuenta('Gastos fijos', s.totalFijos),
            if (s.totalCuotas > 0) _FilaCuenta('Cuotas de créditos', s.totalCuotas),
            if (s.totalPresupuestos > 0)
              _FilaCuenta('Presupuestos', s.totalPresupuestos),
            if (s.otrosGastos > 0) _FilaCuenta('Otros gastos', s.otrosGastos),
          ],
        ),
      ),
    );
  }
}

class _FilaCuenta extends StatelessWidget {
  const _FilaCuenta(this.etiqueta, this.valor, {this.entra = false});

  final String etiqueta;
  final double valor;
  final bool entra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta)),
          Text(
            '${entra ? '+' : '−'} ${dinero(valor)}',
            style: TextStyle(
              color: entra ? colorIngreso : colorGasto,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Presupuestos extends StatelessWidget {
  const _Presupuestos();

  @override
  Widget build(BuildContext context) {
    final s = appState;
    final texto = Theme.of(context).textTheme;
    return Seccion(
      titulo: 'Presupuestos',
      child: s.presupuestos.isEmpty
          ? const Vacio('Crea uno en la pestaña Plan (ej. Alimentación \$100).')
          : Column(
              children: [
                for (final p in s.presupuestos)
                  Builder(builder: (context) {
                    final gastado = s.gastadoEn(p.categoria);
                    final queda = s.quedaEn(p);
                    final color = queda < 0 ? colorGasto : colorIngreso;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(iconoCategoria(p.categoria), size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p.categoria)),
                              Text(
                                queda < 0
                                    ? 'Te pasaste ${dinero(-queda)}'
                                    : 'Quedan ${dinero(queda)}',
                                style: TextStyle(
                                    color: color, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Barra(gastado / p.monto,
                              color: queda < 0 ? colorGasto : null),
                          const SizedBox(height: 4),
                          Text(
                            'Gastado ${dinero(gastado)} de ${dinero(p.monto)}',
                            style: texto.labelSmall,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

/// Fijos y cuotas del mes en una sola lista, ordenados por día de pago.
class _PorPagar extends StatelessWidget {
  const _PorPagar();

  @override
  Widget build(BuildContext context) {
    final s = appState;
    final items = [
      for (final f in s.fijosActivos)
        (
          nombre: f.nombre,
          monto: f.monto,
          vence: f.vencimientoEn(s.mes),
          pago: s.pagoDe(f),
          detalle: null as String?,
          alternar: () => s.alternarPago(f),
        ),
      for (final c in s.creditosDelMes)
        (
          nombre: c.nombre,
          monto: c.cuota,
          vence: c.vencimientoEn(s.mes),
          pago: s.cuotaDelMes(c),
          detalle: 'Cuota ${min(s.cuotasPagadas(c) + (s.cuotaDelMes(c) == null ? 1 : 0), c.numCuotas)} de ${c.numCuotas}',
          alternar: () => s.alternarCuota(c),
        ),
    ]..sort((a, b) => a.vence.compareTo(b.vence));
    final pagados = items.where((i) => i.pago != null).length;

    return Seccion(
      titulo: 'Por pagar este mes',
      extra: items.isEmpty ? null : '$pagados de ${items.length} pagados',
      child: items.isEmpty
          ? const Vacio('Agrega gastos fijos en Plan y créditos en Deudas.')
          : Column(
              children: [
                for (final i in items)
                  Builder(builder: (context) {
                    final vencido = i.pago == null && s.estaVencida(i.vence);
                    final estado = i.pago != null
                        ? 'Pagado el ${fechaCorta(i.pago!.fecha)}'
                        : vencido
                            ? 'Vencido · día ${i.vence.day}'
                            : 'Vence el día ${i.vence.day}';
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: i.pago != null,
                      onChanged: (_) => i.alternar(),
                      title: Text(i.nombre),
                      subtitle: Text(
                        i.detalle == null ? estado : '$estado · ${i.detalle}',
                        style: vencido ? const TextStyle(color: colorGasto) : null,
                      ),
                      secondary: Text(
                        dinero(i.monto),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

/// Saldos que no son del mes: trabajos por cobrar, préstamos y créditos.
class _Pendientes extends StatelessWidget {
  const _Pendientes();

  @override
  Widget build(BuildContext context) {
    final s = appState;
    final cifras = [
      (Icons.south_west, colorIngreso, 'Trabajos por cobrar', s.totalPorCobrar),
      (Icons.south_west, colorIngreso, 'Te deben', s.totalPendiente(TipoPrestamo.meDeben)),
      (Icons.north_east, colorGasto, 'Debes en préstamos', s.totalPendiente(TipoPrestamo.debo)),
      (Icons.north_east, colorGasto, 'Saldo de créditos', s.totalDeudaCreditos),
    ].where((c) => c.$4 > 0).toList();
    if (cifras.isEmpty) return const SizedBox.shrink();

    return Seccion(
      titulo: 'Pendientes',
      extra: 'No cuentan en el mes',
      child: Card.outlined(
        margin: const EdgeInsets.only(top: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, medidas) => Wrap(
              runSpacing: 16,
              children: [
                for (final c in cifras)
                  SizedBox(
                    width: medidas.maxWidth / 2,
                    child: Cifra(
                      icono: c.$1,
                      color: c.$2,
                      etiqueta: c.$3,
                      valor: c.$4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PorCategoria extends StatelessWidget {
  const _PorCategoria();

  @override
  Widget build(BuildContext context) {
    final categorias = appState.gastosPorCategoria;
    if (categorias.isEmpty) return const SizedBox.shrink();
    final total = appState.totalGastos;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Gastos por categoría'),
        trailing: Text(dinero(total)),
        children: [
          for (final c in categorias)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(iconoCategoria(c.key), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.key)),
                      Text('${dinero(c.value)}  ·  '
                          '${(c.value / total * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Barra(c.value / total),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
