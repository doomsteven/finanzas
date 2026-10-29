import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'formularios.dart';

/// Lo que se configura una vez: presupuestos mensuales y gastos fijos.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState;
        final totalPresupuestos =
            s.presupuestos.fold(0.0, (total, p) => total + p.monto);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card.outlined(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('¿Qué va dónde?'),
                subtitle: const Text(
                  'Presupuesto: gastos que varían (comida, transporte).\n'
                  'Gasto fijo: mismo monto cada mes (alquiler, internet).',
                ),
              ),
            ),
            Seccion(
              titulo: 'Presupuestos mensuales',
              extra: dinero(totalPresupuestos),
              child: s.presupuestos.isEmpty
                  ? const Vacio('Ej. Alimentación \$100 al mes.')
                  : Column(
                      children: [
                        for (final p in s.presupuestos)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => abrirFormPresupuesto(context, p),
                            leading: CircleAvatar(
                                child: Icon(iconoCategoria(p.categoria))),
                            title: Text(p.categoria),
                            subtitle: const Text('Cada mes'),
                            trailing: Text(
                              dinero(p.monto),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
            ),
            Seccion(
              titulo: 'Gastos fijos',
              extra: dinero(s.totalFijos),
              child: s.fijos.isEmpty
                  ? const Vacio('Ej. Alquiler, internet, luz.')
                  : Column(
                      children: [
                        for (final f in s.fijos)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            enabled: f.activo,
                            onTap: () => abrirFormFijo(context, f),
                            leading: CircleAvatar(
                                child: Icon(iconoCategoria(f.categoria))),
                            title: Text(f.nombre),
                            subtitle: Text(f.activo
                                ? 'Día ${f.diaPago} de cada mes'
                                : 'Pausado'),
                            trailing: Text(
                              dinero(f.monto),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
