class EspBluetoothDevice {
  final String name;
  final String serviceUuid;

  EspBluetoothDevice({
    required this.name,
    required this.serviceUuid,
  });

  factory EspBluetoothDevice.fromJson(Map<String, dynamic> json) {
    return EspBluetoothDevice(
      name: json['name'],
      serviceUuid: json['service_uuid'],
    );
  }
}
