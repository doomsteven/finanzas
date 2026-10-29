import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'formularios.dart';
import 'prestamos.dart';

void abrirDetalleCredito(BuildContext context, Credito c) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => CreditoDetalle(creditoId: c.id!)));

/// Créditos (cuotas que restan del mes) y préstamos con personas (no restan).
class DeudasScreen extends StatelessWidget {
  const DeudasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState;
        if (s.creditos.isEmpty && s.prestamos.isEmpty) {
          return const Vacio(
            'Registra tus créditos (cuotas mensuales) y los préstamos '
            'con personas.',
            centrado: true,
          );
        }
        final terminados = s.creditos.where(s.creditoTerminado).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            Seccion(
              titulo: 'Créditos',
              extra: dinero(s.totalDeudaCreditos),
              colorExtra: colorGasto,
              child: s.creditosActivos.isEmpty
                  ? const Vacio('Electrodomésticos, préstamos del banco...')
                  : Column(children: [
                      for (final c in s.creditosActivos) _FilaCredito(c),
                    ]),
            ),
            if (terminados.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Créditos pagados (${terminados.length})'),
                children: [for (final c in terminados) _FilaCredito(c)],
              ),
            GrupoPrestamos(TipoPrestamo.meDeben),
            GrupoPrestamos(TipoPrestamo.debo),
            PrestamosSaldados(),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Vacio(
                  'Las cuotas de créditos restan de tu mes. '
                  'Los préstamos con personas no.'),
            ),
          ],
        );
      },
    );
  }
}

class _FilaCredito extends StatelessWidget {
  const _FilaCredito(this.c);

  final Credito c;

  @override
  Widget build(BuildContext context) {
    final s = appState;
    final terminado = s.creditoTerminado(c);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => abrirDetalleCredito(context, c),
      leading: CircleAvatar(
        backgroundColor: colorGasto.withValues(alpha: 0.15),
        child: const Icon(Icons.credit_card_outlined, color: colorGasto),
      ),
      title: Text(c.nombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${dinero(c.cuota)}/mes · día ${c.diaPago} · '
              '${s.cuotasPagadas(c)} de ${c.numCuotas} cuotas'),
          if (!terminado) ...[
            const SizedBox(height: 6),
            Barra(s.cuotasPagadas(c) / c.numCuotas, color: colorGasto, alto: 4),
          ],
        ],
      ),
      trailing: terminado
          ? const Icon(Icons.check_circle_outline)
          : Text(
              dinero(s.saldoCredito(c)),
              style: const TextStyle(
                  color: colorGasto, fontWeight: FontWeight.w600),
            ),
    );
  }
}

class CreditoDetalle extends StatelessWidget {
  const CreditoDetalle({super.key, required this.creditoId});

  final int creditoId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        // Se busca en cada cambio para mostrar siempre los datos al día.
        final c = appState.creditos.where((x) => x.id == creditoId).firstOrNull;
        if (c == null) return const Scaffold();

        final s = appState;
        final pagos = s.pagosDe(c);
        final terminado = s.creditoTerminado(c);

        return Scaffold(
          appBar: AppBar(
            title: Text(c.nombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => abrirFormCredito(context, c),
              ),
            ],
          ),
          floatingActionButton: terminado
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => s.pagarCuota(c, fecha: DateTime.now()),
                  icon: const Icon(Icons.check),
                  label: Text('Pagar cuota de ${dinero(c.cuota)}'),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              TarjetaMonto(
                etiqueta: terminado ? 'Crédito pagado' : 'Te falta pagar',
                monto: s.saldoCredito(c),
                color: colorGasto,
                children: [
                  const SizedBox(height: 12),
                  Barra(s.cuotasPagadas(c) / c.numCuotas, color: colorGasto),
                  const SizedBox(height: 8),
                  Text('${s.cuotasPagadas(c)} de ${c.numCuotas} cuotas pagadas'),
                  const Divider(height: 28),
                  Text('Cuota: ${dinero(c.cuota)} el día ${c.diaPago} de cada mes'),
                  Text('Total del crédito: ${dinero(c.total)}'),
                  if (c.nota.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.nota),
                  ],
                ],
              ),
              Seccion(
                titulo: 'Cuotas pagadas',
                extra: c.cuotasPrevias > 0
                    ? '+${c.cuotasPrevias} antes de la app'
                    : null,
                child: pagos.isEmpty
                    ? const Vacio('Aún no hay cuotas registradas.')
                    : Column(children: [for (final m in pagos) FilaPago(m)]),
              ),
            ],
          ),
        );
      },
    );
  }
}
