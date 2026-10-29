import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import 'formularios.dart';

class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final movimientos = appState.movimientos;
        if (movimientos.isEmpty) {
          return Center(
            child: Text(
              'No hay movimientos este mes.\nToca "+ Movimiento" para agregar uno.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          );
        }

        // Lista agrupada por día (ya viene ordenada de más reciente a más antigua).
        final filas = <Widget>[];
        String? diaAnterior;
        for (final m in movimientos) {
          final dia = fechaIso(m.fecha);
          if (dia != diaAnterior) {
            filas.add(_Encabezado(fechaLarga(m.fecha)));
            diaAnterior = dia;
          }
          filas.add(_FilaMovimiento(m));
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: filas,
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(texto, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento(this.m);

  final Movimiento m;

  @override
  Widget build(BuildContext context) {
    final color = m.esGasto ? colorGasto : colorIngreso;
    return Dismissible(
      key: ValueKey(m.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorGasto,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        appState.eliminarMovimiento(m);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('"${m.titulo}" eliminado'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => appState.guardarMovimiento(m),
            ),
          ));
      },
      child: ListTile(
        onTap: () => abrirFormMovimiento(context, m),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(iconoCategoria(m.categoria), color: color),
        ),
        title: Text(m.titulo),
        subtitle: Text(switch (m) {
          Movimiento(gastoFijoId: != null) => '${m.categoria} · Gasto fijo',
          Movimiento(creditoId: != null) => '${m.categoria} · Cuota de crédito',
          Movimiento(trabajoId: != null) => '${m.categoria} · Cobro de trabajo',
          _ => m.categoria,
        }),
        trailing: Text(
          '${m.esGasto ? '-' : '+'}${dinero(m.monto)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
