import 'package:flutter/cupertino.dart';

import 'bluetooth_adapter/bluetooth_adapter.dart';
import 'esp/esp.dart';
import 'esp/utils/model/bluetooth_device.dart';
import 'esp/utils/model/wifi_network.dart';
import 'location_adapter/location_adapter.dart';

class EspWifiProvisioning {
  static BluetoothAdapter bluetoothAdapter = BluetoothAdapter();
  static LocationAdapter locationAdapter = LocationAdapter();
  static Esp esp = Esp();

  Future<List<EspBluetoothDevice>> quickScanBluetoothDevices() async {
    try {
      bool isRequiredServicesEnabled = await _isRequiredServiceEnabled();

      if (isRequiredServicesEnabled) {
        final List<EspBluetoothDevice> devices = await esp.scanBluetoothDevices();

        return devices;
      } else {
        throw ErrorDescription('Required services are not enabled.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> connectBluetoothDevice({
    required EspBluetoothDevice device,
  }) {
    return esp.connectBluetoothDevice(device: device);
  }

  Future<EspBluetoothDevice?> getConnectedBluetoothDevice() {
    return esp.getConnectedBluetoothDevice();
  }

  Future<List<EspWifiNetwork>> scanWifiNetworks({required String provisionProof}) {
    return esp.scanWifiNetworks(provisionProof: provisionProof);
  }

  Future<bool> provisionWifiNetwork({
    required EspWifiNetwork network,
    String? password,
  }) {
    return esp.provisionWifiNetwork(network: network, password: password);
  }

  Future<bool> disconnectBluetoothDevice() {
    return esp.disconnectBluetoothDevice();
  }

  Future<bool> _isRequiredServiceEnabled() async {
    try {
      bool hasLocationPermissions = await locationAdapter.hasLocationPermissions();
      if (!hasLocationPermissions) {
        hasLocationPermissions = await locationAdapter.requestLocationPermission();
      }

      bool isLocationServiceEnabled = await locationAdapter.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        isLocationServiceEnabled = await locationAdapter.requestEnableLocationService();
      }

      isLocationServiceEnabled = hasLocationPermissions && isLocationServiceEnabled;

      bool hasBluetoothPermissions = await bluetoothAdapter.hasBluetoothPermissions();
      if (!hasBluetoothPermissions) {
        hasBluetoothPermissions = await bluetoothAdapter.requestBluetoothPermission();
      }

      bool isBluetoothServiceEnabled = await bluetoothAdapter.isBluetoothServiceEnabled();
      if (!isBluetoothServiceEnabled) {
        isBluetoothServiceEnabled = await bluetoothAdapter.requestEnableBluetoothService();
      }

      isBluetoothServiceEnabled = hasBluetoothPermissions && isBluetoothServiceEnabled;

      return isLocationServiceEnabled && isBluetoothServiceEnabled;
    } catch (e) {
      rethrow;
    }
  }
}
