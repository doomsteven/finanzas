package com.personal.finanzas

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Pasa a Flutter los accesos rápidos (mosaico de ajustes rápidos y atajos del ícono). */
class MainActivity : FlutterActivity() {
    private var canal: MethodChannel? = null
    private var accionPendiente: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        accionPendiente = accionDe(intent)
        canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "accionInicial") {
                    result.success(accionPendiente)
                    accionPendiente = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    // La app ya estaba abierta: se avisa a Flutter directamente.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        accionDe(intent)?.let { canal?.invokeMethod("abrir", it) }
    }

    // Al volver desde "recientes" Android repite el intent original; ahí no se reabre el formulario.
    private fun accionDe(intent: Intent?): String? {
        if (intent == null || intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        return intent.getStringExtra(EXTRA_ACCION).also { intent.removeExtra(EXTRA_ACCION) }
    }

    companion object {
        const val CANAL = "finanzas/accesos"
        const val EXTRA_ACCION = "accion"
    }
}
