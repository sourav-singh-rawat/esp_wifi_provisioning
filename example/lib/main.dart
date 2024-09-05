import 'package:esp_wifi_provisioning/esp/utils/model/bluetooth_device.dart';
import 'package:esp_wifi_provisioning/esp/utils/model/wifi_network.dart';
import 'package:esp_wifi_provisioning/esp_wifi_provisioning.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP Provisioning',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ESP Provisioning Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final EspWifiProvisioning espWifiProvisioning = EspWifiProvisioning();

  // State variables to manage the UI state and Bluetooth/WiFi status
  bool isBluetoothEnabled = false;
  bool isLocationEnabled = false;
  bool isLoadingBle = false;
  bool isLoadingBleConnection = false;
  bool isLoadingWifiNetworks = false;
  List<EspBluetoothDevice> bleDevices = [];
  List<EspWifiNetwork> wifiNetworks = [];
  bool isProvisioning = false;
  String messageProvisioning = '';
  String messageBleConnection = 'Disconnected';
  String errorScanMessage = '';

  @override
  void initState() {
    super.initState();
    // Check the initial status of Location and Bluetooth when the widget is initialized
    checkIfLocationEnabled();
    checkIfBluetoothEnabled();
  }

  /// Scans for Bluetooth devices using the ESP provisioning API.
  /// Updates the state to reflect loading and error messages as needed.
  void _scanBleDevices() async {
    setState(() => isLoadingBle = true);
    try {
      // You can use quickScanBluetoothDevices() to simplify permission handling
      // final devices = await espWifiProvisioning.quickScanBluetoothDevices();

      // Alternatively, scan directly:
      final devices = await EspWifiProvisioning.esp.scanBluetoothDevices();
      setState(() => bleDevices = devices);
    } catch (e) {
      setState(() => errorScanMessage = e.toString());
    } finally {
      setState(() => isLoadingBle = false);
    }
  }

  /// Connects to a selected Bluetooth device and scans WiFi networks after a successful connection.
  void _connectToBleDevice(EspBluetoothDevice device) async {
    setState(() => isLoadingBleConnection = true);
    try {
      // Connect to the BLE device using the ESP provisioning API
      final success = await espWifiProvisioning.connectBluetoothDevice(device: device);
      setState(() => messageBleConnection = success ? 'Connected' : 'Disconnected');

      // Automatically start scanning for WiFi networks after connection
      if (success) _scanWifiNetworks();
    } catch (e) {
      setState(() => messageBleConnection = e.toString());
    } finally {
      setState(() => isLoadingBleConnection = false);
    }
  }

  /// Scans for available WiFi networks using the ESP provisioning API.
  void _scanWifiNetworks() async {
    setState(() => isLoadingWifiNetworks = true);
    try {
      final networks = await espWifiProvisioning.scanWifiNetworks(provisionProof: 'abc123');
      setState(() => wifiNetworks = networks);
    } catch (e) {
      setState(() => errorScanMessage = e.toString());
    } finally {
      setState(() => isLoadingWifiNetworks = false);
    }
  }

  /// Provisions a selected WiFi network with the provided password.
  void _provisionWifi(EspWifiNetwork network, String? password) async {
    setState(() => isProvisioning = true);
    try {
      final isProvisioned = await espWifiProvisioning.provisionWifiNetwork(
        network: network,
        password: password,
      );
      setState(() => messageProvisioning = isProvisioned ? 'Provisioned' : 'Provision Failed');
    } catch (e) {
      setState(() => messageProvisioning = e.toString());
    } finally {
      setState(() => isProvisioning = false);
    }
  }

  /// Checks if Location services are enabled and have the required permissions.
  void checkIfLocationEnabled() async {
    setState(() => isLoadingBle = true);
    try {
      // Check if location permissions are granted and the location service is enabled
      final hasLocationPermissions = await EspWifiProvisioning.locationAdapter.hasLocationPermissions();
      final isLocationServiceEnabled = await EspWifiProvisioning.locationAdapter.isLocationServiceEnabled();

      setState(() => isLocationEnabled = hasLocationPermissions && isLocationServiceEnabled);
    } catch (e) {
      setState(() => errorScanMessage += e.toString());
    } finally {
      setState(() => isLoadingBle = false);
    }
  }

  /// Checks if Bluetooth is enabled and has the necessary permissions.
  void checkIfBluetoothEnabled() async {
    setState(() => isLoadingBle = true);
    try {
      // Check if Bluetooth permissions are granted and the Bluetooth service is enabled
      final hasBluetoothPermissions = await EspWifiProvisioning.bluetoothAdapter.hasBluetoothPermissions();
      final isBluetoothServiceEnabled = await EspWifiProvisioning.bluetoothAdapter.isBluetoothServiceEnabled();

      setState(() => isBluetoothEnabled = hasBluetoothPermissions && isBluetoothServiceEnabled);
    } catch (e) {
      setState(() => errorScanMessage += e.toString());
    } finally {
      setState(() => isLoadingBle = false);
    }
  }

  /// Enables Bluetooth by requesting the necessary permissions and services.
  void _enableBluetooth() async {
    setState(() {
      isLoadingBle = true;
      errorScanMessage = '';
    });

    try {
      bool hasBluetoothPermissions = await EspWifiProvisioning.bluetoothAdapter.hasBluetoothPermissions();
      if (hasBluetoothPermissions) {
        final isEnabled = await EspWifiProvisioning.bluetoothAdapter.requestEnableBluetoothService();
        setState(() => isBluetoothEnabled = isEnabled);
      } else {
        // If permissions were not granted, request them again
        hasBluetoothPermissions = await EspWifiProvisioning.bluetoothAdapter.requestEnableBluetoothService();
        if (hasBluetoothPermissions) {
          _enableBluetooth.call(); // Retry enabling Bluetooth after permissions are granted
        }
      }
    } catch (e) {
      setState(() => errorScanMessage = e.toString());
    } finally {
      setState(() => isLoadingBle = false);
    }
  }

  /// Enables Location services by requesting the necessary permissions and services.
  void _enableLocation() async {
    setState(() {
      isLoadingBle = true;
      errorScanMessage = '';
    });

    try {
      bool hasLocationPermissions = await EspWifiProvisioning.locationAdapter.hasLocationPermissions();
      if (hasLocationPermissions) {
        final isEnabled = await EspWifiProvisioning.locationAdapter.requestEnableLocationService();
        setState(() => isLocationEnabled = isEnabled);
      } else {
        // If permissions were not granted, request them again
        hasLocationPermissions = await EspWifiProvisioning.locationAdapter.requestLocationPermission();
        if (hasLocationPermissions) {
          _enableLocation.call(); // Retry enabling Location after permissions are granted
        }
      }
    } catch (e) {
      setState(() => errorScanMessage = e.toString());
    } finally {
      setState(() => isLoadingBle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESP Provisioning')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isBluetoothEnabled || !isLocationEnabled) ...{
              RequiredServicesWidget(
                isBluetoothEnabled: isBluetoothEnabled,
                isLocationEnabled: isLocationEnabled,
                enableBluetooth: _enableBluetooth,
                enableLocation: _enableLocation,
              ),
              const Divider(),
            },
            BleScanWidget(
              isLoading: isLoadingBle,
              devices: bleDevices,
              onScan: _scanBleDevices,
              onConnect: _connectToBleDevice,
              error: errorScanMessage,
            ),
            const Divider(),
            BleConnectionWidget(
              isLoading: isLoadingBleConnection,
              connectionMessage: messageBleConnection,
            ),
            const Divider(),
            WifiScanWidget(
              isLoading: isLoadingWifiNetworks,
              networks: wifiNetworks,
              onScan: _scanWifiNetworks,
              onTapNetwork: onPressedWifiNetwork,
              connectionMessage: messageBleConnection,
            ),
            const Divider(),
            ProvisioningWidget(
              isProvisioning: isProvisioning,
              provisioningMessage: messageProvisioning,
            ),
          ],
        ),
      ),
    );
  }

  void onPressedWifiNetwork(EspWifiNetwork network) {
    TextEditingController textEditingController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(network.name),
          content: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(hintText: 'Enter password'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Connect'),
              onPressed: () {
                // Handle the text input here
                String password = textEditingController.text.trim();

                _provisionWifi.call(network, password);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class RequiredServicesWidget extends StatelessWidget {
  final bool isBluetoothEnabled;
  final VoidCallback enableBluetooth;
  final bool isLocationEnabled;
  final VoidCallback enableLocation;
  const RequiredServicesWidget({
    super.key,
    required this.isBluetoothEnabled,
    required this.enableBluetooth,
    required this.isLocationEnabled,
    required this.enableLocation,
  });

  @override
  Widget build(BuildContext context) {
    return _DecoratedContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Required Services:'),
          const SizedBox(height: 8),
          if (!isBluetoothEnabled) ...{
            const _ErrorText('Bluetooth is disabled:'),
            ElevatedButton(onPressed: enableBluetooth, child: const Text('Enable Bluetooth')),
          },
          const SizedBox(height: 4),
          if (!isLocationEnabled) ...{
            const _ErrorText('Location is disabled:'),
            ElevatedButton(onPressed: enableLocation, child: const Text('Enable Location')),
          },
        ],
      ),
    );
  }
}

