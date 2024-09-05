import 'dart:io';

import 'location_adapter_platform_interface.dart';

class LocationAdapter {
  Future<bool> hasLocationPermissions() {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    return LocationAdapterPlatform.instance.hasLocationPermissions();
  }

  Future<bool> requestLocationPermission() {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    return LocationAdapterPlatform.instance.requestLocationPermission();
  }

  Future<bool> isLocationServiceEnabled() {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    return LocationAdapterPlatform.instance.isLocationServiceEnabled();
  }

  Future<bool> requestEnableLocationService() {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    return LocationAdapterPlatform.instance.requestEnableLocationService();
  }
}
