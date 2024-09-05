import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'esp_platform_interface.dart';
import 'utils/exceptions.dart';
import 'utils/model/bluetooth_device.dart';
import 'utils/model/wifi_network.dart';

class MethodChannelEsp extends EspPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('esp_wifi_provisioning/esp');

  @override
  Future<List<EspBluetoothDevice>> scanBluetoothDevices() async {
    try {
      final result = await methodChannel.invokeMethod<List>('searchBleEspDevices');
      if (result != null) {
        if (result.isEmpty) {
          throw PlatformException(code: 'NO_DATA', message: 'No available device.');
        }

        final devices = result.map<EspBluetoothDevice>((e) {
          final data = Map<String, dynamic>.from(e);
          return EspBluetoothDevice.fromJson(data);
        }).toList();

        return devices;
      } else {
        throw PlatformException(code: 'NO_DATA', message: 'Opps, Something went wrong.');
      }
    } on PlatformException catch (e) {
      throw _onPlatformException(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> connectBluetoothDevice({
    required EspBluetoothDevice device,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('connectBLEDevice', {
            'service_uuid': device.serviceUuid,
          }) ??
          false;

      return result;
    } on PlatformException catch (e) {
      throw _onPlatformException(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<EspWifiNetwork>> scanWifiNetworks({required String provisionProof}) async {
    try {
      final result = await methodChannel.invokeMethod<List>('scanWifiNetworks', {
        'provision_proof': provisionProof,
      });

      if (result != null) {
        if (result.isEmpty) {
          throw PlatformException(code: 'NO_DATA', message: 'No available network');
        }

        return result.map<EspWifiNetwork>((e) {
          final data = Map<String, dynamic>.from(e);

          return EspWifiNetwork.fromJson(data);
        }).toList();
      } else {
        throw PlatformException(code: 'NO_DATA', message: 'Opps, Something went wrong.');
      }
    } on PlatformException catch (e) {
      throw _onPlatformException(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> provisionWifiNetwork({
    required EspWifiNetwork network,
    String? password,
  }) async {
    try {
      final wifiPassword = password ?? '';

      if (network.security != EspWifiSecurity.WIFI_OPEN && wifiPassword.isEmpty) {
        throw ErrorDescription('Password is required to connect wifi network.');
      }

      final result = await methodChannel.invokeMethod<bool>('provisionWifiNetwork', {
            'ssid': network.ssid,
            'password': wifiPassword,
          }) ??
          false;

      return result;
    } on PlatformException catch (e) {
      throw _onPlatformException(e);
    } catch (e) {
      rethrow;
    }
  }

  Exception _onPlatformException(PlatformException e) {
    switch (e.code) {
      case 'BLUETOOTH_ERROR':
        return EspBluetoothException(e.message!);
      case 'LOCATION_ERROR':
        return EspLocationException(e.message!);
      case 'SCAN_ERROR':
        return EspBluetoothException(e.message!);
      case 'CONNECTION_ERROR':
        return EspBluetoothConnectionException(e.message!);
      case 'WIFI_SCAN_ERROR':
        return EspWifiScanException(e.message!);
      case 'WIFI_CONNECTION_ERROR':
        return EspWifiConnectionException(e.message!);
      case 'NO_DATA':
        return EspNoDataException(e.message!);
      default:
        return e;
    }
  }

  @override
  Future<bool> disconnectBluetoothDevice() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('disconnectBLEDevice') ?? false;
      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EspBluetoothDevice?> getConnectedBluetoothDevice() async {
    try {
      final result = await methodChannel.invokeMethod<Map?>('getConnectedBLEDevice');
      if (result != null) {
        final data = Map<String, dynamic>.from(result);

        return EspBluetoothDevice.fromJson(data);
      }
    } catch (e) {
      rethrow;
    }

    return null;
  }
}
