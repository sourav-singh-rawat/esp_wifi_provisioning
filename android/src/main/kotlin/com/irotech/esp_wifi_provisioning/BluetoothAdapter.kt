package com.irotech.esp_wifi_provisioning

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

private const val CHANNEL = "esp_wifi_provisioning/bluetooth_adapter";

class BluetoothAdapter: FlutterPlugin, MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener,
    ActivityAware, PluginRegistry.ActivityResultListener {
    private val LOG_TAG = "@[${CHANNEL}]@"

    private val REQUEST_ENABLE_BT_ACTIVITY = 1407199903

    private val REQUEST_BLUETOOTH_PERMISSION = 1407199904

    private lateinit var applicationContext: Context

    private lateinit var platformActivity: Activity

    private var activityBinding: ActivityPluginBinding? = null

    private lateinit var channel: MethodChannel

    private lateinit var bleManager: BluetoothManager

    private lateinit var bleAdapter: BluetoothAdapter

    private fun setupCallbackChannels(binaryMessenger: BinaryMessenger) {
        Log.d(LOG_TAG,"Method and events callbacks setup")

        channel = MethodChannel(binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        setupCallbackChannels(binding.binaryMessenger)

        bleManager = applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bleAdapter = bleManager.adapter
    }

    private var resultCallback: MethodChannel.Result? = null
    private var resultCallbackOptionalError: String = ""
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if(resultCallback!=null){
            resultCallback?.error("",resultCallbackOptionalError,null)
            resultCallback = null
        }

        when (call.method) {
            "isBluetoothServiceEnabled" -> {
                result.success(isBluetoothServiceEnabled())
                return
            }
            "requestEnableBluetoothService" -> {
                requestEnableBluetoothService()
                resultCallback = result
                resultCallbackOptionalError = "Waiting for Bluetooth service response."
                return
            }
            "hasBluetoothPermissions" -> {
                val hasBluetoothPermissions = hasBluetoothPermissions()
                result.success(hasBluetoothPermissions)
                return
            }
            "requestBluetoothPermission" -> {
                val hasBluetoothPermissions = hasBluetoothPermissions()
                if(hasBluetoothPermissions){
                    result.success(true)
                    return
                }
                requestBluetoothPermission()
                resultCallback = result
                resultCallbackOptionalError = "Waiting for Bluetooth service response."
            }
            else -> result.notImplemented()
        }
    }

    private fun isBluetoothServiceEnabled():Boolean {
        return bleAdapter.isEnabled;
    }

    private fun requestEnableBluetoothService(){
        val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ActivityCompat.checkSelfPermission(applicationContext, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
                platformActivity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT_ACTIVITY)
            }else{
                resultCallback?.error("","Enable Bluetooth permission to allow Bluetooth service.",null)
                resultCallback = null
            }
        } else {
            platformActivity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT_ACTIVITY)
        }
    }

    private fun hasBluetoothPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (ActivityCompat.checkSelfPermission(applicationContext, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED) && (ActivityCompat.checkSelfPermission(applicationContext,Manifest.permission.BLUETOOTH_CONNECT) ==PackageManager.PERMISSION_GRANTED)
        } else {
            ActivityCompat.checkSelfPermission(applicationContext,Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestBluetoothPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(platformActivity, arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT), REQUEST_BLUETOOTH_PERMISSION)
        }else{
            ActivityCompat.requestPermissions(platformActivity, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), REQUEST_BLUETOOTH_PERMISSION)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        when(requestCode) {
            REQUEST_BLUETOOTH_PERMISSION -> {
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
            REQUEST_ENABLE_BT_ACTIVITY -> {
                val isBluetoothServiceEnabled = isBluetoothServiceEnabled()
                resultCallback?.success(isBluetoothServiceEnabled)
                resultCallback = null

                return isBluetoothServiceEnabled
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