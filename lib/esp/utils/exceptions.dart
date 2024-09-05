abstract class EspException<T> implements Exception {
  final String message;

  EspException(this.message);
}

class EspBluetoothException extends EspException<void> {
  EspBluetoothException(super.message);

  @override
  String toString() {
    return message;
  }
}

class EspLocationException extends EspException<void> {
  EspLocationException(super.message);

  @override
  String toString() {
    return message;
  }
}

class EspBluetoothScanException extends EspException<void> {
  EspBluetoothScanException(super.message);

  @override
  String toString() {
    return message;
  }
}

class EspBluetoothConnectionException extends EspException<void> {
  EspBluetoothConnectionException(super.message);

  @override
  String toString() {
    return message;
  }
}

class EspWifiScanException extends EspException<void> {
  EspWifiScanException(super.message);

  @override
  String toString() {
    return message;
  }
}

class EspWifiConnectionException extends EspException<void> {
  EspWifiConnectionException(super.message);

  @override
  String toString() {
    return message;
  }
}

class EspNoDataException extends EspException<void> {
  EspNoDataException(super.message);

  @override
  String toString() {
    return message;
  }
}