class BleScanWidget extends StatelessWidget {
  final bool isLoading;
  final List<EspBluetoothDevice> devices;
  final VoidCallback onScan;
  final void Function(EspBluetoothDevice) onConnect;
  final String error;

  const BleScanWidget({
    Key? key,
    required this.isLoading,
    required this.devices,
    required this.onScan,
    required this.onConnect,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _DecoratedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Bluetooth Devices:'),
          if (isLoading) const CircularProgressIndicator() else if (devices.isEmpty) const Text('No devices found'),
          ...devices.map((device) {
            return OutlinedButton(
              onPressed: () => onConnect(device),
              child: Text(device.name),
            );
          }),
          ElevatedButton(onPressed: onScan, child: const Text('Scan Devices')),
          if (error.isNotEmpty) _ErrorText(error),
        ],
      ),
    );
  }
}

class BleConnectionWidget extends StatelessWidget {
  final bool isLoading;
  final String connectionMessage;

  const BleConnectionWidget({
    Key? key,
    required this.isLoading,
    required this.connectionMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _DecoratedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Bluetooth Connection Status:'),
          if (isLoading) const CircularProgressIndicator(),
          Text(connectionMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class WifiScanWidget extends StatelessWidget {
  final bool isLoading;
  final List<EspWifiNetwork> networks;
  final VoidCallback onScan;
  final void Function(EspWifiNetwork) onTapNetwork;
  final String connectionMessage;

  const WifiScanWidget({
    Key? key,
    required this.isLoading,
    required this.networks,
    required this.onScan,
    required this.onTapNetwork,
    required this.connectionMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _DecoratedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Wi-Fi Networks:'),
          if (isLoading) const CircularProgressIndicator() else if (networks.isEmpty) const Text('No networks found'),
          ...networks.map((network) {
            return OutlinedButton(
              onPressed: () {
                onTapNetwork.call(network);
              },
              child: Text(network.name),
            );
          }),
          if (connectionMessage == 'Connected') ElevatedButton(onPressed: onScan, child: const Text('Scan Networks')),
        ],
      ),
    );
  }
}

class ProvisioningWidget extends StatelessWidget {
  final bool isProvisioning;
  final String provisioningMessage;

  const ProvisioningWidget({
    Key? key,
    required this.isProvisioning,
    required this.provisioningMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _DecoratedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Provisioning Status:'),
          if (isProvisioning) const CircularProgressIndicator(),
          Text(provisioningMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DecoratedContainer extends StatelessWidget {
  final Widget child;
  const _DecoratedContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Colors.black),
      ),
      child: child,
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16));
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Colors.redAccent));
  }
}
