import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';

Future<void> _abrir(BuildContext context, Widget pantalla) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));

Future<void> abrirFormMovimiento(BuildContext context, [Movimiento? m]) =>
    _abrir(context, FormMovimiento(movimiento: m));

/// Formulario de un movimiento nuevo con el tipo ya elegido (accesos rápidos).
Future<void> abrirFormNuevo(BuildContext context, TipoMovimiento tipo) =>
    _abrir(context, FormMovimiento(tipoInicial: tipo));

Future<void> abrirFormFijo(BuildContext context, [GastoFijo? f]) =>
    _abrir(context, FormFijo(fijo: f));

Future<void> abrirFormPresupuesto(BuildContext context, [Presupuesto? p]) =>
    _abrir(context, FormPresupuesto(presupuesto: p));

Future<void> abrirFormCredito(BuildContext context, [Credito? c]) =>
    _abrir(context, FormCredito(credito: c));

Future<void> abrirFormTrabajo(BuildContext context, [Trabajo? t]) =>
    _abrir(context, FormTrabajo(trabajo: t));

Future<void> abrirFormPrestamo(BuildContext context, [Prestamo? p]) =>
    _abrir(context, FormPrestamo(prestamo: p));

Future<void> abrirFormCobro(BuildContext context, Trabajo t) {
  final anticipo = appState.cobradoDe(t) == 0;
  return _abrir(
    context,
    _FormMontoRapido(
      titulo: anticipo ? 'Anticipo · ${t.cliente}' : 'Cobro · ${t.cliente}',
      etiquetaFalta: 'Te falta cobrar',
      falta: appState.faltaDe(t),
      color: colorIngreso,
      textoBoton: anticipo ? 'Guardar anticipo' : 'Guardar cobro',
      onGuardar: (monto, fecha) => appState.registrarCobro(t, monto, fecha),
    ),
  );
}

Future<void> abrirFormAbono(BuildContext context, Prestamo p) => _abrir(
      context,
      _FormMontoRapido(
        titulo: p.meDeben ? 'Abono de ${p.persona}' : 'Abono a ${p.persona}',
        etiquetaFalta: p.meDeben ? 'Te falta cobrar' : 'Te falta pagar',
        falta: appState.saldoDe(p),
        color: p.meDeben ? colorIngreso : colorGasto,
        textoBoton: 'Guardar abono',
        onGuardar: (monto, fecha) => appState.guardarAbono(
            Abono(prestamoId: p.id!, monto: monto, fecha: fecha)),
      ),
    );

double? _leerMonto(String? texto) =>
    double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

String? _validarMonto(String? texto) {
  final monto = _leerMonto(texto);
  if (monto == null || monto <= 0) return 'Ingresa un monto válido';
  return null;
}

String _montoInicial(double? monto) =>
    monto == null ? '' : monto.toStringAsFixed(2);

String? _validarTexto(String? t, String mensaje) =>
    (t == null || t.trim().isEmpty) ? mensaje : null;

