# Mis Finanzas

App Android (Flutter) para registrar ingresos, gastos y gastos fijos mensuales.
Todos los datos se guardan solo en el teléfono (SQLite), sin internet ni cuentas.

## Funciones

- **Resumen del mes**: balance, ingresos, gastos y cuánto falta pagar en fijos.
- **Gastos fijos del mes**: lista con casillas para marcarlos como pagados; avisa los vencidos.
- **Gastos por categoría**: cuánto se va en cada rubro y su porcentaje.
- **Movimientos**: historial agrupado por día. Toca uno para editarlo; deslízalo a la izquierda para borrarlo (con opción de deshacer).
- **Fijos**: alquiler, luz, internet, suscripciones... con su monto y día de pago. Se pueden pausar.
- Cambia de mes con las flechas de arriba.

## Compilar el APK (Windows)

1. Instala Flutter: https://docs.flutter.dev/get-started/install/windows/mobile
2. Instala Android Studio (trae el Android SDK): https://developer.android.com/studio
3. En una terminal:
   ```
   flutter doctor
   flutter doctor --android-licenses
   ```
4. Dentro de esta carpeta, genera los archivos de Android (no toca `lib/`):
   ```
   flutter create --org com.personal --project-name finanzas --platforms android .
   flutter pub get
   ```
5. (Opcional) Cambia el nombre visible de la app en
   `android/app/src/main/AndroidManifest.xml`: `android:label="Mis Finanzas"`.
6. Compila:
   ```
   flutter build apk --release
   ```
   El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.
7. Pásalo al teléfono e instálalo (acepta "instalar apps de origen desconocido").

Para probar con el teléfono conectado por USB (depuración USB activada): `flutter run`.

## Moneda

El símbolo se cambia en `lib/format.dart` (por defecto `$`).
