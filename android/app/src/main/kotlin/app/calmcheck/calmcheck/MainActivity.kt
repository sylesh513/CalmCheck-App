package app.calmcheck.calmcheck

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.CancellationSignal
import android.provider.Settings
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The two small things this app talks to Android about directly, rather than
 * taking on a dependency for: opening its own settings page, and answering
 * "where is this phone" — once, in the foreground, only when somebody presses
 * the button that needs it.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "app.calmcheck/device_settings"
    private val locationRequestCode = 8801

    private var pendingLocation: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAppSettings" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }

                    "openNotificationSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }

                    // Which country the phone is actually in, for the crisis
                    // helplines. The network's country beats the SIM's, which
                    // beats the language locale — somebody travelling needs the
                    // numbers for where they are standing, not for the language
                    // they read in. Neither needs a permission.
                    "countryCode" -> {
                        val telephony =
                            getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                        val country = telephony?.networkCountryIso?.takeIf { it.isNotBlank() }
                            ?: telephony?.simCountryIso?.takeIf { it.isNotBlank() }
                        result.success(country?.uppercase())
                    }

                    "currentLocation" -> requestLocation(result)

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasLocationPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    /**
     * Answers with a lat/lon map, or null. Null is an ordinary outcome — no
     * permission, location switched off, no fix in time — and the caller sends
     * its message without it rather than making anybody wait.
     */
    private fun requestLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            if (pendingLocation != null) {
                result.success(null)
                return
            }
            pendingLocation = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.ACCESS_COARSE_LOCATION,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                ),
                locationRequestCode,
            )
            return
        }
        resolveLocation(result)
    }

    private fun resolveLocation(result: MethodChannel.Result) {
        val manager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (manager == null || !LocationManagerCompat.isLocationEnabled(manager)) {
            result.success(null)
            return
        }

        var answered = false
        fun answer(location: Location?) {
            if (answered) return
            answered = true
            result.success(
                location?.let {
                    mapOf("latitude" to it.latitude, "longitude" to it.longitude)
                }
            )
        }

        // A fix that is a few minutes old is still the right street, and it is
        // available instantly. It is used only if a live one does not arrive.
        val cached = lastKnownLocation(manager)

        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.FUSED_PROVIDER,
        ).filter {
            try {
                manager.isProviderEnabled(it)
            } catch (e: IllegalArgumentException) {
                false
            }
        }
        if (providers.isEmpty()) {
            answer(cached)
            return
        }

        val pending = providers.size
        var settled = 0
        try {
            for (provider in providers) {
                LocationManagerCompat.getCurrentLocation(
                    manager,
                    provider,
                    CancellationSignal(),
                    mainExecutor,
                ) { location ->
                    settled++
                    if (location != null) {
                        answer(location)
                    } else if (settled == pending) {
                        // Nothing live from any provider; the cached fix is
                        // better than sending no location at all.
                        answer(cached)
                    }
                }
            }
        } catch (e: SecurityException) {
            answer(cached)
        }
    }

    private fun lastKnownLocation(manager: LocationManager): Location? {
        var best: Location? = null
        try {
            for (provider in manager.getProviders(true)) {
                val candidate = manager.getLastKnownLocation(provider) ?: continue
                if (best == null || candidate.time > best!!.time) best = candidate
            }
        } catch (e: SecurityException) {
            return null
        }
        return best
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != locationRequestCode) return

        val pending = pendingLocation ?: return
        pendingLocation = null
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
            resolveLocation(pending)
        } else {
            pending.success(null)
        }
    }
}
