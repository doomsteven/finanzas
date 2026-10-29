import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'formularios.dart';

void abrirDetalleTrabajo(BuildContext context, Trabajo t) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => TrabajoDetalle(trabajoId: t.id!)));

class TrabajosScreen extends StatelessWidget {
  const TrabajosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState;
        if (s.trabajos.isEmpty) {
          return const Vacio(
            'Registra tus proyectos y cotizaciones.\n'
            'Lo que cobres se suma a tus ingresos del mes.',
            centrado: true,
          );
        }
        final cobrados = s.trabajosCobrados;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            TarjetaMonto(
              etiqueta: 'Por cobrar',
              monto: s.totalPorCobrar,
              color: colorIngreso,
              children: [
                if (s.totalCotizado > 0)
                  Text('Cotizado sin aprobar: ${dinero(s.totalCotizado)}'),
              ],
            ),
            _Grupo('En curso', s.trabajosEn(EstadoTrabajo.enCurso)),
            _Grupo('Terminados por cobrar', s.trabajosEn(EstadoTrabajo.terminado)),
            _Grupo('Cotizados', s.trabajosEn(EstadoTrabajo.cotizado)),
            if (cobrados.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Cobrados (${cobrados.length})'),
                  children: [for (final t in cobrados) _FilaTrabajo(t)],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo(this.titulo, this.trabajos);

  final String titulo;
  final List<Trabajo> trabajos;

  @override
  Widget build(BuildContext context) {
    if (trabajos.isEmpty) return const SizedBox.shrink();
    return Seccion(
      titulo: titulo,
      extra: '${trabajos.length}',
      child: Column(children: [for (final t in trabajos) _FilaTrabajo(t)]),
    );
  }
}

class _FilaTrabajo extends StatelessWidget {
  const _FilaTrabajo(this.t);

  final Trabajo t;

  @override
  Widget build(BuildContext context) {
    final s = appState;
    final gris = Theme.of(context).colorScheme.outline;
    final cotizado = t.estado == EstadoTrabajo.cotizado;
    final cobrado = s.estaCobrado(t);
    final entrega = t.entrega;
    final atrasado = t.estado == EstadoTrabajo.enCurso &&
        entrega != null &&
        s.estaVencida(entrega);

    final detalle = cotizado
        ? 'Cotizado el ${fechaCorta(t.fecha)}'
        : '${dinero(s.cobradoDe(t))} de ${dinero(t.monto)} cobrados'
            '${entrega == null || t.estado != EstadoTrabajo.enCurso ? '' : ' · Entrega ${fechaCorta(entrega)}'}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => abrirDetalleTrabajo(context, t),
      leading: Inicial(t.cliente, color: cotizado ? gris : colorIngreso),
      title: Text(t.cliente),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.descripcion.isNotEmpty) Text(t.descripcion),
          Text(detalle,
              style: atrasado ? const TextStyle(color: colorGasto) : null),
          if (!cotizado && !cobrado) ...[
            const SizedBox(height: 6),
            Barra(s.cobradoDe(t) / t.monto, color: colorIngreso, alto: 4),
          ],
        ],
      ),
      trailing: cobrado
          ? const Icon(Icons.check_circle_outline)
          : Text(
              dinero(cotizado ? t.monto : s.faltaDe(t)),
              style: TextStyle(
                color: cotizado ? gris : colorIngreso,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class TrabajoDetalle extends StatelessWidget {
  const TrabajoDetalle({super.key, required this.trabajoId});

  final int trabajoId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        // Se busca en cada cambio para mostrar siempre los datos al día.
        final t = appState.trabajos.where((x) => x.id == trabajoId).firstOrNull;
        if (t == null) return const Scaffold();

        final s = appState;
        final falta = s.faltaDe(t);
        final cobros = s.cobrosDe(t);
        final entrega = t.entrega;
        final siguiente = switch (t.estado) {
          EstadoTrabajo.cotizado => (EstadoTrabajo.enCurso, 'Aprobado: pasar a En curso'),
          EstadoTrabajo.enCurso => (EstadoTrabajo.terminado, 'Marcar como terminado'),
          EstadoTrabajo.terminado => null,
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(t.cliente),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => abrirFormTrabajo(context, t),
              ),
            ],
          ),
          floatingActionButton: falta < 0.005
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => abrirFormCobro(context, t),
                  icon: const Icon(Icons.add),
                  label: Text(cobros.isEmpty ? 'Anticipo' : 'Cobro'),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              TarjetaMonto(
                etiqueta: s.estaCobrado(t) ? 'Cobrado completo' : 'Te falta cobrar',
                monto: falta,
                color: colorIngreso,
                children: [
                  const SizedBox(height: 12),
                  Barra(s.cobradoDe(t) / t.monto, color: colorIngreso),
                  const SizedBox(height: 8),
                  Text('${dinero(s.cobradoDe(t))} de ${dinero(t.monto)} cobrados'),
                  const Divider(height: 28),
                  Text('Estado: ${nombresEstado[t.estado]}'),
                  if (t.descripcion.isNotEmpty) Text(t.descripcion),
                  Text('Cotizado el ${fechaLarga(t.fecha)}'),
                  if (entrega != null) Text('Entrega: ${fechaLarga(entrega)}'),
                  if (t.nota.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(t.nota),
                  ],
                ],
              ),
              if (siguiente != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton(
                    onPressed: () =>
                        s.guardarTrabajo(t.conEstado(siguiente.$1)),
                    child: Text(siguiente.$2),
                  ),
                ),
              Seccion(
                titulo: 'Cobros',
                child: cobros.isEmpty
                    ? const Vacio('Aún no hay cobros. El primero es el anticipo.')
                    : Column(children: [for (final m in cobros) FilaPago(m)]),
              ),
            ],
          ),
        );
      },
    );
  }
}
