package com.personal.finanzas

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Botón del panel de ajustes rápidos (deslizando desde arriba) que abre la app
 * directamente en la [accion] indicada.
 */
abstract class AccesoRapidoTile(private val accion: String) : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        if (isLocked) unlockAndRun { abrirApp() } else abrirApp()
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun abrirApp() {
        val intent = Intent(this, MainActivity::class.java)
            .putExtra(MainActivity.EXTRA_ACCION, accion)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Un requestCode por acción para que los PendingIntent no se pisen entre sí.
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this, accion.hashCode(), intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}

class IngresoRapidoTile : AccesoRapidoTile("ingreso")

class GastoRapidoTile : AccesoRapidoTile("gasto")

class AbonoRapidoTile : AccesoRapidoTile("abono")
