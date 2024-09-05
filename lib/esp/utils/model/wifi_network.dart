enum EspWifiSecurity {
  WIFI_OPEN,
  WIFI_WEP,
  WIFI_WPA_PSK,
  WIFI_WPA2_PSK,
  WIFI_WPA_WPA2_PSK,
  WIFI_WPA2_ENTERPRISE,
  WIFI_WPA3_PSK,
  WIFI_WPA2_WPA3_PSK,
}

class EspWifiNetwork {
  final String name;
  final int rssi;
  final EspWifiSecurity security;

  EspWifiNetwork({
    required this.name,
    required this.rssi,
    required this.security,
  });

  String get ssid => name;

  factory EspWifiNetwork.fromJson(Map<String, dynamic> json) {
    return EspWifiNetwork(
      name: json['name'],
      rssi: json['rssi'],
      security: EspWifiSecurity.values[(json['security'] as int)],
    );
  }
}
