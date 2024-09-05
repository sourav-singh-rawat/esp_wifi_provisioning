package com.irotech.esp_wifi_provisioning

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import com.espressif.provisioning.DeviceConnectionEvent
import com.espressif.provisioning.ESPConstants
import com.espressif.provisioning.ESPDevice
import com.espressif.provisioning.ESPProvisionManager
import com.espressif.provisioning.WiFiAccessPoint
import com.espressif.provisioning.listeners.BleScanListener
import com.espressif.provisioning.listeners.ProvisionListener
import com.espressif.provisioning.listeners.WiFiScanListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode


private const val CHANNEL = "esp_wifi_provisioning/esp";

class Esp: FlutterPlugin, MethodChannel.MethodCallHandler {
    private val LOG_TAG = "@$CHANNEL@"

    private lateinit var applicationContext: Context

    private lateinit var mChannel: MethodChannel

    private lateinit var provisionManager: ESPProvisionManager

    private var _bleDevices: HashMap<String, BluetoothDevice> = HashMap()

    private var bleDeviceList: ArrayList<HashMap<String,Any>> = ArrayList()

    private var wifiNetworkList: ArrayList<HashMap<String,Any>> = ArrayList()

    private var connectedDevice: ESPDevice? = null

    private fun setupCallbackChannels(binaryMessenger: BinaryMessenger) {
        Log.d(CHANNEL,"Method and events callbacks setup")

        mChannel = MethodChannel(binaryMessenger, CHANNEL)
        mChannel.setMethodCallHandler(this)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        setupCallbackChannels(binding.binaryMessenger)

        provisionManager = ESPProvisionManager.getInstance(applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "searchBleEspDevices" -> searchBleEspDevices(result)
            "connectBLEDevice" -> {
                val serviceUuid = call.argument<String>("service_uuid")
                if(serviceUuid==null){
                    result.error("CONNECTION_ERROR","Device ID is required.",null)
                    return
                }

                connectBLEDevice(serviceUuid,result)
            }
            "getConnectedBLEDevice" ->{
                if(connectedDevice == null){
                    result.success(null)
                    return
                }

                val payload: HashMap<String,Any> = HashMap()
                payload["name"]= connectedDevice!!.deviceName
                payload["service_uuid"] = connectedDevice!!.primaryServiceUuid

                result.success(payload)
            }
            "scanWifiNetworks" ->{
                val provisionProof = call.argument<String>("provision_proof")
                if(provisionProof==null){
                    result.error("CONNECTION_ERROR","Proof of provision is required.",null)
                    return
                }

                scanWifiNetworks(provisionProof,result)
            }
            "provisionWifiNetwork" -> {
                val ssid = call.argument<String>("ssid");
                val password = call.argument<String>("password")

                if(ssid==null){
                    result.error("WIFI_CONNECTION_ERROR","Network SSID is required.",null)
                    return
                }
                if(password==null){
                    result.error("WIFI_CONNECTION_ERROR","Network SSID is required.",null)
                    return
                }

                provision(ssid,password,result)
            }
            "disconnectBLEDevice" -> {
                if(connectedDevice == null){
                    result.error("DISCONNECT_ERROR","No device connected.",null)
                    return
                }

                connectedDevice?.disconnectDevice()
                connectedDevice = null

                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun searchBleEspDevices(result: MethodChannel.Result){
        if (!hasPermissions(result)) {
            return
        }

        var isScanCompleted = false
        _bleDevices = HashMap()
        bleDeviceList = ArrayList()

        if (ActivityCompat.checkSelfPermission(applicationContext, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.searchBleEspDevices("", object : BleScanListener {
                override fun scanStartFailed() {
                    if(isScanCompleted) return

                    result.error("BLUETOOTH_ERROR", "Enable Bluetooth to scan.", null)
                    isScanCompleted = true
                }

                override fun onPeripheralFound(device: BluetoothDevice?, scanResult: ScanResult?) {
                    device ?: return
                    scanResult ?: return

                    if(isScanCompleted) return

                    if (ActivityCompat.checkSelfPermission(applicationContext, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                        result.error("BLUETOOTH_ERROR","Enable Bluetooth permission.",null)
                        isScanCompleted = true
                        return
                    }

                    var deviceExists = false
                    var serviceUuid = ""

                    if (scanResult.scanRecord?.serviceUuids != null && scanResult.scanRecord?.serviceUuids!!.size > 0) {
                        serviceUuid = scanResult.scanRecord?.serviceUuids!![0].toString()
                    }

                    if (_bleDevices.containsKey(serviceUuid)) {
                        deviceExists = true
                    }

                    if (!deviceExists) {
                        val payload: HashMap<String,Any> = HashMap()
                        payload["name"]=device.name
                        payload["service_uuid"] = serviceUuid

                        bleDeviceList.add(payload)

                        _bleDevices[serviceUuid] = device
                    }
                }

                override fun scanCompleted() {
                    if(isScanCompleted) return

                    result.success(bleDeviceList)

                    isScanCompleted = true
                }

                override fun onFailure(e: java.lang.Exception?) {
                    if(isScanCompleted) return

                    result.error("SCAN_ERROR", e?.message, e)

                    isScanCompleted = true
                }
            })
        } else {
            result.error("LOCATION_ERROR","Enable location permission.",null)
            isScanCompleted = true
        }
    }

    private fun connectBLEDevice(serviceUuid:String,result: MethodChannel.Result){
        if (!hasPermissions(result)) {
            connectedDevice = null
            return
        }

        val isCompleted = false

        val esp = provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_1)

        EventBus.getDefault().register(object {
            @Subscribe(threadMode = ThreadMode.MAIN)
            fun onEvent(event: DeviceConnectionEvent) {
                if(isCompleted) return

                Log.d(LOG_TAG,"event_type:${event.eventType} $event")

                when (event.eventType) {
                    ESPConstants.EVENT_DEVICE_CONNECTION_FAILED -> {
                        result.error("CONNECTION_ERROR","Failed to connect to device.",null)
                    }
                    ESPConstants.EVENT_DEVICE_CONNECTED -> {
                        EventBus.getDefault().unregister(this)
                        connectedDevice = esp
                        result.success(true)
                    }
                    ESPConstants.EVENT_DEVICE_DISCONNECTED -> {
                        result.error("CONNECTION_ERROR","Device disconnected.",null)
                    }
                }
            }
        })

        esp.connectBLEDevice(_bleDevices[serviceUuid],serviceUuid)
    }

    private fun scanWifiNetworks(provisionProof:String,result: MethodChannel.Result){
        if(connectedDevice==null){
            result.error("CONNECTION_ERROR","No device connected.",null)
            return
        }

        var isScanComplete = false
        wifiNetworkList = ArrayList()

        connectedDevice?.proofOfPossession = provisionProof

        connectedDevice?.scanNetworks(object : WiFiScanListener {
            override fun onWifiListReceived(wifiList: ArrayList<WiFiAccessPoint>?) {
                wifiList ?: return
                if(isScanComplete) return

                wifiList.forEach {
                    val payload:HashMap<String,Any> = HashMap()

                    payload["name"] = it.wifiName
                    payload["rssi"] = it.rssi
                    payload["security"] = it.security

                    wifiNetworkList.add(payload)
                }

                result.success(wifiNetworkList)

                isScanComplete =true
            }

            override fun onWiFiScanFailed(e: java.lang.Exception?) {
                if(isScanComplete) return

                result.error("WIFI_SCAN_ERROR", e?.message, e)
                isScanComplete =true
            }
        })
    }

    private fun provision(ssid:String,passphrase:String,result: MethodChannel.Result){
        if(connectedDevice==null){
            result.error("CONNECTION_ERROR","No device connected.",null)
            return
        }

        var isProvisionCompleted = false;

        connectedDevice!!.provision(ssid, passphrase, object : ProvisionListener {
            override fun createSessionFailed(e: java.lang.Exception?) {
                if(isProvisionCompleted) return

                result.error("WIFI_CONNECTION_ERROR",e?.message,e)

                isProvisionCompleted = true
            }

            override fun wifiConfigSent() {
                Log.d(LOG_TAG,"wifi config sent")
            }

            override fun wifiConfigFailed(e: java.lang.Exception?) {
                if(isProvisionCompleted) return

                result.error("WIFI_CONNECTION_ERROR",e?.message,e)

                isProvisionCompleted = true
            }

            override fun wifiConfigApplied() {
                Log.d(LOG_TAG,"wifi config applied")
            }

            override fun wifiConfigApplyFailed(e: java.lang.Exception?) {
                if(isProvisionCompleted) return

                result.error("CONNECTION_ERROR",e?.message,e)

                isProvisionCompleted = true
            }

            override fun provisioningFailedFromDevice(failureReason: ESPConstants.ProvisionFailureReason?) {
                if(isProvisionCompleted) return

                result.error("WIFI_CONNECTION_ERROR",failureReason?.name,null)

                connectedDevice?.disconnectDevice()
                connectedDevice = null

                isProvisionCompleted = true
            }

            override fun deviceProvisioningSuccess() {
                if(isProvisionCompleted) return

                result.success(true)

                isProvisionCompleted = true
            }

            override fun onProvisioningFailed(e: java.lang.Exception?) {
                if(isProvisionCompleted) return

                result.error("WIFI_CONNECTION_ERROR",e?.message,e)

                isProvisionCompleted = true
            }
        })
    }

    private fun hasPermissions(result: MethodChannel.Result): Boolean {
        if(!hasLocationPermission()){
            result.error("LOCATION_ERROR","Enable location permission.",
                null)
            return false
        }
        if(!hasBluetoothPermissions()){
            result.error("BLUETOOTH_ERROR","Enable Bluetooth permission.",null)
            return false
        }
        if(!isLocationServiceEnabled()){
            result.error("LOCATION_ERROR","Enable location service.",null)
            return false
        }
        if(!isBluetoothEnable()){
            result.error("BLUETOOTH_ERROR","Enable Bluetooth service.",null)
        }

        return true
    }

    private fun hasLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(applicationContext,Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
    }

    private fun hasBluetoothPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.checkSelfPermission(applicationContext,
                Manifest.permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(applicationContext,Manifest
                .permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            ActivityCompat.checkSelfPermission(applicationContext,Manifest.permission.ACCESS_FINE_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED
        }
    }

    private fun isLocationServiceEnabled(): Boolean {
        val locationManager = applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
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

    private fun isBluetoothEnable(): Boolean {
        val bluetoothManager = applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bleAdapter = bluetoothManager.adapter

        return bleAdapter.isEnabled;
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        mChannel.setMethodCallHandler(null)
    }
}