Future<bool> _confirmarBorrado(BuildContext context, String que,
        {String? detalle}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar $que?'),
        content: detalle == null ? null : Text(detalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;

Future<DateTime?> _elegirDia(BuildContext context, DateTime inicial) =>
    showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

/// Estructura común: barra con título y papelera, campos y botón Guardar.
class _Pantalla extends StatelessWidget {
  const _Pantalla({
    required this.form,
    required this.titulo,
    required this.campos,
    required this.onGuardar,
    this.onEliminar,
    this.textoBoton = 'Guardar',
  });

  final GlobalKey<FormState> form;
  final String titulo;
  final List<Widget> campos;
  final VoidCallback onGuardar;
  final VoidCallback? onEliminar;
  final String textoBoton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          if (onEliminar != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onEliminar,
            ),
        ],
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final campo in campos) ...[campo, const SizedBox(height: 16)],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onGuardar,
              icon: const Icon(Icons.check),
              label: Text(textoBoton),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.controller,
    required this.etiqueta,
    required this.icono,
    this.autofocus = false,
    this.validator,
    this.mayusculas = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String etiqueta;
  final IconData icono;
  final bool autofocus;
  final FormFieldValidator<String>? validator;
  final TextCapitalization mayusculas;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: mayusculas,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class _CampoMonto extends StatelessWidget {
  const _CampoMonto({
    required this.controller,
    required this.etiqueta,
    this.autofocus = false,
    this.validator = _validarMonto,
    this.ayuda,
    this.onChanged,
  });

  final TextEditingController controller;
  final String etiqueta;
  final bool autofocus;
  final FormFieldValidator<String> validator;
  final String? ayuda;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.attach_money),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

/// Campo de número entero (cantidad de cuotas).
class _CampoEntero extends StatelessWidget {
  const _CampoEntero({
    required this.controller,
    required this.etiqueta,
    required this.icono,
    required this.minimo,
    this.onChanged,
  });

  final TextEditingController controller;
  final String etiqueta;
  final IconData icono;
  final int minimo;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      ),
      validator: (t) {
        final n = int.tryParse((t ?? '').trim());
        return n == null || n < minimo ? 'Ingresa un número válido' : null;
      },
      onChanged: onChanged,
    );
  }
}

/// Campo de fecha con el mismo aspecto que los demás campos del formulario.
class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.texto,
    required this.onTap,
    this.icono = Icons.calendar_today_outlined,
    this.onBorrar,
  });

  final String texto;
  final VoidCallback onTap;
  final IconData icono;
  final VoidCallback? onBorrar;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      leading: Icon(icono),
      title: Text(texto),
      trailing: onBorrar == null
          ? null
          : IconButton(icon: const Icon(Icons.close), onPressed: onBorrar),
      onTap: onTap,
    );
  }
}

class _SelectorDia extends StatelessWidget {
  const _SelectorDia({required this.valor, required this.onChanged});

  final int valor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: valor,
      decoration: const InputDecoration(
        labelText: 'Día de pago',
        prefixIcon: Icon(Icons.event_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        for (var d = 1; d <= 31; d++)
          DropdownMenuItem(value: d, child: Text('Día $d')),
      ],
      onChanged: (d) => onChanged(d!),
    );
  }
}

class _SelectorCategoria extends StatelessWidget {
  const _SelectorCategoria({
    super.key,
    required this.categorias,
    required this.valor,
    required this.onChanged,
  });

  final Map<String, IconData> categorias;
  final String valor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: categorias.containsKey(valor) ? valor : categorias.keys.first,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final c in categorias.entries)
          DropdownMenuItem(
            value: c.key,
            child: Row(
              children: [
                Icon(c.value, size: 20),
                const SizedBox(width: 12),
                Text(c.key),
              ],
            ),
          ),
      ],
      onChanged: (c) => onChanged(c!),
    );
  }
}

// -----------------------------------------------------------------------------
// Movimiento

class FormMovimiento extends StatefulWidget {
  const FormMovimiento({super.key, this.movimiento, this.tipoInicial});

  final Movimiento? movimiento;
  final TipoMovimiento? tipoInicial;

  @override
  State<FormMovimiento> createState() => _FormMovimientoState();
}

class _FormMovimientoState extends State<FormMovimiento> {
  final _form = GlobalKey<FormState>();
  late final Movimiento? _original = widget.movimiento;
  late TipoMovimiento _tipo =
      _original?.tipo ?? widget.tipoInicial ?? TipoMovimiento.gasto;
  late String _categoria = _original?.categoria ?? _categoriaInicial(_tipo);
  late DateTime _fecha = _original?.fecha ?? appState.fechaSugerida;
  late final _monto = TextEditingController(text: _montoInicial(_original?.monto));
  late final _descripcion = TextEditingController(text: _original?.descripcion);

