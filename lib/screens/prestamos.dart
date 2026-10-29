import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'formularios.dart';

void abrirDetallePrestamo(BuildContext context, Prestamo p) =>
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PrestamoDetalle(prestamoId: p.id!)));

/// "Abono rápido": elige el préstamo pendiente y abre su formulario de abono.
Future<void> elegirPrestamoParaAbono(BuildContext context) async {
  final pendientes = [
    ...appState.pendientes(TipoPrestamo.meDeben),
    ...appState.pendientes(TipoPrestamo.debo),
  ];
  if (pendientes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes préstamos pendientes.')));
    return;
  }
  final elegido = pendientes.length == 1
      ? pendientes.first
      : await showModalBottomSheet<Prestamo>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text('¿Qué préstamo se abona?',
                    style: Theme.of(context).textTheme.titleMedium),
                for (final p in pendientes)
                  _FilaPrestamo(p, onTap: () => Navigator.pop(context, p)),
              ],
            ),
          ),
        );
  if (elegido != null && context.mounted) {
    await abrirFormAbono(context, elegido);
  }
}

/// Préstamos pendientes de un tipo ("Me deben" o "Debo").
class GrupoPrestamos extends StatelessWidget {
  const GrupoPrestamos(this.tipo, {super.key});

  final TipoPrestamo tipo;

  @override
  Widget build(BuildContext context) {
    final meDeben = tipo == TipoPrestamo.meDeben;
    final pendientes = appState.pendientes(tipo);
    return Seccion(
      titulo: meDeben ? 'Préstamos · me deben' : 'Préstamos · debo',
      extra: dinero(appState.totalPendiente(tipo)),
      colorExtra: meDeben ? colorIngreso : colorGasto,
      child: pendientes.isEmpty
          ? Vacio(meDeben ? 'Nadie te debe.' : 'No debes nada.')
          : Column(children: [for (final p in pendientes) _FilaPrestamo(p)]),
    );
  }
}

class PrestamosSaldados extends StatelessWidget {
  const PrestamosSaldados({super.key});

  @override
  Widget build(BuildContext context) {
    final saldados = appState.saldados;
    if (saldados.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Préstamos saldados (${saldados.length})'),
      children: [for (final p in saldados) _FilaPrestamo(p)],
    );
  }
}

class _FilaPrestamo extends StatelessWidget {
  const _FilaPrestamo(this.p, {this.onTap});

  final Prestamo p;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = appState;
    final color = p.meDeben ? colorIngreso : colorGasto;
    final saldado = s.estaSaldado(p);
    final vencido = s.estaVencido(p);
    final limite = p.fechaLimite;

    final detalle = saldado
        ? 'Saldado · ${dinero(p.monto)}'
        : '${dinero(s.pagadoDe(p))} de ${dinero(p.monto)} pagados'
            '${limite == null ? '' : vencido ? ' · Vencido el ${fechaCorta(limite)}' : ' · Hasta el ${fechaCorta(limite)}'}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap ?? () => abrirDetallePrestamo(context, p),
      leading: Inicial(p.persona, color: color),
      title: Text(p.persona),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detalle, style: vencido ? const TextStyle(color: colorGasto) : null),
          if (!saldado) ...[
            const SizedBox(height: 6),
            Barra(s.pagadoDe(p) / p.monto, color: color, alto: 4),
          ],
        ],
      ),
      trailing: saldado
          ? const Icon(Icons.check_circle_outline)
          : Text(
              dinero(s.saldoDe(p)),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
    );
  }
}

class PrestamoDetalle extends StatelessWidget {
  const PrestamoDetalle({super.key, required this.prestamoId});

  final int prestamoId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        // Se busca en cada cambio para mostrar siempre los datos al día.
        final p = appState.prestamos.where((x) => x.id == prestamoId).firstOrNull;
        if (p == null) return const Scaffold();

        final s = appState;
        final color = p.meDeben ? colorIngreso : colorGasto;
        final saldado = s.estaSaldado(p);
        final abonos = s.abonosDe(p);
        final limite = p.fechaLimite;

        return Scaffold(
          appBar: AppBar(
            title: Text(p.persona),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => abrirFormPrestamo(context, p),
              ),
            ],
          ),
          floatingActionButton: saldado
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => abrirFormAbono(context, p),
                  icon: const Icon(Icons.add),
                  label: const Text('Abono'),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              TarjetaMonto(
                etiqueta: saldado
                    ? 'Saldado'
                    : p.meDeben
                        ? 'Te debe'
                        : 'Le debes',
                monto: s.saldoDe(p),
                color: color,
                children: [
                  const SizedBox(height: 12),
                  Barra(s.pagadoDe(p) / p.monto, color: color),
                  const SizedBox(height: 8),
                  Text('${dinero(s.pagadoDe(p))} de ${dinero(p.monto)} pagados'),
                  const Divider(height: 28),
                  Text('Prestado el ${fechaLarga(p.fecha)}'),
                  if (limite != null)
                    Text(
                      s.estaVencido(p)
                          ? 'Venció el ${fechaLarga(limite)}'
                          : 'Pagar hasta el ${fechaLarga(limite)}',
                      style: s.estaVencido(p)
                          ? const TextStyle(color: colorGasto)
                          : null,
                    ),
                  if (p.nota.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(p.nota),
                  ],
                ],
              ),
              Seccion(
                titulo: 'Abonos',
                child: abonos.isEmpty
                    ? const Vacio('Aún no hay abonos.')
                    : Column(children: [for (final a in abonos) _FilaAbono(a)]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilaAbono extends StatelessWidget {
  const _FilaAbono(this.a);

  final Abono a;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(a.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorGasto,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        appState.eliminarAbono(a);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Abono de ${dinero(a.monto)} eliminado'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => appState.guardarAbono(a),
            ),
          ));
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.payments_outlined),
        title: Text(fechaLarga(a.fecha)),
        trailing: Text(
          dinero(a.monto),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
