import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'location_adapter_method_channel.dart';

abstract class LocationAdapterPlatform extends PlatformInterface {
  LocationAdapterPlatform() : super(token: _token);
  static final Object _token = Object();

  static LocationAdapterPlatform _instance = MethodChannelLocationAdapter();

  /// The default instance of [LocationAdapterPlatform] to use.
  ///
  /// Defaults to [MethodChannelLocationAdapter].
  static LocationAdapterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LocationAdapterPlatform] when
  /// they register themselves.
  static set instance(LocationAdapterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> hasLocationPermissions();

  Future<bool> requestLocationPermission();

  Future<bool> isLocationServiceEnabled();

  Future<bool> requestEnableLocationService();
}
