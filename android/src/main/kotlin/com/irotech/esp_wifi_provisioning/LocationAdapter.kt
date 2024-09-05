package com.irotech.esp_wifi_provisioning

import android.Manifest
import android.app.Activity
import android.app.Activity.*
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.location.LocationManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.*
import com.google.android.gms.tasks.Task
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

private const val CHANNEL = "esp_wifi_provisioning/location_adapter";

class LocationAdapter: FlutterPlugin, MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener,
    ActivityAware, PluginRegistry.ActivityResultListener {
    private val LOG_TAG = "@[$CHANNEL]@"

    private val REQUEST_LOCATION_ACTIVITY = 1407199901

    private val REQUEST_FINE_LOCATION_PERMISSION = 1407199902

    private lateinit var applicationContext: Context

    private lateinit var platformActivity: Activity

    private var activityBinding: ActivityPluginBinding? = null

    private lateinit var channel: MethodChannel

    private lateinit var locationManager: LocationManager

    private lateinit var locationRequest: LocationRequest

    private fun setupCallbackChannels(binaryMessenger: BinaryMessenger) {
        Log.d(LOG_TAG,"Method and events callbacks setup")

        channel = MethodChannel(binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        setupCallbackChannels(binding.binaryMessenger)

        locationManager = applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    }

    private var resultCallback: MethodChannel.Result? = null
    private var resultCallbackOptionalError: String = ""
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if(resultCallback!=null){
            resultCallback?.error("",resultCallbackOptionalError,null)
            resultCallback = null
        }

        when (call.method) {
            "isLocationServiceEnabled" -> {
                val isLocationServiceEnabled = isLocationServiceEnabled();
                result.success(isLocationServiceEnabled)
                return
            }
            "requestEnableLocationService" -> {
                requestEnableLocationService()
                resultCallback = result
                resultCallbackOptionalError = "Waiting for location service to be enabled."
                return
            }
            "hasLocationPermissions" -> {
                val hasLocationPermissions = hasLocationPermissions()
                result.success(hasLocationPermissions)
                return
            }
            "requestLocationPermission" -> {
                val hasLocationPermissions = hasLocationPermissions()
                if(hasLocationPermissions){
                    result.success(true)
                    return
                }
                requestLocationPermission()
                resultCallback = result
                resultCallbackOptionalError = "Waiting for location service response."
            }
            else -> result.notImplemented()
        }
    }

    private fun requestEnableLocationService(){
        locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000)
            .setWaitForAccurateLocation(false)
            .build()

        val builder = LocationSettingsRequest.Builder()
            .addLocationRequest(locationRequest)
        val client: SettingsClient = LocationServices.getSettingsClient(platformActivity)
        val task: Task<LocationSettingsResponse> = client.checkLocationSettings(builder.build())

        task.addOnSuccessListener { _ ->
            resultCallback?.success(true)
            resultCallback = null
        }

        task.addOnFailureListener { exception ->
            if (exception is ResolvableApiException) {
                try {
                    // Show the dialog by calling startResolutionForResult(),
                    exception.startResolutionForResult(platformActivity, REQUEST_LOCATION_ACTIVITY)
                } catch (sendEx: IntentSender.SendIntentException) {
                    // Open setting page to turn on location
                    platformActivity.startActivityForResult(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS),
                        REQUEST_LOCATION_ACTIVITY)
                }
            }
        }
    }

    private fun isLocationServiceEnabled(): Boolean {
        var gpsEnabled = false
        var networkEnabled = false

        try {
            gpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        } catch (ex: Exception) {
            Log.e(LOG_TAG, "GPS provider is not enabled.")
        }

        try {
            networkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        } catch (ex: Exception) {
            Log.e(LOG_TAG, "Network provider is not enabled.")
        }

        Log.d(LOG_TAG, "GPS Enabled: $gpsEnabled, Network Enabled: $networkEnabled")

        return gpsEnabled || networkEnabled
    }

    private fun hasLocationPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(applicationContext,Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestLocationPermission() {
        ActivityCompat.requestPermissions(platformActivity, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), REQUEST_FINE_LOCATION_PERMISSION)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        when(requestCode) {
            REQUEST_FINE_LOCATION_PERMISSION -> {
                // If request is cancelled, the result arrays are empty.
                val result = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                resultCallback?.success(result)
                resultCallback = null

                return result
            }
        }

        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        init(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.let { tearDown(it) }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        init(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.let { tearDown(it) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when(requestCode) {
            REQUEST_LOCATION_ACTIVITY -> {
                var isLocationServiceEnabled = resultCode == RESULT_OK
                if(resultCode == RESULT_CANCELED) {
                    isLocationServiceEnabled = isLocationServiceEnabled()
                }
                resultCallback?.success(isLocationServiceEnabled)
                resultCallback = null

                return isLocationServiceEnabled
            }
        }
        return false
    }

    private fun init(binding: ActivityPluginBinding){
        activityBinding = binding
        platformActivity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    private fun tearDown(binding: ActivityPluginBinding) {
        binding.removeActivityResultListener(this)
        binding.removeRequestPermissionsResultListener(this)
        activityBinding = null;
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}