import 'package:flutter/material.dart';

import 'format.dart';
import 'models.dart';
import 'state.dart';

/// Título de sección con un dato opcional a la derecha (total, conteo...).
class Seccion extends StatelessWidget {
  const Seccion({
    super.key,
    required this.titulo,
    this.extra,
    this.colorExtra,
    required this.child,
  });

  final String titulo;
  final String? extra;
  final Color? colorExtra;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: texto.titleMedium)),
              if (extra != null)
                Text(
                  extra!,
                  style: colorExtra == null
                      ? texto.labelLarge
                      : texto.titleMedium?.copyWith(
                          color: colorExtra, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class Vacio extends StatelessWidget {
  const Vacio(this.mensaje, {super.key, this.centrado = false});

  final String mensaje;
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      mensaje,
      textAlign: centrado ? TextAlign.center : TextAlign.start,
      style: TextStyle(color: Theme.of(context).colorScheme.outline),
    );
    return centrado
        ? Center(child: Padding(padding: const EdgeInsets.all(32), child: texto))
        : Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: texto);
  }
}

/// Una cifra con icono de color: verde entra, rojo sale.
class Cifra extends StatelessWidget {
  const Cifra({
    super.key,
    required this.icono,
    required this.color,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final Color color;
  final String etiqueta;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icono, size: 18, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: Theme.of(context).textTheme.labelMedium),
            Text(dinero(valor),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class Barra extends StatelessWidget {
  const Barra(this.valor, {super.key, this.color, this.alto = 6});

  final double valor;
  final Color? color;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: valor.isFinite ? valor.clamp(0, 1) : 0,
      minHeight: alto,
      color: color,
      borderRadius: BorderRadius.circular(alto / 2),
    );
  }
}

class Inicial extends StatelessWidget {
  const Inicial(this.nombre, {super.key, required this.color});

  final String nombre;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        nombre.isEmpty ? '?' : nombre.characters.first.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Tarjeta grande de cabecera: etiqueta, monto destacado y contenido extra.
class TarjetaMonto extends StatelessWidget {
  const TarjetaMonto({
    super.key,
    required this.etiqueta,
    required this.monto,
    required this.color,
    this.children = const [],
  });

  final String etiqueta;
  final double monto;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    // Color sólido: uno semitransparente se mezcla con la sombra y se ve gris.
    final fondo = Color.alphaBlend(
        color.withValues(alpha: 0.12), Theme.of(context).colorScheme.surface);
    return Card(
      color: fondo,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: texto.labelLarge),
            Text(
              dinero(monto),
              style: texto.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Fila de un movimiento ligado (cuota, cobro) que se borra deslizando.
class FilaPago extends StatelessWidget {
  const FilaPago(this.m, {super.key});

  final Movimiento m;

  @override
  Widget build(BuildContext context) {
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
            content: Text('Pago de ${dinero(m.monto)} eliminado'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => appState.guardarMovimiento(m),
            ),
          ));
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.payments_outlined),
        title: Text(fechaLarga(m.fecha)),
        trailing: Text(
          dinero(m.monto),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class Opcion {
  const Opcion(this.icono, this.titulo, this.subtitulo, this.accion);

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final void Function(BuildContext context) accion;
}

/// Hoja inferior para elegir qué agregar.
Future<void> elegirOpcion(BuildContext context, List<Opcion> opciones) async {
  final elegida = await showModalBottomSheet<Opcion>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in opciones)
            ListTile(
              leading: Icon(o.icono),
              title: Text(o.titulo),
              subtitle: Text(o.subtitulo),
              onTap: () => Navigator.pop(context, o),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (elegida != null && context.mounted) elegida.accion(context);
}
