import Flutter
import UIKit
import ESPProvision

private protocol EspService {
    func searchBleDevices(completion: @escaping ([[String:Any]]?,FlutterError?) -> Void) -> Void
    func connectBleDevice(serviceUuid: String,completion: @escaping (Bool?,FlutterError?) -> Void) -> Void
    func getConnectedBleDevice(completion: @escaping ([String:Any]?) -> Void) -> Void
    func scanWifiNetworks(completion: @escaping ([[String:Any]]?,FlutterError?) -> Void) -> Void
    func provision(ssid: String, passphrase: String,completion: @escaping (Bool?,FlutterError?) -> Void) -> Void
    func disconnectBleDevice(completion: @escaping (Bool?,FlutterError?) -> Void) -> Void
}

private class EspManager: EspService {
    private var blutoothManager: BluetoothManager!
    private let proofOfPossession: String = "abcd1234"
    private var connectedDevice: ESPDevice?

    init(){
        blutoothManager = BluetoothManager()
    }

    func searchBleDevices(completion: @escaping ([[String:Any]]?,FlutterError?) -> Void) {
        hasPermission { error in
            if error != nil {
                completion(nil,error)
                return
            }
        }

        ESPProvisionManager.shared.searchESPDevices(devicePrefix: "", transport:.ble, security:.secure) { deviceList, error in
            if(error != nil) {
                if error!.code == 27 {
                    completion([],nil)
                    return
                }

                completion(nil,ESPErrorHandler.toFlutterError(error: error!))
                return
            }

            let payload = (deviceList ?? []).map({ (device: ESPDevice) -> [String:Any] in
                let device = [
                    "name":device.name,
                    "service_uuid": device.name
                ]

                return device
            })

            completion(payload,nil)
        }
    }

    func connectBleDevice(serviceUuid: String,completion: @escaping (Bool?,FlutterError?) -> Void) {
        hasPermission { error in
            if error != nil {
                completion(nil,error)
                return
            }
        }

        ESPProvisionManager.shared.createESPDevice(deviceName: serviceUuid, transport: .ble, security: .secure, proofOfPossession: proofOfPossession) { espDevice, error in

            if(error != nil) {
                completion(nil,ESPErrorHandler.toFlutterError(error: error!))
                return
            }

            espDevice?.connect { status in
                switch status {
                case .connected:
                    self.connectedDevice = espDevice
                    completion(true,nil)
                case let .failedToConnect(error):
                    self.connectedDevice = nil
                    completion(nil,FlutterError(code:"CONNECTION_ERROR",message:error.description,details:nil))
                default:
                    self.connectedDevice = nil
                    completion(nil,FlutterError(code: "CONNECTION_ERROR", message: "Device disconnected.", details: nil))
                }
            }
        }
    }

    func getConnectedBleDevice(completion: @escaping ([String:Any]?) -> Void){
        if(self.connectedDevice == nil){
            completion(nil)
            return
        }

        let connectedDevicePayload = [
            "name":self.connectedDevice!.name,
            "service_uuid": self.connectedDevice!.name
        ]

        completion(connectedDevicePayload)
    }

    func scanWifiNetworks(completion: @escaping ([[String:Any]]?,FlutterError?)->Void) {
        if(self.connectedDevice==nil){
            completion(nil,FlutterError(code:"CONNECTION_ERROR",message: "Device is not connected.",details: nil))
            return
        }

        self.connectedDevice!.scanWifiList { wifiList, error in
            if(error != nil) {
                completion(nil,ESPErrorHandler.toFlutterError(error: error!))
                return
            }

            let payload = (wifiList ?? []).map({(network: ESPWifiNetwork) -> [String:Any] in
                let device = [
                    "name": network.ssid,
                    "rssi": network.rssi,
                    "security": network.auth.rawValue
                ]

                return device
            })

            completion(payload,nil)
        }
    }

    func provision(ssid: String, passphrase: String,completion: @escaping (Bool?,FlutterError?) -> Void) {
        if(self.connectedDevice==nil){
            completion(nil,FlutterError(code:"CONNECTION_ERROR",message: "Device is not connected.",details: nil))
            return
        }

        self.connectedDevice!.provision(ssid: ssid, passPhrase: passphrase) { status in
            switch status {
            case .success:
                completion(true,nil)
            case .configApplied:
                NSLog("Wifi config applied device.")
            case .failure:
                completion(nil,FlutterError(code: "WIFI_CONNECTION_ERROR", message: "Failed to provision device.", details: nil))
            }
        }
    }

    func disconnectBleDevice(completion: @escaping (Bool?,FlutterError?) -> Void) {
        if(self.connectedDevice == nil){
            completion(nil,FlutterError(code:"DISCONNECT_ERROR",message:"No device connected.",details:nil))
            return
        }

        self.connectedDevice!.disconnect()
        self.connectedDevice = nil

        completion(true,nil)
    }

    private func hasPermission(completion: @escaping (FlutterError?) -> Void) {
        blutoothManager.hasBluetoothPermission { hasPermission in
            if(!hasPermission){
                completion(FlutterError(code:"BLUETOOTH_ERROR",message: "Not able to start scan as Bluetooth permission is not granted.",details:nil))
                return
            }
        }

        completion(nil)
    }
}

fileprivate class ESPErrorHandler {
    static func toFlutterError(error: ESPError) -> FlutterError {
        return FlutterError(code: String(error.code), message: error.description, details: nil)
    }
}


public class SwiftEspPlugin: NSObject, FlutterPlugin {
    fileprivate let espManager = EspManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "esp_wifi_provisioning/esp", binaryMessenger: registrar.messenger())
        let instance = SwiftEspPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]

        if(call.method == "searchBleEspDevices") {
            espManager.searchBleDevices { deviceList, error in
                if(error != nil){
                    result(error)
                    return
                }

                result(deviceList)
            }
        }else if(call.method == "connectBLEDevice"){
            guard let serviceUuid = arguments?["service_uuid"] as? String else {
                result(FlutterError(code:"CONNECTION_ERROR",message: "Device ID is required.",details: nil))
                return
            }

            espManager.connectBleDevice(serviceUuid: serviceUuid, completion: { isConnected, error in
                if (error != nil) {
                    result(error)
                    return
                }

                result(isConnected)
            })
        }else if (call.method == "getConnectedBLEDevice"){
            espManager.getConnectedBleDevice(completion: { connectedDevice in
                result(connectedDevice)
            })
        } else if(call.method == "scanWifiNetworks") {
            espManager.scanWifiNetworks { wifiNetworks, error in
                if(error != nil){
                    result(error)
                    return
                }

                result(wifiNetworks)
            }
        } else if (call.method == "provisionWifiNetwork") {
            guard let ssid = arguments?["ssid"] as? String else {
                result(FlutterError(code: "WIFI_CONNECTION_ERROR", message: "Network ssid is required.", details: nil))
                return
            }
            let password = arguments?["password"] as? String ?? ""

            espManager.provision(
                ssid: ssid,
                passphrase: password,
                completion: { isProvisioned ,error in
                    if(error != nil){
                        result(error)
                        return
                    }

                    result(isProvisioned)
                }
            )
        }else if (call.method == "disconnectBLEDevice"){
            espManager.disconnectBleDevice(completion: { isDisconnected,error in
                if(error != nil){
                    result(error)
                    return
                }

                result(isDisconnected)
            })
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}