  /// Gasto: la primera categoría con presupuesto (lo más habitual, ej. comida).
  static String _categoriaInicial(TipoMovimiento tipo) {
    if (tipo == TipoMovimiento.gasto && appState.presupuestos.isNotEmpty) {
      return appState.presupuestos.first.categoria;
    }
    return categoriasDe(tipo).keys.first;
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _cambiarTipo(TipoMovimiento tipo) {
    setState(() {
      _tipo = tipo;
      if (!categoriasDe(tipo).containsKey(_categoria)) {
        _categoria = _categoriaInicial(tipo);
      }
    });
  }

  /// Cuánto queda del presupuesto de la categoría elegida, si tiene.
  String? get _ayudaPresupuesto {
    if (_tipo != TipoMovimiento.gasto || _original?.esLibre == false) return null;
    final p = appState.presupuestoDe(_categoria);
    if (p == null) return null;
    // Al editar, el monto original ya está descontado.
    final queda = appState.quedaEn(p) + (_original?.monto ?? 0);
    return queda >= 0
        ? 'Presupuesto: te quedan ${dinero(queda)} de ${dinero(p.monto)}'
        : 'Presupuesto: te pasaste ${dinero(-queda)}';
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await appState.guardarMovimiento(Movimiento(
      id: _original?.id,
      tipo: _tipo,
      monto: _leerMonto(_monto.text)!,
      categoria: _categoria,
      descripcion: _descripcion.text.trim(),
      fecha: _fecha,
      gastoFijoId: _original?.gastoFijoId,
      creditoId: _original?.creditoId,
      trabajoId: _original?.trabajoId,
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    if (!await _confirmarBorrado(context, 'este movimiento')) return;
    await appState.eliminarMovimiento(_original!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ayuda = _ayudaPresupuesto;
    return _Pantalla(
      form: _form,
      titulo: _original == null ? 'Nuevo movimiento' : 'Editar movimiento',
      onGuardar: _guardar,
      onEliminar: _original == null ? null : _eliminar,
      campos: [
        SegmentedButton<TipoMovimiento>(
          segments: const [
            ButtonSegment(
              value: TipoMovimiento.gasto,
              label: Text('Gasto'),
              icon: Icon(Icons.north_east),
            ),
            ButtonSegment(
              value: TipoMovimiento.ingreso,
              label: Text('Ingreso'),
              icon: Icon(Icons.south_west),
            ),
          ],
          selected: {_tipo},
          onSelectionChanged: (s) => _cambiarTipo(s.first),
        ),
        _CampoMonto(
          controller: _monto,
          etiqueta: 'Monto',
          autofocus: _original == null,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectorCategoria(
              key: ValueKey(_tipo),
              categorias: categoriasDe(_tipo),
              valor: _categoria,
              onChanged: (c) => setState(() => _categoria = c),
            ),
            if (ayuda != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Text(
                  ayuda,
                  style: TextStyle(
                    color: ayuda.contains('pasaste') ? colorGasto : colorIngreso,
                  ),
                ),
              ),
          ],
        ),
        _CampoTexto(
          controller: _descripcion,
          etiqueta: 'Descripción (opcional)',
          icono: Icons.notes,
        ),
        _CampoFecha(
          texto: fechaLarga(_fecha),
          onTap: () async {
            final elegida = await _elegirDia(context, _fecha);
            if (elegida != null) setState(() => _fecha = elegida);
          },
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Gasto fijo

class FormFijo extends StatefulWidget {
  const FormFijo({super.key, this.fijo});

  final GastoFijo? fijo;

  @override
  State<FormFijo> createState() => _FormFijoState();
}

class _FormFijoState extends State<FormFijo> {
  final _form = GlobalKey<FormState>();
  late final GastoFijo? _original = widget.fijo;
  late String _categoria = _original?.categoria ?? 'Servicios';
  late int _dia = _original?.diaPago ?? DateTime.now().day;
  late bool _activo = _original?.activo ?? true;
  late final _nombre = TextEditingController(text: _original?.nombre);
  late final _monto = TextEditingController(text: _montoInicial(_original?.monto));

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await appState.guardarFijo(GastoFijo(
      id: _original?.id,
      nombre: _nombre.text.trim(),
      monto: _leerMonto(_monto.text)!,
      categoria: _categoria,
      diaPago: _dia,
      activo: _activo,
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    if (!await _confirmarBorrado(context, '"${_original!.nombre}"')) return;
    await appState.eliminarFijo(_original);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      form: _form,
      titulo: _original == null ? 'Nuevo gasto fijo' : 'Editar gasto fijo',
      onGuardar: _guardar,
      onEliminar: _original == null ? null : _eliminar,
      campos: [
        _CampoTexto(
          controller: _nombre,
          etiqueta: 'Nombre (ej. Alquiler, Luz, Internet)',
          icono: Icons.label_outline,
          autofocus: _original == null,
          validator: (t) => _validarTexto(t, 'Escribe un nombre'),
        ),
        _CampoMonto(controller: _monto, etiqueta: 'Monto mensual'),
        _SelectorCategoria(
          categorias: categoriasGasto,
          valor: _categoria,
          onChanged: (c) => _categoria = c,
        ),
        _SelectorDia(valor: _dia, onChanged: (d) => _dia = d),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Activo'),
          subtitle: const Text('Desactívalo si dejaste de pagarlo por un tiempo'),
          value: _activo,
          onChanged: (v) => setState(() => _activo = v),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Presupuesto

class FormPresupuesto extends StatefulWidget {
  const FormPresupuesto({super.key, this.presupuesto});

  final Presupuesto? presupuesto;

  @override
  State<FormPresupuesto> createState() => _FormPresupuestoState();
}

class _FormPresupuestoState extends State<FormPresupuesto> {
  final _form = GlobalKey<FormState>();
  late final Presupuesto? _original = widget.presupuesto;

  /// Solo categorías que aún no tienen presupuesto (más la propia al editar).
  late final Map<String, IconData> _libres = {
    for (final c in categoriasGasto.entries)
      if (c.key != categoriaCuotas &&
          (c.key == _original?.categoria || appState.presupuestoDe(c.key) == null))
        c.key: c.value,
  };
  late String _categoria = _original?.categoria ?? _libres.keys.first;
  late final _monto = TextEditingController(text: _montoInicial(_original?.monto));

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await appState.guardarPresupuesto(Presupuesto(
      id: _original?.id,
      categoria: _categoria,
      monto: _leerMonto(_monto.text)!,
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    final que = 'el presupuesto de ${_original!.categoria}';
    if (!await _confirmarBorrado(context, que)) return;
    await appState.eliminarPresupuesto(_original);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      form: _form,
      titulo: _original == null ? 'Nuevo presupuesto' : 'Editar presupuesto',
      onGuardar: _guardar,
      onEliminar: _original == null ? null : _eliminar,
      campos: [
        _SelectorCategoria(
          categorias: _libres,
          valor: _categoria,
          onChanged: (c) => _categoria = c,
        ),
        _CampoMonto(
          controller: _monto,
          etiqueta: 'Máximo al mes',
          autofocus: _original == null,
          ayuda: 'Cada gasto de esta categoría se descuenta. Empieza de cero cada mes.',
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Crédito

class FormCredito extends StatefulWidget {
  const FormCredito({super.key, this.credito});

  final Credito? credito;

  @override
  State<FormCredito> createState() => _FormCreditoState();
}

class _FormCreditoState extends State<FormCredito> {
  final _form = GlobalKey<FormState>();
  late final Credito? _original = widget.credito;
  late int _dia = _original?.diaPago ?? DateTime.now().day;
  late final _nombre = TextEditingController(text: _original?.nombre);
  late final _cuota = TextEditingController(text: _montoInicial(_original?.cuota));
  late final _numCuotas =
      TextEditingController(text: _original?.numCuotas.toString());
  late final _previas =
      TextEditingController(text: (_original?.cuotasPrevias ?? 0).toString());
  late final _nota = TextEditingController(text: _original?.nota);

  @override
  void dispose() {
    for (final c in [_nombre, _cuota, _numCuotas, _previas, _nota]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _total {
    final cuota = _leerMonto(_cuota.text);
    final n = int.tryParse(_numCuotas.text.trim());
    if (cuota == null || n == null) return null;
    return 'Total del crédito: ${dinero(cuota * n)}';
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final hoy = DateTime.now();
    await appState.guardarCredito(Credito(
      id: _original?.id,
      nombre: _nombre.text.trim(),
      cuota: _leerMonto(_cuota.text)!,
      numCuotas: int.parse(_numCuotas.text.trim()),
      cuotasPrevias: int.parse(_previas.text.trim()),
      diaPago: _dia,
      inicio: _original?.inicio ?? DateTime(hoy.year, hoy.month),
      nota: _nota.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    if (!await _confirmarBorrado(context, '"${_original!.nombre}"',
        detalle: 'Las cuotas pagadas quedan en tus movimientos.')) {
      return;
    }
    await appState.eliminarCredito(_original);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      form: _form,
      titulo: _original == null ? 'Nuevo crédito' : 'Editar crédito',
      onGuardar: _guardar,
      onEliminar: _original == null ? null : _eliminar,
      campos: [
        _CampoTexto(
          controller: _nombre,
          etiqueta: 'Nombre (ej. Refrigeradora, Préstamo banco)',
          icono: Icons.credit_card_outlined,
          autofocus: _original == null,
          validator: (t) => _validarTexto(t, 'Escribe un nombre'),
        ),
        _CampoMonto(
          controller: _cuota,
          etiqueta: 'Cuota mensual',
          ayuda: _total,
          onChanged: (_) => setState(() {}),
        ),
        _CampoEntero(
          controller: _numCuotas,
          etiqueta: 'Número de cuotas',
          icono: Icons.format_list_numbered,
          minimo: 1,
          onChanged: (_) => setState(() {}),
        ),
        _CampoEntero(
          controller: _previas,
          etiqueta: 'Cuotas que ya pagaste antes',
          icono: Icons.done_all,
          minimo: 0,
        ),
        _SelectorDia(valor: _dia, onChanged: (d) => _dia = d),
        _CampoTexto(
          controller: _nota,
          etiqueta: 'Nota (opcional)',
          icono: Icons.notes,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Trabajo

class FormTrabajo extends StatefulWidget {
  const FormTrabajo({super.key, this.trabajo});

  final Trabajo? trabajo;

  @override
  State<FormTrabajo> createState() => _FormTrabajoState();
}

class _FormTrabajoState extends State<FormTrabajo> {
  final _form = GlobalKey<FormState>();
  late final Trabajo? _original = widget.trabajo;
  late EstadoTrabajo _estado = _original?.estado ?? EstadoTrabajo.cotizado;
  late DateTime _fecha = _original?.fecha ?? DateTime.now();
  late DateTime? _entrega = _original?.entrega;
  late final _cliente = TextEditingController(text: _original?.cliente);
  late final _descripcion = TextEditingController(text: _original?.descripcion);
  late final _monto = TextEditingController(text: _montoInicial(_original?.monto));
  late final _nota = TextEditingController(text: _original?.nota);

  @override
  void dispose() {
    for (final c in [_cliente, _descripcion, _monto, _nota]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validarMontoTrabajo(String? texto) {
    final error = _validarMonto(texto);
    if (error != null || _original == null) return error;
    final cobrado = appState.cobradoDe(_original);
    if (_leerMonto(texto)! < cobrado) {
      return 'Ya cobraste ${dinero(cobrado)}; no puede ser menos';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await appState.guardarTrabajo(Trabajo(
      id: _original?.id,
      cliente: _cliente.text.trim(),
      descripcion: _descripcion.text.trim(),
      monto: _leerMonto(_monto.text)!,
      estado: _estado,
      fecha: _fecha,
      entrega: _entrega,
      nota: _nota.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    if (!await _confirmarBorrado(context, 'este trabajo',
        detalle: 'Lo cobrado queda en tus ingresos.')) {
      return;
    }
    await appState.eliminarTrabajo(_original!);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      form: _form,
      titulo: _original == null ? 'Nuevo trabajo' : 'Editar trabajo',
      onGuardar: _guardar,
      onEliminar: _original == null ? null : _eliminar,
      campos: [
        SegmentedButton<EstadoTrabajo>(
          showSelectedIcon: false,
          segments: [
            for (final e in EstadoTrabajo.values)
              ButtonSegment(value: e, label: Text(nombresEstado[e]!)),
          ],
          selected: {_estado},
          onSelectionChanged: (s) => setState(() => _estado = s.first),
        ),
        _CampoTexto(
          controller: _cliente,
          etiqueta: 'Cliente',
          icono: Icons.person_outline,
          autofocus: _original == null,
          mayusculas: TextCapitalization.words,
          validator: (t) => _validarTexto(t, 'Escribe el cliente'),
        ),
        _CampoTexto(
          controller: _descripcion,
          etiqueta: '¿Qué trabajo es? (opcional)',
          icono: Icons.design_services_outlined,
        ),
        _CampoMonto(
          controller: _monto,
          etiqueta: 'Valor total',
          validator: _validarMontoTrabajo,
        ),
        _CampoFecha(
          texto: '${nombresEstado[EstadoTrabajo.cotizado]} el ${fechaLarga(_fecha)}',
          onTap: () async {
            final elegida = await _elegirDia(context, _fecha);
            if (elegida != null) setState(() => _fecha = elegida);
          },
        ),
        _CampoFecha(
          icono: Icons.flag_outlined,
          texto: _entrega == null
              ? 'Fecha de entrega (opcional)'
              : 'Entregar el ${fechaLarga(_entrega!)}',
          onTap: () async {
            final elegida = await _elegirDia(context, _entrega ?? DateTime.now());
            if (elegida != null) setState(() => _entrega = elegida);
          },
          onBorrar: _entrega == null ? null : () => setState(() => _entrega = null),
        ),
        _CampoTexto(
          controller: _nota,
          etiqueta: 'Nota (opcional)',
          icono: Icons.notes,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Préstamo

class FormPrestamo extends StatefulWidget {
  const FormPrestamo({super.key, this.prestamo});

  final Prestamo? prestamo;

  @override
  State<FormPrestamo> createState() => _FormPrestamoState();
}

class _FormPrestamoState extends State<FormPrestamo> {
  final _form = GlobalKey<FormState>();
  late final Prestamo? _original = widget.prestamo;
  late TipoPrestamo _tipo = _original?.tipo ?? TipoPrestamo.meDeben;
  late DateTime _fecha = _original?.fecha ?? DateTime.now();
  late DateTime? _fechaLimite = _original?.fechaLimite;
  late final _persona = TextEditingController(text: _original?.persona);
  late final _monto = TextEditingController(text: _montoInicial(_original?.monto));
  late final _nota = TextEditingController(text: _original?.nota);

  @override
  void dispose() {
    for (final c in [_persona, _monto, _nota]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validarMontoPrestamo(String? texto) {
    final error = _validarMonto(texto);
    if (error != null || _original == null) return error;
    final pagado = appState.pagadoDe(_original);
    if (_leerMonto(texto)! < pagado) {
      return 'Ya se abonaron ${dinero(pagado)}; no puede ser menos';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await appState.guardarPrestamo(Prestamo(
      id: _original?.id,
      tipo: _tipo,
      persona: _persona.text.trim(),
      monto: _leerMonto(_monto.text)!,
      fecha: _fecha,
      fechaLimite: _fechaLimite,
      nota: _nota.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    final que = 'el préstamo de ${_original!.persona} y sus abonos';
    if (!await _confirmarBorrado(context, que)) return;
    await appState.eliminarPrestamo(_original);
    // También se cierra el detalle del préstamo, que ya no existe.
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return _Pantalla(
      form: _form,
      titulo: _original == null ? 'Nuevo préstamo' : 'Editar préstamo',
      onGuardar: _guardar,
      onEliminar: _original == null ? null : _eliminar,
      campos: [
        SegmentedButton<TipoPrestamo>(
          segments: const [
            ButtonSegment(
              value: TipoPrestamo.meDeben,
              label: Text('Me deben'),
              icon: Icon(Icons.south_west),
            ),
            ButtonSegment(
              value: TipoPrestamo.debo,
              label: Text('Debo'),
              icon: Icon(Icons.north_east),
            ),
          ],
          selected: {_tipo},
          onSelectionChanged: (s) => setState(() => _tipo = s.first),
        ),
        _CampoTexto(
          controller: _persona,
          etiqueta: _tipo == TipoPrestamo.meDeben
              ? '¿Quién te debe?'
              : '¿A quién le debes?',
          icono: Icons.person_outline,
          autofocus: _original == null,
          mayusculas: TextCapitalization.words,
          validator: (t) => _validarTexto(t, 'Escribe un nombre'),
        ),
        _CampoMonto(
          controller: _monto,
          etiqueta: 'Monto prestado',
          validator: _validarMontoPrestamo,
        ),
        _CampoFecha(
          texto: 'Prestado el ${fechaLarga(_fecha)}',
          onTap: () async {
            final elegida = await _elegirDia(context, _fecha);
            if (elegida != null) setState(() => _fecha = elegida);
          },
        ),
        _CampoFecha(
          icono: Icons.event_busy_outlined,
          texto: _fechaLimite == null
              ? 'Sin fecha límite (opcional)'
              : 'Pagar hasta el ${fechaLarga(_fechaLimite!)}',
          onTap: () async {
            final elegida =
                await _elegirDia(context, _fechaLimite ?? DateTime.now());
            if (elegida != null) setState(() => _fechaLimite = elegida);
          },
          onBorrar: _fechaLimite == null
              ? null
              : () => setState(() => _fechaLimite = null),
        ),
        _CampoTexto(
          controller: _nota,
          etiqueta: 'Nota (opcional)',
          icono: Icons.notes,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Cobros y abonos: un solo campo de monto, el ✓ del teclado guarda.

class _FormMontoRapido extends StatefulWidget {
  const _FormMontoRapido({
    required this.titulo,
    required this.etiquetaFalta,
    required this.falta,
    required this.color,
    required this.textoBoton,
    required this.onGuardar,
  });

  final String titulo;
  final String etiquetaFalta;
  final double falta;
  final Color color;
  final String textoBoton;
  final Future<void> Function(double monto, DateTime fecha) onGuardar;

  @override
  State<_FormMontoRapido> createState() => _FormMontoRapidoState();
}

class _FormMontoRapidoState extends State<_FormMontoRapido> {
  final _form = GlobalKey<FormState>();
  DateTime _fecha = DateTime.now();
  final _monto = TextEditingController();

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  String? _validar(String? texto) {
    final error = _validarMonto(texto);
    if (error != null) return error;
    if (_leerMonto(texto)! > widget.falta + 0.005) {
      return 'Solo falta ${dinero(widget.falta)}';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await widget.onGuardar(_leerMonto(_monto.text)!, _fecha);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return _Pantalla(
      form: _form,
      titulo: widget.titulo,
      textoBoton: widget.textoBoton,
      onGuardar: _guardar,
      campos: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.etiquetaFalta, style: texto.labelLarge),
            Text(
              dinero(widget.falta),
              style: texto.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: widget.color),
            ),
          ],
        ),
        TextFormField(
          controller: _monto,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // El ✓ del teclado guarda directamente: así es un solo paso.
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _guardar(),
          decoration: InputDecoration(
            labelText: 'Monto',
            prefixIcon: const Icon(Icons.attach_money),
            border: const OutlineInputBorder(),
            suffixIcon: TextButton(
              onPressed: () => _monto.text = widget.falta.toStringAsFixed(2),
              child: const Text('Todo'),
            ),
          ),
          validator: _validar,
        ),
        _CampoFecha(
          texto: fechaLarga(_fecha),
          onTap: () async {
            final elegida = await _elegirDia(context, _fecha);
            if (elegida != null) setState(() => _fecha = elegida);
          },
        ),
      ],
    );
  }
}
