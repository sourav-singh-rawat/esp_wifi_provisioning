import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'esp_method_channel.dart';
import 'utils/model/bluetooth_device.dart';
import 'utils/model/wifi_network.dart';

abstract class EspPlatform extends PlatformInterface {
  EspPlatform() : super(token: _token);
  static final Object _token = Object();

  static EspPlatform _instance = MethodChannelEsp();

  /// The default instance of [EspPlatform] to use.
  ///
  /// Defaults to [MethodChannelEsp].
  static EspPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EspPlatform] when
  /// they register themselves.
  static set instance(EspPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<EspBluetoothDevice>> scanBluetoothDevices();

  Future<bool> connectBluetoothDevice({
    required EspBluetoothDevice device,
  });

  Future<EspBluetoothDevice?> getConnectedBluetoothDevice();

  Future<List<EspWifiNetwork>> scanWifiNetworks({required String provisionProof});

  Future<bool> provisionWifiNetwork({
    required EspWifiNetwork network,
    String? password,
  });

  Future<bool> disconnectBluetoothDevice();
}
