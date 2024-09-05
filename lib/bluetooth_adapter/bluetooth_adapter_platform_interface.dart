import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_adapter_method_channel.dart';

abstract class BluetoothAdapterPlatform extends PlatformInterface {
  BluetoothAdapterPlatform() : super(token: _token);
  static final Object _token = Object();

  static BluetoothAdapterPlatform _instance = MethodChannelBluetoothAdapter();

  /// The default instance of [BluetoothAdapterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothAdapter].
  static BluetoothAdapterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothAdapterPlatform] when
  /// they register themselves.
  static set instance(BluetoothAdapterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> hasBluetoothPermissions();

  Future<bool> requestBluetoothPermission();

  Future<bool> isBluetoothServiceEnabled();

  Future<bool> requestEnableBluetoothService();
}
