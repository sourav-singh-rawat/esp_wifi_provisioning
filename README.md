
[![pub package][pub_badge]][pub_link]
[![License: MIT][license_badge]][license_link]

# esp_provisioning_wifi

Library to provision WiFi on ESP32 devices over Bluetooth.

## Requirements

### Android 6 (API level 23)+

Make sure your `android/build.gradle` has 23+ here:

```
defaultConfig {
    minSdkVersion 23
}
```

Add this in your `android/app/build.gradle` at the end of repositories:

```
allprojects {
    repositories {
   	 ...
   	 maven { url 'https://jitpack.io' }
    }
}
```

Bluetooth permissions are automatically requested by the library.

### iOS 13.0+


Add this in your `ios/Runner/Info.plist`:
```
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This will be required to setup wifi on hardware device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This will be required to setup wifi on hardware device.</string>
```

## Notes

### esp_provisioning_wifi

This library is inspired and improved version of [esp_provisioning_wifi](https://pub.dev/packages/esp_provisioning_wifi).

### esp-idf-provisioning-android & esp-idf-provisioning-ios

The [Espressif Android Provisioning library](https://github.com/espressif/esp-idf-provisioning-android) & [Espressif 
iOS Provisioning library](https://github.com/espressif/esp-idf-provisioning-ios) is 
currently embedded in libs.

[pub_badge]: https://img.shields.io/pub/v/esp_wifi_provisioning.svg
[pub_link]: https://pub.dartlang.org/packages/esp_wifi_provisioning_wifi
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT