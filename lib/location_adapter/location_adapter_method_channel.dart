import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'location_adapter_platform_interface.dart';

class MethodChannelLocationAdapter extends LocationAdapterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('esp_wifi_provisioning/location_adapter');

  @override
  Future<bool> hasLocationPermissions() async {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    try {
      final hasLocationPermissions = await methodChannel.invokeMethod<bool>('hasLocationPermissions') ?? false;

      return hasLocationPermissions;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    try {
      final isAllowed = await methodChannel.invokeMethod<bool>('requestLocationPermission') ?? false;

      return isAllowed;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    try {
      final isLocationServiceEnabled = await methodChannel.invokeMethod<bool>('isLocationServiceEnabled') ?? false;

      return isLocationServiceEnabled;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> requestEnableLocationService() async {
    if (Platform.isIOS) {
      return Future.value(true);
    }

    try {
      final hasLocationPermissions = await this.hasLocationPermissions();
      if (!hasLocationPermissions) {
        final isAllowed = await requestLocationPermission();
        if (isAllowed) {
          return await requestEnableLocationService();
        }

        throw ErrorDescription('Enable location permission to turn on service.');
      }

      final enabled = await methodChannel.invokeMethod<bool>('requestEnableLocationService') ?? false;
      return enabled;
    } catch (e) {
      rethrow;
    }
  }
}
