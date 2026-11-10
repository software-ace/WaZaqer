package ace.software.wazaqer

import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.function.Consumer

// Location through the platform LocationManager instead of a plugin: the
// common Flutter location plugins pull in Google Play Services, which
// F-Droid builds can't ship. Coarse accuracy is enough for prayer times.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wazaqer/location")
            .setMethodCallHandler { call, result ->
                if (call.method != "current") {
                    result.notImplemented()
                } else {
                    try {
                        current(result)
                    } catch (e: SecurityException) {
                        result.error("denied", e.message, null)
                    }
                }
            }
    }

    private fun current(result: MethodChannel.Result) {
        val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = lm.getProviders(true)
        if (providers.isEmpty()) return result.error("off", "location is off", null)

        // A recent cached fix is good enough and instant.
        val last = providers
            .mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }
        if (last != null) return result.success(last.toMap())

        val provider = if (LocationManager.NETWORK_PROVIDER in providers) {
            LocationManager.NETWORK_PROVIDER
        } else {
            providers.first()
        }
        var replied = false
        val reply = { l: Location? ->
            if (!replied) {
                replied = true
                if (l == null) result.error("none", "no fix", null) else result.success(l.toMap())
            }
        }
        if (Build.VERSION.SDK_INT >= 30) {
            lm.getCurrentLocation(provider, null, mainExecutor, Consumer { reply(it) })
        } else {
            @Suppress("DEPRECATION")
            lm.requestSingleUpdate(provider, LocationListener { reply(it) }, Looper.getMainLooper())
        }
    }

    private fun Location.toMap() = mapOf("lat" to latitude, "lng" to longitude)
}
