import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bluetooth_adapter_platform_interface.dart';

class MethodChannelBluetoothAdapter extends BluetoothAdapterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('esp_wifi_provisioning/bluetooth_adapter');

  @override
  Future<bool> hasBluetoothPermissions() async {
    try {
      final hasBluetoothPermissions = await methodChannel.invokeMethod<bool>('hasBluetoothPermissions') ?? false;

      return hasBluetoothPermissions;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> requestBluetoothPermission() async {
    try {
      final isAllowed = await methodChannel.invokeMethod<bool>('requestBluetoothPermission') ?? false;

      return isAllowed;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isBluetoothServiceEnabled() async {
    try {
      final isBluetoothServiceEnabled = await methodChannel.invokeMethod<bool>('isBluetoothServiceEnabled') ?? false;

      return isBluetoothServiceEnabled;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> requestEnableBluetoothService() async {
    try {
      final hasBluetoothPermissions = await this.hasBluetoothPermissions();
      if (!hasBluetoothPermissions) {
        final isAllowed = await requestBluetoothPermission();
        if (isAllowed) {
          return await requestEnableBluetoothService();
        }

        throw ErrorDescription('Enable bluetooth permission to turn on service.');
      }
      final enabled = await methodChannel.invokeMethod<bool>('requestEnableBluetoothService') ?? false;
      return enabled;
    } catch (e) {
      rethrow;
    }
  }
}
