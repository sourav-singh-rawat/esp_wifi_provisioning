import 'location_adapter_platform_interface.dart';

class LocationAdapter {
  Future<bool> hasLocationPermissions() {
    return LocationAdapterPlatform.instance.hasLocationPermissions();
  }

  Future<bool> requestLocationPermission() {
    return LocationAdapterPlatform.instance.requestLocationPermission();
  }

  Future<bool> isLocationServiceEnabled() {
    return LocationAdapterPlatform.instance.isLocationServiceEnabled();
  }

  Future<bool> requestEnableLocationService() {
    return LocationAdapterPlatform.instance.requestEnableLocationService();
  }
}
