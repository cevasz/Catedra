package com.catedra.catedra

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.AlarmClock
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "catedra/alarms").setMethodCallHandler { call, result ->
            when (call.method) {
                "setAlarm" -> result.success(
                    setAlarm(
                        hour = call.argument<Int>("hour")!!,
                        minute = call.argument<Int>("minute")!!,
                        isoDays = call.argument<List<Int>>("days").orEmpty(),
                        label = call.argument<String>("label").orEmpty(),
                    ),
                )
                "showAlarms" -> result.success(start(Intent(AlarmClock.ACTION_SHOW_ALARMS)))
                "canSetAlarms" -> result.success(
                    Intent(AlarmClock.ACTION_SET_ALARM).resolveActivity(packageManager) != null,
                )
                "requestNotifications" -> result.success(requestNotifications())
                "scheduleReminders" -> {
                    EvalReminders.schedule(
                        this,
                        channelName = call.argument<String>("channel").orEmpty(),
                        items = call.argument<List<Map<String, Any>>>("items").orEmpty(),
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Crea una alarma semanal en el Reloj del teléfono, sin abrir su pantalla.
     * Es el intent estándar de Android: lo atiende la app de reloj
     * predeterminada (en Samsung, el Reloj; Alarmy no lo acepta). Ninguna app
     * puede borrar después las alarmas que crea otra.
     */
    private fun setAlarm(hour: Int, minute: Int, isoDays: List<Int>, label: String): Boolean {
        // ISO (1 = lunes … 7 = domingo) → Calendar (1 = domingo … 7 = sábado).
        val days = ArrayList(isoDays.map { it % 7 + 1 })
        val intent = Intent(AlarmClock.ACTION_SET_ALARM)
            .putExtra(AlarmClock.EXTRA_HOUR, hour)
            .putExtra(AlarmClock.EXTRA_MINUTES, minute)
            .putExtra(AlarmClock.EXTRA_MESSAGE, label)
            .putExtra(AlarmClock.EXTRA_DAYS, days)
            .putExtra(AlarmClock.EXTRA_VIBRATE, true)
            .putExtra(AlarmClock.EXTRA_SKIP_UI, true)
        return start(intent)
    }

    private fun start(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    } catch (e: SecurityException) {
        false
    }

    /** Android 13+ pide permiso para notificar. Devuelve si ya lo tiene. */
    private fun requestNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        if (!granted) ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
        return granted
    }
}
