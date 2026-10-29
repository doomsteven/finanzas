import 'package:finanzas/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fechaIso rellena con ceros', () {
    expect(fechaIso(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('el día 31 se ajusta en meses cortos', () {
    final f = GastoFijo(nombre: 'Alquiler', monto: 100, categoria: 'Vivienda', diaPago: 31);
    expect(f.vencimientoEn(DateTime(2026, 2)), DateTime(2026, 2, 28));
    expect(f.vencimientoEn(DateTime(2026, 3)), DateTime(2026, 3, 31));
  });
}
