import 'package:esp_wifi_provisioning/bluetooth_adapter/bluetooth_adapter_platform_interface.dart';

class BluetoothAdapter {
  Future<bool> hasBluetoothPermissions() {
    return BluetoothAdapterPlatform.instance.hasBluetoothPermissions();
  }

  Future<bool> requestBluetoothPermission() {
    return BluetoothAdapterPlatform.instance.requestBluetoothPermission();
  }

  Future<bool> isBluetoothServiceEnabled() {
    return BluetoothAdapterPlatform.instance.isBluetoothServiceEnabled();
  }

  Future<bool> requestEnableBluetoothService() {
    return BluetoothAdapterPlatform.instance.requestEnableBluetoothService();
  }
}
