import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'deudas.dart';
import 'formularios.dart';
import 'mes.dart';
import 'movimientos.dart';
import 'plan.dart';
import 'prestamos.dart';
import 'trabajos.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  static const _tabMes = 0;
  static const _tabTrabajos = 2;
  static const _tabDeudas = 3;
  static const _tabPlan = 4;

  /// Accesos rápidos de Android: mosaicos de ajustes rápidos y atajos del ícono.
  static const _accesos = MethodChannel('finanzas/accesos');

  @override
  void initState() {
    super.initState();
    _accesos.setMethodCallHandler((call) async {
      if (call.method == 'abrir') await _abrirAcceso(call.arguments as String);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accion = await _accesos.invokeMethod<String>('accionInicial');
      if (accion != null) await _abrirAcceso(accion);
    });
  }

  Future<void> _abrirAcceso(String accion) async {
    if (!mounted) return;
    // Cierra formularios abiertos para no apilarlos.
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (accion == 'abono') {
      setState(() => _tab = _tabDeudas);
      await elegirPrestamoParaAbono(context);
      return;
    }
    setState(() => _tab = _tabMes);
    await appState.irAlMesActual();
    if (mounted) await abrirFormNuevo(context, TipoMovimiento.values.byName(accion));
  }

  void _agregar() => switch (_tab) {
        _tabTrabajos => abrirFormTrabajo(context),
        _tabDeudas => elegirOpcion(context, [
            Opcion(Icons.credit_card_outlined, 'Crédito',
                'Cuotas mensuales: electrodomésticos, banco...', abrirFormCredito),
            Opcion(Icons.handshake_outlined, 'Préstamo',
                'Dinero con una persona: me deben o debo', abrirFormPrestamo),
          ]),
        _tabPlan => elegirOpcion(context, [
            Opcion(Icons.donut_large_outlined, 'Presupuesto',
                'Gastos que varían: comida, transporte...', abrirFormPresupuesto),
            Opcion(Icons.event_repeat_outlined, 'Gasto fijo',
                'Mismo monto cada mes: alquiler, internet...', abrirFormFijo),
          ]),
        _ => abrirFormMovimiento(context),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: switch (_tab) {
          _tabTrabajos => const Text('Trabajos'),
          _tabDeudas => const Text('Deudas'),
          _tabPlan => const Text('Plan mensual'),
          _ => const SelectorMes(),
        },
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          MesScreen(),
          MovimientosScreen(),
          TrabajosScreen(),
          DeudasScreen(),
          PlanScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        icon: const Icon(Icons.add),
        label: Text(switch (_tab) {
          _tabTrabajos => 'Trabajo',
          _tabDeudas || _tabPlan => 'Agregar',
          _ => 'Movimiento',
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Mes',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.design_services_outlined),
            selectedIcon: Icon(Icons.design_services),
            label: 'Trabajos',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Deudas',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Plan',
          ),
        ],
      ),
    );
  }
}

class SelectorMes extends StatelessWidget {
  const SelectorMes({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => appState.cambiarMes(-1),
          ),
          Text(mesTexto(appState.mes)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => appState.cambiarMes(1),
          ),
        ],
      ),
    );
  }
}
