import 'package:esp_wifi_provisioning/esp/esp_platform_interface.dart';
import 'package:esp_wifi_provisioning/esp/utils/model/bluetooth_device.dart';
import 'package:esp_wifi_provisioning/esp/utils/model/wifi_network.dart';

class Esp {
  Future<List<EspBluetoothDevice>> scanBluetoothDevices() {
    return EspPlatform.instance.scanBluetoothDevices();
  }

  Future<bool> connectBluetoothDevice({
    required EspBluetoothDevice device,
  }) {
    return EspPlatform.instance.connectBluetoothDevice(device: device);
  }

  Future<EspBluetoothDevice?> getConnectedBluetoothDevice() {
    return EspPlatform.instance.getConnectedBluetoothDevice();
  }

  Future<List<EspWifiNetwork>> scanWifiNetworks({required String provisionProof}) {
    return EspPlatform.instance.scanWifiNetworks(provisionProof: provisionProof);
  }

  Future<bool> provisionWifiNetwork({
    required EspWifiNetwork network,
    String? password,
  }) {
    return EspPlatform.instance.provisionWifiNetwork(network: network, password: password);
  }

  Future<bool> disconnectBluetoothDevice() {
    return EspPlatform.instance.disconnectBluetoothDevice();
  }
}
