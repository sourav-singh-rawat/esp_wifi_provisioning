import Flutter
import CoreBluetooth

fileprivate enum BluetoothError: Error {
    case unsupported
    case unauthorized
    case unknown

    var description: String {
        switch self {
        case .unsupported:
            return "Bluetooth is not supported on this device"
        case .unauthorized:
            return "Bluetooth permission is not granted"
        case .unknown:
            return "Bluetooth state is unknown"
        }
    }
}

private protocol BlutoothService {
    var centralManager: CBCentralManager? { get }
    func hasBluetoothPermission(canShowInteractionAlert:Bool,completion: @escaping (Bool) -> Void) -> Void
    //TODO: Define more
}

class BluetoothManager: NSObject, BlutoothService {
    var centralManager: CBCentralManager?
    private var bundleDisplayName:String = ""
    private var rootViewController:UIViewController!

    override init() {
        super.init()

        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            self.bundleDisplayName = bundleName
        }

        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                self.rootViewController = rootViewController
            }
        } else {
            // Fallback for iOS 12 and earlier
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                self.rootViewController = rootViewController
            }
        }
    }

    func initializeCBCentralManager() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func hasBluetoothPermission(canShowInteractionAlert:Bool = true,completion: @escaping (Bool) -> Void) {
        if #available(iOS 13.0, *) {
            let status: CBManagerAuthorization

            if #available(iOS 13.1, *) {
                status = CBManager.authorization
            } else {
                status = CBCentralManager().authorization
            }

            NSLog("[hasBluetoothPermission]: Status \(status)")
            switch status {
            case .allowedAlways:
//                if centralManager == nil {
//                    self.initializeCBCentralManager()
//                }
                completion(true)
            case .restricted, .denied:
                if canShowInteractionAlert {
                    self.promptToTurnOnBluetoothPermission(completion: completion)
                }else {
                    completion(false)
                }
            case .notDetermined:
                completion(false)
            @unknown default:
                completion(false)
            }
        } else {
            // Before iOS 13, Bluetooth permissions are not required
            completion(true)
        }
    }

    func requestBluetoothPermission() {
        self.initializeCBCentralManager()
    }

    func requestEnableBluetoothService() {
        self.initializeCBCentralManager()
    }

    func isBluetoothServiceEnabled(canShowInteractionAlert:Bool = true,completion: @escaping (Result<Bool, Error>) -> Void) {
        if(centralManager == nil){
            completion(.success(false))
            return
        }

        NSLog("[isBluetoothServiceEnabled]: Status \(String(describing: centralManager!.state.rawValue))")

        switch centralManager!.state {
        case .poweredOn:
            completion(.success(true))
        case .poweredOff:
            if canShowInteractionAlert {
                self.promptToTurnOnBluetooth(completion: completion)
            } else {
                completion(.success(false))
            }
        case .unsupported:
            completion(.failure(BluetoothError.unsupported))
        case .unauthorized:
            completion(.failure(BluetoothError.unauthorized))
        case .resetting:
            completion(.success(false))
        case .unknown:
            completion(.success(false))
        @unknown default:
            completion(.success(false))
        }
    }

    func promptToTurnOnBluetooth(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.promptAlertDiloagBox(
            title: "\(self.bundleDisplayName) Requires Bluetooth Access",
            message: "Please Turn On Bluetooth in the app settings to connect with nearby Pie.",
            action: UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:]) { _ in
                        self.isBluetoothServiceEnabled(canShowInteractionAlert: false, completion: { result in
                            completion(result)
                        })
                    }
                } else {
                    completion(.success(false))
                }
            }, onCancle: {
                completion(.success(false))
            })
    }


    func promptToTurnOnBluetoothPermission(completion: @escaping (Bool) -> Void) {
        self.promptAlertDiloagBox(
            title: "\"\(self.bundleDisplayName)\" Requires Bluetooth Permission",
            message: "This app needs Bluetooth permission to connect with nearby Pie.",
            action: UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:]) { _ in
                        self.hasBluetoothPermission(canShowInteractionAlert: false, completion: { hasPermission in
                            completion(hasPermission)
                        })
                    }
                } else {
                    completion(false)
                }
            }, onCancle: {
                completion(false)
            })
    }


    private func promptAlertDiloagBox(title:String,message:String,action:UIAlertAction,onCancle: @escaping () -> Void) {
        if (rootViewController.presentedViewController != nil){
            return
        }

        DispatchQueue.main.async {
            let alert = UIAlertController(
                title:title,
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(action)

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                onCancle()
            })

            self.rootViewController.present(alert, animated: true, completion: nil)
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        self.isBluetoothServiceEnabled(canShowInteractionAlert:false,completion: { _ in })
    }
}

public class SwiftBluetoothAdapterPlugin: NSObject, FlutterPlugin {
    private let bluetoothManager = BluetoothManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "esp_wifi_provisioning/bluetooth_adapter", binaryMessenger: registrar.messenger())
        let instance = SwiftBluetoothAdapterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "isBluetoothServiceEnabled" {
            self.bluetoothManager.isBluetoothServiceEnabled(canShowInteractionAlert:false,completion: { statusResult in
                switch statusResult {
                case .success(let isEnabled):
                    result(isEnabled)
                case .failure(let error):
                    NSLog("[isBluetoothServiceEnabled]: Error \(error)")
                    result(FlutterError(code: "",
                                        message: error.localizedDescription,
                                        details: nil))
                }
            })
        } else if call.method == "requestEnableBluetoothService" {
            self.bluetoothManager.requestEnableBluetoothService()

            self.bluetoothManager.isBluetoothServiceEnabled { statusResult in
                switch statusResult {
                case .success(let isEnabled):
                    result(isEnabled)
                case .failure(let error):
                    NSLog("[requestEnableBluetoothService]: Error \(error)")
                    result(FlutterError(code: "",
                                        message: error.localizedDescription,
                                        details: nil))
                }
            }
        }else if call.method == "hasBluetoothPermissions" {
            self.bluetoothManager.hasBluetoothPermission(canShowInteractionAlert:false,completion:{ isEnabled in
                result(isEnabled)
            })
        } else if call.method == "requestBluetoothPermission" {
            self.bluetoothManager.requestBluetoothPermission()

            self.bluetoothManager.hasBluetoothPermission { isEnabled in
                result(isEnabled)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}